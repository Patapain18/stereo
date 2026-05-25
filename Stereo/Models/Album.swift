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
    /// Groupe les tracks par (artiste principal, album). Les tracks d'un même
    /// album avec différents featurings (ex: « ELIESG & 63KLUF », « ELIESG &
    /// Bedry ») sont fusionnés sous un seul Album d'« ELIESG ».
    /// Albums triés par artiste, puis nom. Tracks conservent leur ordre.
    func groupedByAlbum() -> [Album] {
        var keysOrder: [String] = []
        var groups: [String: [Track]] = [:]

        for track in self {
            let primaryArtist = Self.primaryArtist(from: track.artist)
            let albumName = track.album.isEmpty ? track.title : track.album
            let key = "\(primaryArtist.lowercased())||\(albumName.lowercased())"
            if groups[key] == nil {
                keysOrder.append(key)
                groups[key] = []
            }
            groups[key]?.append(track)
        }

        let albums = keysOrder.compactMap { key -> Album? in
            guard let tracks = groups[key], let first = tracks.first else { return nil }
            let primaryArtist = Self.primaryArtist(from: first.artist)
            return Album(
                id: key,
                name: first.album.isEmpty ? first.title : first.album,
                artist: primaryArtist,
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

    /// Sépare les vrais albums (≥ 2 morceaux + nom d'album distinct du titre)
    /// des singles (1 morceau, album vide, ou album == titre).
    func groupedByAlbumAndSingles() -> (albums: [Album], singles: [Track]) {
        let allGroups = groupedByAlbum()
        var albums: [Album] = []
        var singles: [Track] = []
        for group in allGroups {
            guard let first = group.tracks.first else { continue }
            let albumNameNonEmpty = !first.album.trimmingCharacters(in: .whitespaces).isEmpty
            let albumNameDistinct = first.album.localizedCaseInsensitiveCompare(first.title) != .orderedSame
            let isRealAlbum = group.tracks.count >= 2 && albumNameNonEmpty && albumNameDistinct
            if isRealAlbum {
                albums.append(group)
            } else {
                singles.append(contentsOf: group.tracks)
            }
        }
        // Singles triés par artiste puis titre
        singles.sort { lhs, rhs in
            if lhs.artist != rhs.artist {
                return lhs.artist.localizedCompare(rhs.artist) == .orderedAscending
            }
            return lhs.title.localizedCompare(rhs.title) == .orderedAscending
        }
        return (albums, singles)
    }

    /// Extrait l'artiste principal d'une chaîne contenant des featurings.
    /// Exemples :
    ///   « ELIESG & 63KLUF »      → « ELIESG »
    ///   « Drake feat. Future »   → « Drake »
    ///   « Adele (feat. Beyoncé) »→ « Adele »
    ///   « Daft Punk »            → « Daft Punk »
    private static func primaryArtist(from artistString: String) -> String {
        let separators = [
            " & ",
            " feat. ", " feat ", " (feat",
            " ft. ", " ft ",
            " featuring ",
            " avec ", " vs. ", " vs ",
            ", "
        ]
        var name = artistString
        for sep in separators {
            if let range = name.range(of: sep, options: [.caseInsensitive]) {
                name = String(name[..<range.lowerBound])
            }
        }
        return name.trimmingCharacters(in: .whitespaces)
    }
}
