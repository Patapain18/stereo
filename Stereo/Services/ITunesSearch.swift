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
            let response = try await call(term: query, limit: 1)
            guard let first = response.results.first,
                  let raw = first.artworkUrl100 else { return nil }
            return Self.upscaleArtwork(raw)
        } catch {
            return nil
        }
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
