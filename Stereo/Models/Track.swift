//
//  Track.swift
//  Stereo · Models/Track.swift
//
//  La structure de données qui représente un morceau, peu importe sa source.
//  C'est l'équivalent de tes objets `track` dans hifi-data.jsx.
//

import Foundation

/// D'où provient un morceau
enum TrackSource: String, Codable, Hashable {
    case appleMusic
    case soundcloud
    case iTunesSearch
    case localFile
}

/// Un morceau de musique — local ou distant.
struct Track: Identifiable, Codable, Equatable, Hashable {
    /// Identifiant unique. Pour Apple Music c'est le `persistent ID`.
    /// Pour les autres sources : "source-id".
    var id: String

    var title: String
    var artist: String
    var album: String

    /// Durée en secondes
    var duration: Double

    var source: TrackSource

    /// URL pour ouvrir le morceau dans son app native (Apple Music, SoundCloud...)
    var externalURL: URL?

    /// URL d'un preview 30s (iTunes Search API en fournit un)
    var previewURL: URL?

    /// URL HD de la pochette. Soit fournie d'origine (iTunes Search), soit
    /// résolue à la demande par ArtworkLoader pour les tracks Apple Music locaux.
    var artworkURL: URL?

    /// Pour les tracks source = .localFile : URL absolue du fichier sur disque
    var localFileURL: URL?

    /// Le 'kind' de track tel que reporté par Apple Music via AppleScript.
    /// Permet de distinguer :
    ///   - 'Apple Music song'         → catalogue Apple Music
    ///   - 'Matched audio file'       → fichier matché au catalogue
    ///   - 'Purchased AAC audio file' → acheté iTunes
    ///   - 'MPEG audio file' / 'WAV audio file' → uploads locaux personnels
    var kind: String?

    /// True si ce track est un fichier uploadé localement par l'utilisateur
    /// (et non issu du catalogue Apple Music). Heuristique : tout ce qui n'est
    /// pas explicitement un kind "catalogue" connu (EN + FR — Apple Music
    /// utilise les noms en français sur les Mac configurés en FR).
    var isLocalUpload: Bool {
        guard let rawKind = kind?.lowercased(), !rawKind.isEmpty else {
            return false
        }
        // Apple Music FR utilise des non-breaking spaces (U+00A0) entre les
        // mots, donc 'apple\u{00A0}music' ne match pas 'apple music' avec
        // un .contains classique. On normalise tous les whitespaces Unicode
        // en simple espace pour comparison.
        let k = rawKind
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let catalogueKinds = [
            // English
            "apple music", "matched", "purchased", "protected",
            // French
            "musique apple", "correspondant", "acheté", "achete", "protégé", "protege"
        ]
        return !catalogueKinds.contains { k.contains($0) }
    }
}
