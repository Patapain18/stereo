//
//  SoundCloudOEmbed.swift
//  Stereo · Services/SoundCloudOEmbed.swift
//
//  Bridge vers l'API oEmbed publique de SoundCloud, qui n'a pas besoin de clé
//  contrairement à leur vraie API (fermée depuis 2021).
//
//  Doc : https://developers.soundcloud.com/docs/oembed
//  Endpoint : https://soundcloud.com/oembed?format=json&url=<URL_TRACK>
//
//  Renvoie : title, author_name, thumbnail_url, html (iframe embed).
//

import Foundation

private struct OEmbedResponse: Codable {
    let title: String?
    let author_name: String?
    let thumbnail_url: String?
    let html: String?
}

enum SoundCloudError: LocalizedError {
    case invalidURL
    case badStatus(Int)
    case parsing

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL SoundCloud invalide"
        case .badStatus(let c): return "SoundCloud a renvoyé HTTP \(c)"
        case .parsing: return "Réponse SoundCloud invalide"
        }
    }
}

actor SoundCloudOEmbed {
    static let shared = SoundCloudOEmbed()

    /// Récupère les métadonnées d'un track SoundCloud à partir de son URL publique
    func fetchTrack(from urlString: String) async throws -> Track {
        let trimmed = urlString.trimmingCharacters(in: .whitespaces)
        guard trimmed.contains("soundcloud.com"),
              let inputURL = URL(string: trimmed) else {
            throw SoundCloudError.invalidURL
        }

        var components = URLComponents(string: "https://soundcloud.com/oembed")!
        components.queryItems = [
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "url", value: trimmed)
        ]
        guard let oembedURL = components.url else { throw SoundCloudError.invalidURL }

        var request = URLRequest(url: oembedURL)
        request.setValue("Stereo/0.1 (macOS)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw SoundCloudError.badStatus(http.statusCode)
        }

        guard let parsed = try? JSONDecoder().decode(OEmbedResponse.self, from: data) else {
            throw SoundCloudError.parsing
        }

        // Nettoie le titre "Title by Author" → "Title"
        var title = parsed.title ?? "Track SoundCloud"
        let artist = parsed.author_name ?? "SoundCloud"
        if let byRange = title.range(of: " by \(artist)") {
            title.removeSubrange(byRange)
        }

        // Upgrade l'artwork SoundCloud t500x500 si possible
        let artworkURL: URL? = parsed.thumbnail_url
            .map { $0.replacingOccurrences(of: "-large.jpg", with: "-t500x500.jpg") }
            .flatMap(URL.init(string:))

        // ID stable depuis l'URL d'origine
        let id = "sc-" + (inputURL.path
            .components(separatedBy: "/")
            .filter { !$0.isEmpty }
            .joined(separator: "/"))

        return Track(
            id: id,
            title: title,
            artist: artist,
            album: "SoundCloud",
            duration: 0,  // oEmbed ne donne pas la durée — on l'aura via le Widget
            source: .soundcloud,
            externalURL: inputURL,
            previewURL: nil,
            artworkURL: artworkURL
        )
    }
}
