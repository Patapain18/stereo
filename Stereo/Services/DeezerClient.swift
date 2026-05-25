//
//  DeezerClient.swift
//  Stereo · Services/DeezerClient.swift
//
//  Recherche d'artwork via l'API publique Deezer — fallback supplémentaire
//  après iTunes et MusicBrainz. Catalogue énorme, souvent meilleur pour les
//  artistes français/européens qu'iTunes n'a pas.
//
//  Endpoint public : https://api.deezer.com/search/album?q=...
//  Pas de clé API requise pour les recherches.
//

import Foundation

actor DeezerClient {
    static let shared = DeezerClient()

    private var lastRequest: Date = .distantPast
    private let minInterval: TimeInterval = 0.3  // 3 req/sec max (Deezer permet plus mais on reste poli)

    /// Cherche l'URL de la pochette d'un album via Deezer.
    /// Retourne nil si pas trouvé ou si la validation échoue.
    func resolveAlbumArtwork(album: String, artist: String) async -> URL? {
        let trimmedAlbum = album.trimmingCharacters(in: .whitespaces)
        let trimmedArtist = artist.trimmingCharacters(in: .whitespaces)
        guard !trimmedAlbum.isEmpty else { return nil }

        // Rate limit local
        let elapsed = -lastRequest.timeIntervalSinceNow
        if elapsed < minInterval {
            try? await Task.sleep(nanoseconds: UInt64((minInterval - elapsed) * 1_000_000_000))
        }
        lastRequest = Date()

        // Query format Deezer : artist:"X" album:"Y" (avec guillemets pour exact)
        let escapedAlbum = trimmedAlbum.replacingOccurrences(of: "\"", with: "")
        let escapedArtist = trimmedArtist.replacingOccurrences(of: "\"", with: "")
        let query = "artist:\"\(escapedArtist)\" album:\"\(escapedAlbum)\""

        var components = URLComponents(string: "https://api.deezer.com/search/album")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: "3")
        ]
        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.setValue("Stereo/0.3 (macOS)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                return nil
            }

            struct DeezerResponse: Codable {
                let data: [DeezerAlbum]
            }
            struct DeezerAlbum: Codable {
                let title: String?
                let cover_xl: String?
                let cover_big: String?
                let artist: DeezerArtist?
            }
            struct DeezerArtist: Codable {
                let name: String?
            }

            let parsed = try JSONDecoder().decode(DeezerResponse.self, from: data)

            // Validation stricte : album + artist doivent matcher
            for album in parsed.data {
                let albumOK = ITunesSearch.fuzzyMatches(
                    returned: album.title ?? "",
                    expected: trimmedAlbum
                )
                let artistOK = ITunesSearch.fuzzyMatches(
                    returned: album.artist?.name ?? "",
                    expected: trimmedArtist
                )
                if albumOK && artistOK {
                    // Prefer cover_xl (1000x1000), fallback cover_big (500x500)
                    if let xl = album.cover_xl, let url = URL(string: xl) {
                        return url
                    }
                    if let big = album.cover_big, let url = URL(string: big) {
                        return url
                    }
                }
            }
            return nil
        } catch {
            return nil
        }
    }
}
