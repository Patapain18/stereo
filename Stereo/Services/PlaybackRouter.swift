//
//  PlaybackRouter.swift
//  Stereo · Services/PlaybackRouter.swift
//
//  Coordonne 3 sources de lecture :
//   — Apple Music (via MusicController/Watcher)
//   — SoundCloud (via SoundCloudController + WKWebView caché)
//   — Fichiers locaux (via LocalPlayer + AVPlayer)
//
//  Une seule source est active à la fois — switcher coupe les autres pour
//  éviter le mash-up sonore.
//
//  PlayerState reflète toujours ce qui joue, quelle que soit la source.
//

import Foundation
import Observation

@Observable
@MainActor
final class PlaybackRouter {

    private(set) var activeSource: TrackSource = .appleMusic

    private let player: PlayerState
    private let watcher: MusicWatcher
    private let amController: MusicController
    private let scController: SoundCloudController
    private let localPlayer: LocalPlayer
    private let libraryStore: LibraryStore

    init(
        player: PlayerState,
        watcher: MusicWatcher,
        amController: MusicController,
        scController: SoundCloudController,
        localPlayer: LocalPlayer,
        libraryStore: LibraryStore
    ) {
        self.player = player
        self.watcher = watcher
        self.amController = amController
        self.scController = scController
        self.localPlayer = localPlayer
        self.libraryStore = libraryStore

        wireSoundCloudEvents()
        wireLocalEvents()
    }

    // MARK: — Routing des commandes

    /// Lance la lecture d'un track depuis n'importe quelle source.
    /// Switch automatiquement la source active si besoin.
    func play(_ track: Track) {
        switch track.source {
        case .appleMusic:
            activateAM()
            libraryStore.play(track)
        case .soundcloud:
            activateSC()
            scController.load(track)
        case .localFile:
            activateLocal()
            localPlayer.load(track)
        case .iTunesSearch:
            // Les résultats iTunes Search ouvrent juste Apple Music (deep link).
            break
        }
    }

    /// Toggle play/pause de la source active
    func togglePlay() {
        switch activeSource {
        case .appleMusic:  amController.togglePlay()
        case .soundcloud:  scController.togglePlay()
        case .localFile:   localPlayer.togglePlay()
        case .iTunesSearch: break
        }
    }

    /// Saute à une position dans le track courant
    func seek(toSeconds sec: Double) {
        switch activeSource {
        case .appleMusic:  amController.seek(to: sec)
        case .soundcloud:  scController.seek(toSeconds: sec)
        case .localFile:   localPlayer.seek(toSeconds: sec)
        case .iTunesSearch: break
        }
    }

    /// Track suivant (uniquement AM pour l'instant — SC et local n'ont pas de queue)
    func nextTrack() {
        if activeSource == .appleMusic { amController.nextTrack() }
    }

    /// Track précédent (uniquement AM)
    func previousTrack() {
        if activeSource == .appleMusic { amController.previousTrack() }
    }

    /// Active explicitement Apple Music (re-démarre le watcher, coupe SC et local)
    func activateAM() {
        if activeSource == .soundcloud { scController.pause() }
        if activeSource == .localFile { localPlayer.pause() }
        activeSource = .appleMusic
        watcher.enabled = true
    }

    /// Active explicitement SoundCloud
    func activateSC() {
        if activeSource == .appleMusic { amController.pause() }
        if activeSource == .localFile { localPlayer.pause() }
        activeSource = .soundcloud
        watcher.enabled = false
    }

    /// Active explicitement la lecture locale
    func activateLocal() {
        if activeSource == .appleMusic { amController.pause() }
        if activeSource == .soundcloud { scController.pause() }
        activeSource = .localFile
        watcher.enabled = false
    }

    // MARK: — Wiring des events vers PlayerState

    private func wireSoundCloudEvents() {
        scController.onTrackChanged = { [weak self] track in
            guard let self, self.activeSource == .soundcloud else { return }
            self.player.current = track
            if let dur = track?.duration, dur > 0 {
                self.player.duration = dur
            }
            self.player.position = 0
        }
        scController.onPlayStateChanged = { [weak self] playing in
            guard let self, self.activeSource == .soundcloud else { return }
            self.player.isPlaying = playing
        }
        scController.onProgress = { [weak self] position, duration in
            guard let self, self.activeSource == .soundcloud else { return }
            self.player.position = position
            if duration > 0 { self.player.duration = duration }
        }
        scController.onFinish = { [weak self] in
            guard let self, self.activeSource == .soundcloud else { return }
            self.player.isPlaying = false
        }
    }

    private func wireLocalEvents() {
        localPlayer.onTrackChanged = { [weak self] track in
            guard let self, self.activeSource == .localFile else { return }
            self.player.current = track
            if let dur = track?.duration, dur > 0 {
                self.player.duration = dur
            }
            self.player.position = 0
        }
        localPlayer.onPlayStateChanged = { [weak self] playing in
            guard let self, self.activeSource == .localFile else { return }
            self.player.isPlaying = playing
        }
        localPlayer.onProgress = { [weak self] position, duration in
            guard let self, self.activeSource == .localFile else { return }
            self.player.position = position
            if duration > 0 { self.player.duration = duration }
        }
        localPlayer.onFinish = { [weak self] in
            guard let self, self.activeSource == .localFile else { return }
            self.player.isPlaying = false
        }
    }
}
