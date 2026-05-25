//
//  LibraryStore.swift
//  Stereo · Services/LibraryStore.swift
//
//  Conserve en mémoire la bibliothèque chargée + l'état de chargement.
//  Observable, donc l'UI réagit automatiquement.
//

import Foundation
import Observation

@Observable
@MainActor
final class LibraryStore {
    var tracks: [Track] = []
    var playlists: [PlaylistRef] = []
    var isLoading: Bool = false
    var hasLoaded: Bool = false

    /// Cache des tracks par playlist ID — alimenté à la demande via `loadPlaylist(id:)`
    var playlistTracks: [String: [Track]] = [:]

    /// Set des playlist IDs dont le chargement est en cours
    var loadingPlaylists: Set<String> = []

    private let library = MusicLibrary()

    func loadIfNeeded() async {
        guard !hasLoaded, !isLoading else { return }
        await reload()
    }

    func reload() async {
        isLoading = true
        async let t = library.loadTracks(limit: 500)
        async let p = library.loadPlaylists()
        let (loadedTracks, loadedPlaylists) = await (t, p)
        self.tracks = loadedTracks
        self.playlists = loadedPlaylists
        isLoading = false
        hasLoaded = true
    }

    func play(_ track: Track) {
        guard track.source == .appleMusic else { return }
        let pid = track.id.replacingOccurrences(of: "am-", with: "")
        library.play(persistentID: pid)
    }

    /// Charge les tracks d'une playlist si pas déjà en cache. Idempotent.
    func loadPlaylist(id: String) async {
        guard playlistTracks[id] == nil, !loadingPlaylists.contains(id) else { return }
        loadingPlaylists.insert(id)
        let tracks = await library.loadTracks(forPlaylistID: id)
        playlistTracks[id] = tracks
        loadingPlaylists.remove(id)
    }

    /// Force un rechargement de la playlist (par ex. après un changement côté Apple Music)
    func reloadPlaylist(id: String) async {
        loadingPlaylists.insert(id)
        let tracks = await library.loadTracks(forPlaylistID: id)
        playlistTracks[id] = tracks
        loadingPlaylists.remove(id)
    }

    /// Récupère la playlist par son id (helper)
    func playlist(by id: String) -> PlaylistRef? {
        playlists.first { $0.id == id }
    }

    /// Lance la lecture d'une playlist entière dans Apple Music
    func playPlaylist(id: String) {
        library.playPlaylist(id: id)
    }
}
