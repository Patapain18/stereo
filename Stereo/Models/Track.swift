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
}
