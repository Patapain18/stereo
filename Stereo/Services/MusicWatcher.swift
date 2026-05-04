//
//  MusicWatcher.swift
//  Stereo · Services/MusicWatcher.swift
//
//  Le watcher temps réel : il maintient `PlayerState` à jour avec ce qui
//  se passe dans Apple Music.
//
//  Combo gagnant :
//  - DistributedNotificationCenter : Apple Music envoie une notif système
//    à chaque changement de morceau → on rafraîchit instantanément.
//  - Timer 4×/sec : pour la position qui avance dans le morceau (le seul
//    truc qu'aucune notif ne donne en continu).
//

import Foundation
import AppKit

@MainActor
final class MusicWatcher {

    private let controller = MusicController()
    let player: PlayerState

    private var timer: Timer?
    private var lastPersistentID: String?

    init(player: PlayerState) {
        self.player = player
    }

    // MARK: — Cycle de vie

    func start() {
        // 1) S'inscrire aux notifs de changement (instantané)
        DistributedNotificationCenter.default.addObserver(
            self,
            selector: #selector(onPlayerInfo(_:)),
            name: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil
        )

        // 2) Démarrer le polling de la position (4×/sec)
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }

        // 3) Premier refresh immédiat
        refreshAll()
    }

    func stop() {
        DistributedNotificationCenter.default.removeObserver(self)
        timer?.invalidate()
        timer = nil
    }

    // MARK: — Refresh

    @objc private func onPlayerInfo(_ note: Notification) {
        // Une notif est arrivée d'Apple Music : refresh complet
        Task { @MainActor in self.refreshAll() }
    }

    /// Tick fréquent (4×/sec) : on met juste à jour la position et l'état play/pause
    private func tick() {
        guard let info = controller.currentTrack() else {
            if player.current != nil {
                player.current = nil
                player.isPlaying = false
            }
            return
        }

        // Si le morceau a changé entre 2 ticks (cas rare où la notif est ratée),
        // on fait un refresh complet
        if info.persistentID != lastPersistentID {
            applyFullRefresh(info)
            return
        }

        // Sinon on met juste à jour la position + état play/pause
        if !inhibitPositionUpdate {
            player.position = info.position
        }
        player.isPlaying = info.isPlaying
        player.duration = info.duration
    }

    /// Refresh complet : recharge tout le morceau en cours
    private func refreshAll() {
        guard let info = controller.currentTrack() else {
            player.current = nil
            player.isPlaying = false
            player.position = 0
            player.duration = 0
            lastPersistentID = nil
            return
        }
        applyFullRefresh(info)
    }

    private func applyFullRefresh(_ info: CurrentTrackInfo) {
        let track = Track(
            id: info.persistentID.isEmpty ? UUID().uuidString : "am-\(info.persistentID)",
            title: info.title,
            artist: info.artist,
            album: info.album,
            duration: info.duration,
            source: .appleMusic,
            externalURL: nil,
            previewURL: nil
        )
        player.current = track
        player.duration = info.duration
        player.position = info.position
        player.isPlaying = info.isPlaying
        lastPersistentID = info.persistentID
    }

    // MARK: — Anti-fight pendant scrub

    /// Quand l'utilisateur drag le slider, on ne veut pas que le tick
    /// écrase sa valeur pendant 1 seconde.
    private var inhibitPositionUpdate: Bool = false

    func beginScrub() { inhibitPositionUpdate = true }
    func endScrub() {
        // On laisse 0.5s à Apple Music pour confirmer le seek avant de re-poll
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            inhibitPositionUpdate = false
        }
    }
}
