//
//  ArtworkLoader.swift
//  Stereo · Services/ArtworkLoader.swift
//
//  Cache + fetch async des pochettes. Une seule instance dans l'app, injectée
//  via @Environment.
//
//  Logique :
//  — Si un Track a déjà une `artworkURL` (cas iTunes Search), on télécharge direct.
//  — Sinon (cas track Apple Music local sans artwork accessible), on appelle
//    iTunes Search pour résoudre l'URL via title+artist.
//  — Les images sont mises en cache mémoire par track.id, donc pas de re-fetch.
//  — Les "non-trouvables" sont aussi cachées pour ne pas retenter à l'infini.
//

import SwiftUI
import AppKit
import Observation

@MainActor
@Observable
final class ArtworkLoader {

    /// Cache des images chargées, indexées par track.id
    private(set) var cache: [String: NSImage] = [:]

    /// IDs des tracks qu'on a déjà cherchés et qui n'ont pas de pochette,
    /// pour éviter de spammer iTunes Search en boucle.
    private var unresolved: Set<String> = []

    /// IDs des tracks dont le fetch est en cours.
    private var inFlight: Set<String> = []

    private let search = ITunesSearch.shared

    /// Renvoie l'image si déjà en cache, nil sinon. Ne déclenche pas de fetch.
    func image(for trackID: String) -> NSImage? {
        cache[trackID]
    }

    /// Lance le fetch si pas déjà fait. À appeler dans `.onAppear` des vues qui
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

        // 1. Résolution de l'URL si on ne l'a pas déjà
        var url = track.artworkURL
        if url == nil {
            url = await search.resolveArtwork(title: track.title, artist: track.artist)
        }

        guard let imageURL = url else {
            unresolved.insert(track.id)
            return
        }

        // 2. Téléchargement
        do {
            let (data, _) = try await URLSession.shared.data(from: imageURL)
            guard let image = NSImage(data: data) else {
                unresolved.insert(track.id)
                return
            }
            cache[track.id] = image
        } catch {
            unresolved.insert(track.id)
        }
    }
}
