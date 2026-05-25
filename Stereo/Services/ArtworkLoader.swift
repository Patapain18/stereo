//
//  ArtworkLoader.swift
//  Stereo · Services/ArtworkLoader.swift
//
//  Cache à 2 niveaux + fetch async des pochettes. Une seule instance dans l'app,
//  injectée via @Environment.
//
//  Stratégie :
//  1. Cache mémoire (rapide, vidé au quit de l'app)
//  2. Cache disque dans ~/Library/Caches/com.mathis.Stereo/artwork/<hash>.png
//     → persiste entre les lancements, donc la grille bibliothèque réapparaît
//     instantanément avec ses pochettes au second démarrage.
//  3. Sinon, fetch via iTunes Search API puis téléchargement de l'URL.
//
//  Les IDs non-résolvables (cas tracks obscurs ou en langue non latine) sont
//  aussi persistés dans unresolved.json pour ne plus retenter à chaque démarrage.
//

import SwiftUI
import AppKit
import Observation
import CryptoKit

@MainActor
@Observable
final class ArtworkLoader {

    /// Cache mémoire — indexé par track.id
    private(set) var cache: [String: NSImage] = [:]

    /// IDs des tracks déjà cherchés sans succès, pour ne pas retenter en boucle.
    /// Persisté sur disque.
    private var unresolved: Set<String> = []

    /// IDs dont le fetch est en cours
    private var inFlight: Set<String> = []

    private let search = ITunesSearch.shared
    private let diskCache = ArtworkDiskCache()

    init() {
        // Migration : v4 introduit la validation stricte du match (rejet des
        // fausses pochettes pour artistes obscurs). On purge complètement le
        // cache pour invalider les fausses pochettes déjà téléchargées.
        let currentStrategyVersion = 4
        let storedVersion = UserDefaults.standard.integer(forKey: "stereo.artwork.strategyVersion")
        if storedVersion < currentStrategyVersion {
            diskCache.clearAll()
            UserDefaults.standard.set(currentStrategyVersion, forKey: "stereo.artwork.strategyVersion")
            self.unresolved = []
        } else {
            self.unresolved = diskCache.loadUnresolved()
        }
    }

    /// Renvoie l'image si déjà en cache mémoire, nil sinon. Ne déclenche pas de fetch.
    func image(for trackID: String) -> NSImage? {
        cache[trackID]
    }

    /// Renvoie la première image en cache parmi une liste de tracks.
    /// Utile pour AlbumCard qui veut afficher la pochette de n'importe quel
    /// track de l'album.
    func firstImage(amongTracks tracks: [Track]) -> NSImage? {
        for t in tracks {
            if let img = cache[t.id] { return img }
        }
        return nil
    }

    /// S'assure qu'au moins une pochette est résolue pour l'album.
    /// Stratégie : utilise entity=album d'iTunes (plus précis pour les albums)
    /// et propage l'image à TOUS les track IDs de l'album.
    func ensureAlbumLoaded(tracks: [Track]) {
        if firstImage(amongTracks: tracks) != nil { return }
        guard let first = tracks.first else { return }

        // Évite double-fetch
        let albumKey = "album-" + (first.album.isEmpty ? first.title : first.album).lowercased()
        if inFlight.contains(albumKey) { return }
        inFlight.insert(albumKey)

        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.inFlight.remove(albumKey) }

            let albumName = first.album.isEmpty ? first.title : first.album

            // Stratégie en cascade pour maximiser les chances de trouver
            // une pochette officielle :
            //
            //   1. iTunes entity=album (rapide, beaucoup de catalogue)
            //   2. iTunes entity=track (fallback, parfois match meilleur)
            //   3. MusicBrainz + Cover Art Archive (artistes indé, petits labels)

            var imageURL: URL?

            // 1. iTunes entity=album
            imageURL = await ITunesSearch.shared.resolveAlbumArtwork(
                album: albumName,
                artist: first.artist
            )

            // 2. iTunes entity=track (fallback)
            if imageURL == nil {
                for t in tracks.prefix(3) {
                    if let u = await ITunesSearch.shared.resolveArtwork(
                        title: t.title, artist: t.artist
                    ) {
                        imageURL = u
                        break
                    }
                }
            }

            // 3. MusicBrainz + Cover Art Archive (artistes pas dans iTunes)
            if imageURL == nil {
                imageURL = await MusicBrainzClient.shared.resolveAlbumArtwork(
                    album: albumName,
                    artist: first.artist
                )
            }

            guard let final = imageURL else {
                // Marque tous les tracks unresolved pour ne pas re-tenter en boucle
                for t in tracks {
                    self.unresolved.insert(t.id)
                }
                self.diskCache.saveUnresolved(self.unresolved)
                return
            }

            // 3. Télécharge l'image
            do {
                let (data, _) = try await URLSession.shared.data(from: final)
                guard let image = NSImage(data: data) else { return }
                // 4. Stocke pour TOUS les tracks de l'album → toute card aura l'image
                for t in tracks {
                    self.cache[t.id] = image
                    await self.diskCache.save(data: data, for: t.id)
                    self.unresolved.remove(t.id)
                }
                self.diskCache.saveUnresolved(self.unresolved)
            } catch {
                for t in tracks {
                    self.unresolved.insert(t.id)
                }
                self.diskCache.saveUnresolved(self.unresolved)
            }
        }
    }

    /// Lance le chargement si pas déjà fait. À appeler dans `.onAppear` des vues qui
    /// affichent une cassette.
    func ensureLoaded(for track: Track) {
        guard cache[track.id] == nil,
              !unresolved.contains(track.id),
              !inFlight.contains(track.id) else { return }
        inFlight.insert(track.id)
        Task { await self.load(track) }
    }

    private func load(_ track: Track) async {
        defer { inFlight.remove(track.id) }

        // 1. Cache disque ?
        if let image = await diskCache.loadImage(for: track.id) {
            cache[track.id] = image
            return
        }

        // 2. Résolution de l'URL si on ne l'a pas déjà
        var url = track.artworkURL
        if url == nil {
            url = await search.resolveArtwork(title: track.title, artist: track.artist)
        }

        guard let imageURL = url else {
            markUnresolved(track.id)
            return
        }

        // 3. Téléchargement
        do {
            let (data, _) = try await URLSession.shared.data(from: imageURL)
            guard let image = NSImage(data: data) else {
                markUnresolved(track.id)
                return
            }
            cache[track.id] = image
            // Persiste sur disque pour les démarrages suivants
            await diskCache.save(data: data, for: track.id)
        } catch {
            markUnresolved(track.id)
        }
    }

    private func markUnresolved(_ id: String) {
        unresolved.insert(id)
        diskCache.saveUnresolved(unresolved)
    }

    /// Vide complètement le cache (mémoire + disque). Utile pour debug ou
    /// pour forcer un re-fetch après un changement de pochette dans Apple Music.
    func clearAll() {
        cache.removeAll()
        unresolved.removeAll()
        diskCache.clearAll()
    }
}

// MARK: — Cache disque

/// Sépare le file IO du loader pour garder le code testable et lisible.
/// Tous les accès disque sont nonisolated → exécutables hors main actor.
private final class ArtworkDiskCache {

    private let cacheDir: URL

    init() {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let bundleID = Bundle.main.bundleIdentifier ?? "com.mathis.Stereo"
        self.cacheDir = base
            .appendingPathComponent(bundleID, isDirectory: true)
            .appendingPathComponent("artwork", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    private var unresolvedFile: URL {
        cacheDir.appendingPathComponent("unresolved.json")
    }

    private func fileURL(for trackID: String) -> URL {
        // MD5 de l'ID pour avoir un nom de fichier safe (les track.id peuvent contenir
        // des caractères spéciaux ou être très longs)
        let digest = Insecure.MD5.hash(data: Data(trackID.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return cacheDir.appendingPathComponent("\(hex).img")
    }

    /// Charge une image depuis disque si elle existe.
    /// Le fichier est binaire (ce qu'on a téléchargé), pas re-encodé.
    func loadImage(for trackID: String) async -> NSImage? {
        let url = fileURL(for: trackID)
        return await Task.detached(priority: .userInitiated) { () -> NSImage? in
            guard FileManager.default.fileExists(atPath: url.path),
                  let data = try? Data(contentsOf: url),
                  let image = NSImage(data: data) else {
                return nil
            }
            return image
        }.value
    }

    /// Sauvegarde la data brute (PNG/JPEG selon ce qu'a retourné le CDN Apple).
    func save(data: Data, for trackID: String) async {
        let url = fileURL(for: trackID)
        await Task.detached(priority: .background) {
            try? data.write(to: url, options: .atomic)
        }.value
    }

    /// Charge le set des IDs non-résolvables persistés.
    func loadUnresolved() -> Set<String> {
        guard let data = try? Data(contentsOf: unresolvedFile),
              let array = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return Set(array)
    }

    /// Persiste le set des IDs non-résolvables.
    func saveUnresolved(_ set: Set<String>) {
        let array = Array(set)
        guard let data = try? JSONEncoder().encode(array) else { return }
        try? data.write(to: unresolvedFile, options: .atomic)
    }

    /// Vide tout le cache disque (images + unresolved).
    func clearAll() {
        try? FileManager.default.removeItem(at: cacheDir)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }
}
