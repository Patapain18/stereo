//
//  LocalPlayer.swift
//  Stereo · Services/LocalPlayer.swift
//
//  Lecteur audio pour fichiers locaux via AVPlayer (gère MP3, M4A, AAC, FLAC,
//  WAV, AIFF nativement). API homogène avec SoundCloudController pour pouvoir
//  être branché par PlaybackRouter sans cas particulier.
//

import Foundation
import AVFoundation
import Observation

@MainActor
@Observable
final class LocalPlayer {

    // MARK: — État observable

    private(set) var isPlaying: Bool = false
    private(set) var position: Double = 0
    private(set) var duration: Double = 0
    private(set) var currentTrack: Track? = nil

    // MARK: — Callbacks (le PlaybackRouter s'y branche)

    var onTrackChanged: ((Track?) -> Void)?
    var onPlayStateChanged: ((Bool) -> Void)?
    var onProgress: ((Double, Double) -> Void)?
    var onFinish: (() -> Void)?

    // MARK: — Internals

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?

    // MARK: — Commandes

    func load(_ track: Track) {
        guard track.source == .localFile, let fileURL = track.localFileURL else {
            print("⚠️ LocalPlayer.load: track invalide (source=\(track.source) localFileURL=\(String(describing: track.localFileURL)))")
            return
        }

        cleanup()

        currentTrack = track
        duration = track.duration
        position = 0
        onTrackChanged?(track)

        let item = AVPlayerItem(url: fileURL)
        let p = AVPlayer(playerItem: item)
        player = p

        // Observe la position toutes les 250ms (~4Hz, comme MusicWatcher)
        let interval = CMTime(seconds: 0.25, preferredTimescale: 1000)
        timeObserver = p.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            let pos = CMTimeGetSeconds(time)
            if pos.isFinite, pos >= 0 {
                self.position = pos
                self.onProgress?(pos, self.duration)
            }
        }

        // Notif fin du track → onFinish
        endObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.isPlaying = false
                self.onPlayStateChanged?(false)
                self.onFinish?()
            }
        }

        // Auto-play
        p.play()
        isPlaying = true
        onPlayStateChanged?(true)
        print("🎵 LocalPlayer.load: \(track.title) — \(fileURL.lastPathComponent)")
    }

    func play() {
        guard let p = player else { return }
        p.play()
        isPlaying = true
        onPlayStateChanged?(true)
    }

    func pause() {
        player?.pause()
        isPlaying = false
        onPlayStateChanged?(false)
    }

    func togglePlay() {
        if isPlaying { pause() } else { play() }
    }

    func seek(toSeconds sec: Double) {
        let t = CMTime(seconds: max(0, sec), preferredTimescale: 1000)
        player?.seek(to: t)
    }

    // MARK: — Cleanup

    private func cleanup() {
        if let obs = timeObserver, let p = player {
            p.removeTimeObserver(obs)
            timeObserver = nil
        }
        if let end = endObserver {
            NotificationCenter.default.removeObserver(end)
            endObserver = nil
        }
        player?.pause()
        player = nil
    }

    deinit {
        // Attention : on est dans deinit (nonisolated). Pas d'accès direct à
        // self.player car @MainActor. On ne peut pas appeler cleanup() ici.
        // En pratique, l'app garde une seule instance pour toute la durée de vie,
        // donc deinit n'est jamais réellement appelée.
    }
}
