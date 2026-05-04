//
//  MusicController.swift
//  Stereo · Services/MusicController.swift
//
//  Le bridge entre Swift et Apple Music.
//  Toutes les commandes (play/pause/seek/...) passent par ici.
//
//  On utilise NSAppleScript : on compile un petit script AppleScript
//  une fois, puis on l'exécute. C'est rapide et sûr.
//

import Foundation
import AppKit

/// Infos sur le morceau en cours retournées par Apple Music
struct CurrentTrackInfo: Equatable {
    var title: String
    var artist: String
    var album: String
    var duration: Double
    var position: Double
    var isPlaying: Bool
    var persistentID: String
}

/// Erreurs possibles lors d'un appel AppleScript
enum MusicControllerError: Error {
    case scriptError(String)
    case nothingPlaying
}

final class MusicController {

    // MARK: — Commandes simples
    //
    // ⚠️ On cible Apple Music par bundle ID `com.apple.Music`, jamais par nom.
    // Sur certains Mac, `tell application "Music"` matche un autre handler
    // (vérifié au POC, retournait version "1.0" au lieu de la vraie 1.6.x).

    func togglePlay() {
        run(#"tell application id "com.apple.Music" to playpause"#)
    }

    func play() {
        run(#"tell application id "com.apple.Music" to play"#)
    }

    func pause() {
        run(#"tell application id "com.apple.Music" to pause"#)
    }

    func nextTrack() {
        run(#"tell application id "com.apple.Music" to next track"#)
    }

    func previousTrack() {
        run(#"tell application id "com.apple.Music" to previous track"#)
    }

    /// Saute à `seconds` dans le morceau courant
    func seek(to seconds: Double) {
        let s = max(0, seconds)
        run(#"tell application id "com.apple.Music" to set player position to \#(s)"#)
    }

    /// Règle le volume Apple Music, entre 0 et 1
    func setVolume(_ value: Double) {
        let v = Int((max(0, min(1, value))) * 100)
        run(#"tell application id "com.apple.Music" to set sound volume to \#(v)"#)
    }

    // MARK: — Lecture d'état

    /// Récupère le morceau en cours, ou nil si Apple Music ne joue rien.
    func currentTrack() -> CurrentTrackInfo? {
        let script = """
        tell application id "com.apple.Music"
            if player state is playing or player state is paused then
                set t to current track
                set s to ""
                try
                    set s to persistent ID of t
                end try
                set isP to (player state is playing)
                return (name of t) & "\\t" & ¬
                       (artist of t) & "\\t" & ¬
                       (album of t) & "\\t" & ¬
                       (duration of t as text) & "\\t" & ¬
                       (player position as text) & "\\t" & ¬
                       (isP as text) & "\\t" & ¬
                       s
            else
                return ""
            end if
        end tell
        """

        guard let raw = runReturning(script), !raw.isEmpty else {
            return nil
        }

        let parts = raw.components(separatedBy: "\t")
        guard parts.count >= 7 else { return nil }

        return CurrentTrackInfo(
            title: parts[0],
            artist: parts[1],
            album: parts[2],
            duration: parseNumber(parts[3]),
            position: parseNumber(parts[4]),
            isPlaying: parts[5].lowercased() == "true",
            persistentID: parts[6]
        )
    }

    /// Parse un nombre AppleScript indépendamment de la locale système.
    /// AppleScript respecte la locale FR et retourne "18,311" au lieu de "18.311",
    /// ce qui casse `Double()` qui n'accepte que le point.
    private func parseNumber(_ s: String) -> Double {
        Double(s.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    // MARK: — Helpers privés

    /// Exécute un script AppleScript sans attendre de retour.
    private func run(_ source: String) {
        guard let script = NSAppleScript(source: source) else { return }
        var error: NSDictionary?
        script.executeAndReturnError(&error)
        if let error {
            print("⚠️ AppleScript error:", error)
        }
    }

    /// Exécute un script AppleScript et retourne sa string descriptor.
    private func runReturning(_ source: String) -> String? {
        guard let script = NSAppleScript(source: source) else { return nil }
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        if let error {
            print("⚠️ AppleScript error:", error)
            return nil
        }
        return result.stringValue
    }
}
