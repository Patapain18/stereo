//
//  MusicLibrary.swift
//  Stereo · Services/MusicLibrary.swift
//
//  Récupère la bibliothèque Apple Music via AppleScript.
//  Renvoie une liste de Track utilisables dans l'app.
//
//  ⚠️ Pour de grosses bibliothèques (>5000 morceaux), AppleScript devient lent.
//  On limite à 500 morceaux par défaut, paginé à terme.
//

import Foundation
import AppKit

@MainActor
final class MusicLibrary {

    /// Charge les N premiers morceaux de la bibliothèque
    func loadTracks(limit: Int = 500) async -> [Track] {
        let script = """
        set output to ""
        tell application id "com.apple.Music"
            try
                set theTracks to tracks of library playlist 1
                set total to count of theTracks
                if total > \(limit) then set total to \(limit)
                repeat with i from 1 to total
                    set t to item i of theTracks
                    set pid to ""
                    try
                        set pid to persistent ID of t
                    end try
                    set k to ""
                    try
                        set k to (kind of t as text)
                    end try
                    set output to output & pid & "\\t" & ¬
                        (name of t) & "\\t" & ¬
                        (artist of t) & "\\t" & ¬
                        (album of t) & "\\t" & ¬
                        (duration of t as text) & "\\t" & ¬
                        k & "\\n"
                end repeat
            end try
        end tell
        return output
        """

        return await Task.detached {
            guard let raw = await Self.runScript(script) else { return [] }
            return Self.parse(raw)
        }.value
    }

    /// Charge les playlists utilisateur
    func loadPlaylists() async -> [PlaylistRef] {
        let script = """
        set output to ""
        tell application id "com.apple.Music"
            try
                set userPL to (every user playlist whose smart is false)
                repeat with p in userPL
                    set pid to ""
                    try
                        set pid to persistent ID of p
                    end try
                    set output to output & pid & "\\t" & (name of p) & "\\t" & (count of tracks of p) & "\\n"
                end repeat
            end try
        end tell
        return output
        """

        return await Task.detached {
            guard let raw = await Self.runScript(script) else { return [] }
            return raw.split(separator: "\n").compactMap { line in
                let parts = line.components(separatedBy: "\t")
                guard parts.count >= 3 else { return nil }
                return PlaylistRef(
                    id: parts[0],
                    name: parts[1],
                    trackCount: Int(parts[2]) ?? 0
                )
            }
        }.value
    }

    /// Joue un morceau par son persistent ID
    func play(persistentID: String) {
        let script = """
        tell application id "com.apple.Music"
            try
                set t to (some track of library playlist 1 whose persistent ID is "\(persistentID)")
                play t
            end try
        end tell
        """
        _ = NSAppleScript(source: script)?.executeAndReturnError(nil)
    }

    /// Charge les morceaux d'une playlist utilisateur par son persistent ID
    func loadTracks(forPlaylistID playlistID: String) async -> [Track] {
        let script = """
        set output to ""
        tell application id "com.apple.Music"
            try
                set thePL to (some user playlist whose persistent ID is "\(playlistID)")
                set theTracks to tracks of thePL
                repeat with t in theTracks
                    set pid to ""
                    try
                        set pid to persistent ID of t
                    end try
                    set output to output & pid & "\\t" & ¬
                        (name of t) & "\\t" & ¬
                        (artist of t) & "\\t" & ¬
                        (album of t) & "\\t" & ¬
                        (duration of t as text) & "\\n"
                end repeat
            end try
        end tell
        return output
        """

        return await Task.detached {
            guard let raw = await Self.runScript(script) else { return [] }
            return Self.parse(raw)
        }.value
    }

    /// Lance la lecture d'une playlist entière (premier track + queue auto)
    func playPlaylist(id: String) {
        let script = """
        tell application id "com.apple.Music"
            try
                set thePL to (some user playlist whose persistent ID is "\(id)")
                play thePL
            end try
        end tell
        """
        _ = NSAppleScript(source: script)?.executeAndReturnError(nil)
    }

    // MARK: — Helpers

    nonisolated private static func runScript(_ source: String) -> String? {
        guard let script = NSAppleScript(source: source) else { return nil }
        var err: NSDictionary?
        let result = script.executeAndReturnError(&err)
        if let err {
            print("⚠️ AppleScript MusicLibrary error:", err)
            return nil
        }
        return result.stringValue
    }

    nonisolated private static func parse(_ raw: String) -> [Track] {
        raw.split(separator: "\n").compactMap { line in
            let parts = line.components(separatedBy: "\t")
            guard parts.count >= 5 else { return nil }
            let pid = parts[0]
            // AppleScript respecte la locale FR : "180,5" au lieu de "180.5".
            let durationStr = parts[4].replacingOccurrences(of: ",", with: ".")
            // kind est optionnel (6e champ ajouté plus tard, peut manquer
            // si l'ancien format de cache traîne)
            let kind: String? = parts.count >= 6 ? parts[5] : nil
            return Track(
                id: pid.isEmpty ? UUID().uuidString : "am-\(pid)",
                title: parts[1],
                artist: parts[2],
                album: parts[3],
                duration: Double(durationStr) ?? 0,
                source: .appleMusic,
                externalURL: nil,
                previewURL: nil,
                artworkURL: nil,
                localFileURL: nil,
                kind: kind
            )
        }
    }
}

/// Une playlist utilisateur
struct PlaylistRef: Identifiable, Hashable {
    var id: String
    var name: String
    var trackCount: Int
}
