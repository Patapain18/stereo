//
//  Album.swift
//  Stereo · Models/Album.swift
//
//  Groupe les tracks de la bibliothèque par (artiste, nom d'album) pour
//  proposer une vue Albums au lieu de la grille brute de tracks. Réduit
//  drastiquement le bruit visuel : un OST de 24 tracks devient une seule
//  carte Album au lieu de 24 cartes avec la même pochette.
//

import Foundation

struct Album: Identifiable, Hashable {
    let id: String
    let name: String
    let artist: String
    let tracks: [Track]

    /// Track de référence pour la pochette (le premier de l'album).
    var coverTrack: Track? { tracks.first }

    /// Durée totale en secondes
    var totalDuration: Double {
        tracks.reduce(0) { $0 + $1.duration }
    }

    /// Format "5 morceaux · 23 min"
    var summary: String {
        let count = tracks.count
        let label = count > 1 ? "morceaux" : "morceau"
        let mins = Int((totalDuration / 60).rounded())
        return "\(count) \(label) · \(mins) min"
    }
}

extension Array where Element == Track {
    /// Groupe les tracks par (artiste, album). Albums triés par artiste, puis nom.
    /// Tracks dans un album conservent leur ordre d'origine.
    func groupedByAlbum() -> [Album] {
        // Préserve l'ordre d'apparition de chaque (artiste|album) dans la liste
        var keysOrder: [String] = []
        var groups: [String: [Track]] = [:]

        for track in self {
            let key = "\(track.artist)||\(track.album.isEmpty ? track.title : track.album)"
            if groups[key] == nil {
                keysOrder.append(key)
                groups[key] = []
            }
            groups[key]?.append(track)
        }

        let albums = keysOrder.compactMap { key -> Album? in
            guard let tracks = groups[key], let first = tracks.first else { return nil }
            return Album(
                id: key,
                name: first.album.isEmpty ? first.title : first.album,
                artist: first.artist,
                tracks: tracks
            )
        }

        return albums.sorted { lhs, rhs in
            if lhs.artist != rhs.artist {
                return lhs.artist.localizedCompare(rhs.artist) == .orderedAscending
            }
            return lhs.name.localizedCompare(rhs.name) == .orderedAscending
        }
    }
}
