//
//  ITunesSearch.swift
//  Stereo · Services/ITunesSearch.swift
//
//  Bridge vers l'API publique iTunes Search.
//  Doc : https://performance-partners.apple.com/search-api
//
//  Sert à deux choses dans Stéréo :
//  1. La recherche dans le catalogue Apple Music public (page Rechercher)
//  2. La résolution d'artwork HD pour les tracks de la bibliothèque locale,
//     qui n'ont pas d'artwork accessible via AppleScript pour les morceaux streamés.
//
//  L'API est gratuite, sans clé. Apple throttle silencieusement (HTTP 403) si
//  on tape trop de requêtes en peu de temps depuis la même IP. On gère ça avec :
//  — un rate limiter (1 req toutes les 200ms minimum)
//  — un backoff sur 403 (on bloque les requêtes pendant 60 sec)
//  — un User-Agent identifiable (plus poli)
//

import Foundation

enum ITunesError: LocalizedError {
    case throttled
    case badStatus(Int)

    var errorDescription: String? {
        switch self {
        case .throttled:
            return "iTunes Search a temporairement bloqué les requêtes (trop d'appels récents). Réessaie dans 1 minute."
        case .badStatus(let code):
            return "iTunes Search a renvoyé HTTP \(code)."
        }
    }
}

/// Réponse JSON de iTunes Search API
private struct ITunesSearchResponse: Codable {
    let resultCount: Int
    let results: [ITunesSearchTrack]
}

private struct ITunesSearchTrack: Codable {
    let trackId: Int?
    let trackName: String?
    let artistName: String?
    let collectionName: String?
    let trackTimeMillis: Int?
    let artworkUrl100: String?
    let trackViewUrl: String?
    let previewUrl: String?
}

/// Limite le débit des requêtes pour rester sous le radar du throttle d'Apple.
private actor RateLimiter {
    private var lastRequest: Date = .distantPast
    private let minInterval: TimeInterval = 0.25
    private var blockedUntil: Date? = nil

    /// Bloque jusqu'à ce qu'on puisse faire une nouvelle requête. Throw si on est
    /// dans un backoff après un 403.
    func acquire() async throws {
        if let until = blockedUntil, Date() < until {
            throw ITunesError.throttled
        }
        blockedUntil = nil

        let elapsed = -lastRequest.timeIntervalSinceNow
        if elapsed < minInterval {
            let waitNs = UInt64((minInterval - elapsed) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: waitNs)
        }
        lastRequest = Date()
    }

    /// Bloque les requêtes pendant 60s suite à un 403.
    func markBlocked() {
        blockedUntil = Date().addingTimeInterval(60)
    }
}

actor ITunesSearch {

    /// Une seule instance partagée pour que le rate limiter couvre TOUS les
    /// appelants (ArtworkLoader + SearchView).
    static let shared = ITunesSearch()

    private let limiter = RateLimiter()

    /// Recherche dans le catalogue Apple Music par mot-clé.
    func searchCatalog(query: String, limit: Int = 24) async throws -> [Track] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let response = try await call(term: query, limit: limit)
        return response.results.compactMap { Self.mapToTrack($0) }
    }

    /// Cherche le track équivalent dans le catalogue et retourne son URL d'artwork HD.
    func resolveArtwork(title: String, artist: String) async -> URL? {
        let query = "\(title) \(artist)".trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return nil }
        do {
            let response = try await call(term: query, limit: 3)
            // Cherche un match valide parmi les premiers résultats
            for result in response.results {
                guard let raw = result.artworkUrl100 else { continue }
                let titleOK = Self.fuzzyMatches(returned: result.trackName ?? "", expected: title)
                let artistOK = Self.fuzzyMatches(returned: result.artistName ?? "", expected: artist)
                if titleOK && artistOK {
                    return Self.upscaleArtwork(raw)
                }
            }
            return nil
        } catch {
            return nil
        }
    }

    /// Cherche l'artwork d'un album entier via entity=album.
    /// Beaucoup plus précis que resolveArtwork(title:artist:) pour les pochettes
    /// d'albums : l'API iTunes match mieux quand on lui demande spécifiquement
    /// un album plutôt qu'un track.
    func resolveAlbumArtwork(album: String, artist: String) async -> URL? {
        let trimmedAlbum = album.trimmingCharacters(in: .whitespaces)
        let trimmedArtist = artist.trimmingCharacters(in: .whitespaces)
        guard !trimmedAlbum.isEmpty else { return nil }
        let query = "\(trimmedArtist) \(trimmedAlbum)".trimmingCharacters(in: .whitespaces)

        do {
            try await limiter.acquire()
            var components = URLComponents(string: "https://itunes.apple.com/search")!
            components.queryItems = [
                URLQueryItem(name: "term", value: query),
                URLQueryItem(name: "entity", value: "album"),
                URLQueryItem(name: "limit", value: "1"),
                URLQueryItem(name: "media", value: "music")
            ]
            guard let url = components.url else { return nil }

            var request = URLRequest(url: url)
            request.setValue("Stereo/0.1 (macOS; +https://github.com/local)", forHTTPHeaderField: "User-Agent")
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 403 || http.statusCode == 429 {
                    await limiter.markBlocked()
                    return nil
                }
                guard (200..<300).contains(http.statusCode) else { return nil }
            }

            struct AlbumResponse: Codable {
                let results: [AlbumItem]
            }
            struct AlbumItem: Codable {
                let artworkUrl100: String?
                let collectionName: String?
                let artistName: String?
            }
            let parsed = try JSONDecoder().decode(AlbumResponse.self, from: data)
            guard let first = parsed.results.first,
                  let raw = first.artworkUrl100 else { return nil }

            // Validation stricte : rejette si le résultat ne matche pas vraiment
            // (évite d'afficher la pochette d'un autre album du même mot-clé).
            let albumOK = Self.fuzzyMatches(
                returned: first.collectionName ?? "",
                expected: trimmedAlbum
            )
            let artistOK = Self.fuzzyMatches(
                returned: first.artistName ?? "",
                expected: trimmedArtist
            )
            guard albumOK && artistOK else {
                print("🚫 iTunes album match rejeté : « \(first.collectionName ?? "?") » / « \(first.artistName ?? "?") » ≠ « \(trimmedAlbum) » / « \(trimmedArtist) »")
                return nil
            }

            return Self.upscaleArtwork(raw)
        } catch {
            return nil
        }
    }

    /// Normalise et compare 2 strings pour détecter un vrai match album/artist.
    /// Ignore casse, suffixes - Single/EP/Deluxe, features, parens.
    static func fuzzyMatches(returned: String, expected: String) -> Bool {
        let normalize: (String) -> String = { s in
            var result = s.lowercased()
            // Strip suffixes communs Apple
            let suffixes = [
                " - single", " (single)",
                " - ep", " (ep)",
                " - deluxe edition", " - deluxe", " (deluxe)",
                " - remastered", " (remastered)",
                " - special edition", " - bonus track version",
                " (live)", " - live"
            ]
            for suf in suffixes {
                if result.hasSuffix(suf) {
                    result = String(result.dropLast(suf.count))
                }
            }
            // Strip features
            let featPatterns = [" (feat.", " (ft.", " feat.", " ft.", " featuring", " & "]
            for pat in featPatterns {
                if let range = result.range(of: pat) {
                    result = String(result[..<range.lowerBound])
                }
            }
            return result.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let r = normalize(returned)
        let e = normalize(expected)
        if r.isEmpty || e.isEmpty { return false }
        return r == e || r.contains(e) || e.contains(r)
    }

    // MARK: — Helpers

    private func call(term: String, limit: Int) async throws -> ITunesSearchResponse {
        try await limiter.acquire()

        var components = URLComponents(string: "https://itunes.apple.com/search")!
        components.queryItems = [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "entity", value: "musicTrack"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "media", value: "music")
        ]
        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.setValue("Stereo/0.1 (macOS; +https://github.com/local)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse {
            if http.statusCode == 403 || http.statusCode == 429 {
                await limiter.markBlocked()
                throw ITunesError.throttled
            }
            guard (200..<300).contains(http.statusCode) else {
                throw ITunesError.badStatus(http.statusCode)
            }
        }

        return try JSONDecoder().decode(ITunesSearchResponse.self, from: data)
    }

    private static func mapToTrack(_ r: ITunesSearchTrack) -> Track? {
        guard let id = r.trackId, let title = r.trackName, let artist = r.artistName else { return nil }
        let durationSec = r.trackTimeMillis.map { Double($0) / 1000 } ?? 0
        let artwork = r.artworkUrl100.flatMap(Self.upscaleArtwork)
        return Track(
            id: "itunes-\(id)",
            title: title,
            artist: artist,
            album: r.collectionName ?? "",
            duration: durationSec,
            source: .iTunesSearch,
            externalURL: r.trackViewUrl.flatMap(URL.init(string:)),
            previewURL: r.previewUrl.flatMap(URL.init(string:)),
            artworkURL: artwork
        )
    }

    /// Le `artworkUrl100` est un thumbnail 100×100. L'URL contient le segment
    /// `100x100bb.jpg` qu'on peut remplacer par `600x600bb.jpg` pour avoir la HD.
    private static func upscaleArtwork(_ raw: String) -> URL? {
        let upscaled = raw.replacingOccurrences(of: "100x100bb", with: "600x600bb")
        return URL(string: upscaled)
    }
}
