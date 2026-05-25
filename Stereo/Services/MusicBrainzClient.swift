//
//  MusicBrainzClient.swift
//  Stereo · Services/MusicBrainzClient.swift
//
//  Recherche d'artwork via MusicBrainz + Cover Art Archive — fallback gratuit
//  quand iTunes Search ne trouve pas (artistes indé, petits labels, etc.).
//
//  Flow :
//   1. MusicBrainz API : recherche release-group par (artist + album)
//   2. Récupère le MBID du release-group le plus pertinent
//   3. Cover Art Archive : https://coverartarchive.org/release-group/MBID/front-500
//      redirige vers l'image JPG/PNG officielle
//
//  Pas de clé API requise. Rate limit MusicBrainz : 1 req/sec → on respecte.
//

import Foundation

actor MusicBrainzClient {
    static let shared = MusicBrainzClient()

    private var lastRequest: Date = .distantPast
    private let minInterval: TimeInterval = 1.1  // Respecte le 1 req/sec MusicBrainz
    private var blockedUntil: Date? = nil

    /// Cherche l'URL de la pochette d'un album via MusicBrainz + Cover Art Archive.
    /// Retourne nil si pas trouvé ou si MusicBrainz est temporairement throttle.
    func resolveAlbumArtwork(album: String, artist: String) async -> URL? {
        let trimmedAlbum = album.trimmingCharacters(in: .whitespaces)
        let trimmedArtist = artist.trimmingCharacters(in: .whitespaces)
        guard !trimmedAlbum.isEmpty else { return nil }

        // Backoff si on est dans une fenêtre throttle récente
        if let until = blockedUntil, Date() < until {
            return nil
        }
        blockedUntil = nil

        // Rate limit local : respecte 1 req/sec
        let elapsed = -lastRequest.timeIntervalSinceNow
        if elapsed < minInterval {
            try? await Task.sleep(nanoseconds: UInt64((minInterval - elapsed) * 1_000_000_000))
        }
        lastRequest = Date()

        // 1. Cherche le MBID du release-group
        guard let mbid = await fetchReleaseGroupMBID(album: trimmedAlbum, artist: trimmedArtist) else {
            return nil
        }

        // 2. Cover Art Archive — URL directe (redirect automatique vers l'image)
        return URL(string: "https://coverartarchive.org/release-group/\(mbid)/front-500")
    }

    private func fetchReleaseGroupMBID(album: String, artist: String) async -> String? {
        // Query Lucene MusicBrainz : artist:"Radiohead" AND release:"In Rainbows"
        let escapedAlbum = album.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedArtist = artist.replacingOccurrences(of: "\"", with: "\\\"")
        let luceneQuery = "release:\"\(escapedAlbum)\" AND artist:\"\(escapedArtist)\""

        var components = URLComponents(string: "https://musicbrainz.org/ws/2/release-group/")!
        components.queryItems = [
            URLQueryItem(name: "query", value: luceneQuery),
            URLQueryItem(name: "fmt", value: "json"),
            URLQueryItem(name: "limit", value: "1")
        ]
        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        // MusicBrainz exige un User-Agent identifiable (sous peine de ban)
        request.setValue("Stereo/0.3 (+https://github.com/Patapain18/stereo)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 503 || http.statusCode == 429 {
                    // MusicBrainz throttle → backoff 2 min
                    blockedUntil = Date().addingTimeInterval(120)
                    return nil
                }
                guard (200..<300).contains(http.statusCode) else { return nil }
            }

            struct MBResponse: Codable {
                let releaseGroups: [ReleaseGroup]?
                enum CodingKeys: String, CodingKey {
                    case releaseGroups = "release-groups"
                }
            }
            struct ReleaseGroup: Codable {
                let id: String
                let score: Int?
            }
            let parsed = try JSONDecoder().decode(MBResponse.self, from: data)
            guard let first = parsed.releaseGroups?.first,
                  (first.score ?? 0) >= 80 else {
                // Score < 80 = match trop faible, on rejette
                return nil
            }
            return first.id
        } catch {
            return nil
        }
    }
}
