//
//  LocalLibrary.swift
//  Stereo · Services/LocalLibrary.swift
//
//  Scanne des dossiers locaux pour trouver des fichiers audio, extrait leurs
//  métadonnées (titre, artiste, album, durée, pochette) via AVFoundation, et
//  les expose comme des Track utilisables dans le reste de l'app.
//
//  Persiste la liste des dossiers ajoutés (mais pas les tracks — re-scan à
//  chaque démarrage pour rester synchro avec le disque).
//
//  Pochettes embarquées : extraites une fois et écrites dans le cache disque
//  d'ArtworkLoader, donc l'affichage est instantané au 2e démarrage.
//

import Foundation
import AppKit
import AVFoundation
import Observation
import CryptoKit

@Observable
@MainActor
final class LocalLibrary {

    private let foldersKey = "stereo.local.folders.v1"

    /// Dossiers que l'utilisateur a ajoutés (paths absolus)
    private(set) var folders: [URL] = []

    /// Tracks indexés depuis tous les dossiers
    private(set) var tracks: [Track] = []

    /// État du scan
    var isScanning: Bool = false
    var scanProgress: (current: Int, total: Int) = (0, 0)
    var lastError: String? = nil

    /// Extensions audio supportées par AVFoundation sur macOS
    static let supportedExtensions: Set<String> = [
        "mp3", "m4a", "aac", "wav", "aiff", "aif", "flac", "alac", "caf", "mp4"
    ]

    init() {
        loadFolders()
    }

    // MARK: — Folders management

    private func loadFolders() {
        if let array = UserDefaults.standard.array(forKey: foldersKey) as? [String] {
            folders = array.compactMap { URL(fileURLWithPath: $0) }
        }
    }

    private func saveFolders() {
        let paths = folders.map(\.path)
        UserDefaults.standard.set(paths, forKey: foldersKey)
    }

    /// Ouvre un NSOpenPanel et ajoute le dossier sélectionné à la biblio
    func pickAndAddFolder() async {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.title = "Choisir un dossier de musique à indexer"
        panel.prompt = "Indexer"

        let response = await MainActor.run { panel.runModal() }
        guard response == .OK, let url = panel.url else { return }
        await addFolder(url)
    }

    func addFolder(_ url: URL) async {
        if !folders.contains(where: { $0.path == url.path }) {
            folders.append(url)
            saveFolders()
        }
        await rescanAll()
    }

    func removeFolder(_ url: URL) async {
        folders.removeAll { $0.path == url.path }
        saveFolders()
        await rescanAll()
    }

    // MARK: — Scan

    func rescanAll() async {
        isScanning = true
        scanProgress = (0, 0)
        lastError = nil
        defer {
            isScanning = false
            scanProgress = (0, 0)
        }

        // Trouve tous les fichiers audio dans tous les dossiers
        let allFiles = folders.flatMap { findAudioFiles(in: $0) }
        scanProgress = (0, allFiles.count)

        var newTracks: [Track] = []
        newTracks.reserveCapacity(allFiles.count)
        for (index, file) in allFiles.enumerated() {
            let track = await loadTrack(from: file)
            newTracks.append(track)
            scanProgress = (index + 1, allFiles.count)
        }

        // Trie : artiste / album / titre
        newTracks.sort { lhs, rhs in
            if lhs.artist != rhs.artist { return lhs.artist.localizedCompare(rhs.artist) == .orderedAscending }
            if lhs.album != rhs.album { return lhs.album.localizedCompare(rhs.album) == .orderedAscending }
            return lhs.title.localizedCompare(rhs.title) == .orderedAscending
        }

        self.tracks = newTracks
    }

    /// Liste récursivement les fichiers audio dans un dossier.
    /// nonisolated car FileManager scan est CPU-bound + on veut pas bloquer le main thread.
    nonisolated private func findAudioFiles(in folder: URL) -> [URL] {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: folder,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }

        var files: [URL] = []
        for case let url as URL in enumerator {
            let ext = url.pathExtension.lowercased()
            if LocalLibrary.supportedExtensions.contains(ext) {
                files.append(url)
            }
        }
        return files
    }

    /// Extrait les métadonnées d'un fichier audio via AVAsset
    private func loadTrack(from fileURL: URL) async -> Track {
        let asset = AVURLAsset(url: fileURL)
        let id = "local-" + Self.stableID(for: fileURL.path)

        // Valeurs par défaut depuis le nom de fichier
        let fileBaseName = fileURL.deletingPathExtension().lastPathComponent
        var title = fileBaseName
        var artist = "Artiste inconnu"
        var album = ""
        var duration: Double = 0
        var artworkData: Data? = nil

        // Charge metadata et duration en async
        async let metadataLoad: [AVMetadataItem]? = try? asset.load(.commonMetadata)
        async let durationLoad: CMTime? = try? asset.load(.duration)

        if let metadata = await metadataLoad {
            for item in metadata {
                guard let key = item.commonKey?.rawValue else { continue }
                switch key {
                case AVMetadataKey.commonKeyTitle.rawValue:
                    if let v = try? await item.load(.stringValue), !v.isEmpty { title = v }
                case AVMetadataKey.commonKeyArtist.rawValue:
                    if let v = try? await item.load(.stringValue), !v.isEmpty { artist = v }
                case AVMetadataKey.commonKeyAlbumName.rawValue:
                    if let v = try? await item.load(.stringValue), !v.isEmpty { album = v }
                case AVMetadataKey.commonKeyArtwork.rawValue:
                    if let d = try? await item.load(.dataValue) { artworkData = d }
                default:
                    break
                }
            }
        }

        if let cmTime = await durationLoad {
            let seconds = CMTimeGetSeconds(cmTime)
            if seconds.isFinite, seconds > 0 {
                duration = seconds
            }
        }

        // Si on a une pochette embarquée, on l'écrit dans le cache disque
        // d'ArtworkLoader pour que CassetteThumb la trouve directement.
        if let data = artworkData {
            await Self.writeArtworkToCache(data: data, trackID: id)
        }

        return Track(
            id: id,
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            source: .localFile,
            externalURL: nil,
            previewURL: nil,
            artworkURL: nil,
            localFileURL: fileURL
        )
    }

    // MARK: — Helpers

    nonisolated private static func stableID(for path: String) -> String {
        let digest = Insecure.MD5.hash(data: Data(path.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// Écrit la pochette embarquée directement dans le cache disque, au même
    /// path que ce qu'utilise ArtworkLoader → affichage instantané.
    nonisolated private static func writeArtworkToCache(data: Data, trackID: String) async {
        let fm = FileManager.default
        let base = fm.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let bundleID = Bundle.main.bundleIdentifier ?? "com.mathis.Stereo"
        let dir = base
            .appendingPathComponent(bundleID, isDirectory: true)
            .appendingPathComponent("artwork", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)

        let digest = Insecure.MD5.hash(data: Data(trackID.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        let file = dir.appendingPathComponent("\(hex).img")
        try? data.write(to: file, options: .atomic)
    }
}
