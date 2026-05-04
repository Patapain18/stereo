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
}
