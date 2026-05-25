//
//  SoundCloudScraper.swift
//  Stereo · Services/SoundCloudScraper.swift
//
//  Récupère les tracks publics d'un profil SoundCloud via leur API v2
//  (api-v2.soundcloud.com). Le client_id est extrait dynamiquement par
//  SoundCloudClientID — auto-réparation sur invalidation.
//
//  Approche en 2 stratégies :
//   A. API v2 (fiable, ~99% du temps) — la voie principale
//   B. JSON `__sc_hydration` du HTML (fallback dégradé) — pour les rares cas où
//      l'API v2 ne répond pas ou que le client_id casse temporairement
//
//  ⚠️ L'API v2 est non-publique côté SoundCloud (officiellement, leur API
//  ouverte est fermée depuis 2021). C'est techniquement contre leurs CGU.
//  En pratique, c'est read-only sur des données publiques, identique à ce
//  que font soundcloud-dl / youtube-dl depuis des années sans souci. Pour un
//  usage perso, le risque est ~nul. Voir SECURITY.md pour la position.
//

import Foundation

enum SoundCloudScrapeStrategy: String {
    case apiV2 = "api-v2"
    case hydrationJSON = "hydration-json-fallback"
}

enum SoundCloudScrapeError: LocalizedError {
    case fetchFailed(Int)
    case userNotFound
    case clientIDFailed(String)
    case noStrategyWorked

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let code):
            return "SoundCloud a renvoyé HTTP \(code)"
        case .userNotFound:
            return "Impossible de trouver l'utilisateur correspondant à cette URL"
        case .clientIDFailed(let why):
            return "Extraction du client_id SoundCloud échouée : \(why)"
        case .noStrategyWorked:
            return "Aucune stratégie de récupération n'a fonctionné (SC a probablement changé leur API ou bundle JS — signaler sur GitHub)"
        }
    }
}

struct SoundCloudScrapeResult {
    let trackURLs: [URL]
    let strategy: SoundCloudScrapeStrategy
    let warnings: [String]
}

// MARK: — Modèles API v2

private struct UserResolve: Codable {
    let id: Int
    let username: String?
    let permalink: String?
}

private struct TracksPage: Codable {
    let collection: [TrackItem]
    let next_href: String?
}

private struct TrackItem: Codable {
    let permalink_url: String?
}

// MARK: — Scraper

actor SoundCloudScraper {
    static let shared = SoundCloudScraper()

    private let clientIDProvider = SoundCloudClientID.shared

    /// Récupère les URLs des tracks publics d'un profil.
    func fetchProfile(url profileURL: String) async throws -> SoundCloudScrapeResult {
        guard let url = URL(string: profileURL), url.host?.contains("soundcloud.com") == true else {
            throw SoundCloudError.invalidURL
        }

        // Stratégie A : API v2 (la voie principale)
        do {
            let urls = try await fetchViaAPIv2(profileURL: url)
            if !urls.isEmpty {
                print("🔍 SC scraper: stratégie A (API v2) — \(urls.count) tracks")
                return SoundCloudScrapeResult(trackURLs: urls, strategy: .apiV2, warnings: [])
            }
        } catch {
            print("⚠️ SC scraper: stratégie A a échoué (\(error.localizedDescription)), fallback…")
        }

        // Stratégie B : __sc_hydration (fallback dégradé)
        do {
            let urls = try await fetchViaHydration(profileURL: url)
            if !urls.isEmpty {
                print("🔍 SC scraper: stratégie B (hydration JSON) — \(urls.count) tracks (fallback)")
                return SoundCloudScrapeResult(
                    trackURLs: urls,
                    strategy: .hydrationJSON,
                    warnings: ["API v2 indisponible, fallback HTML utilisé (résultats potentiellement partiels)"]
                )
            }
        } catch {
            print("⚠️ SC scraper: stratégie B a échoué (\(error.localizedDescription))")
        }

        throw SoundCloudScrapeError.noStrategyWorked
    }

    // MARK: — Stratégie A : API v2

    private func fetchViaAPIv2(profileURL: URL) async throws -> [URL] {
        var clientID = try await clientIDProvider.get()

        // 1. Resolve username → user object
        var user = try? await resolveUser(profileURL: profileURL, clientID: clientID)

        // Si 401, le client_id est invalide — on force refresh et on retry une fois
        if user == nil {
            clientID = try await clientIDProvider.get(forceRefresh: true)
            user = try await resolveUser(profileURL: profileURL, clientID: clientID)
        }

        guard let user else { throw SoundCloudScrapeError.userNotFound }

        // 2. Pagine /users/{id}/tracks jusqu'à épuisement
        var allURLs: [URL] = []
        var nextHref: String? = "https://api-v2.soundcloud.com/users/\(user.id)/tracks?client_id=\(clientID)&limit=50&linked_partitioning=1"

        while let href = nextHref {
            let page = try await fetchTracksPage(url: href)
            for item in page.collection {
                if let permalink = item.permalink_url, let url = URL(string: permalink) {
                    allURLs.append(url)
                }
            }
            // next_href peut ne pas contenir client_id, on l'ajoute si manquant
            if let nh = page.next_href, !nh.isEmpty {
                if nh.contains("client_id=") {
                    nextHref = nh
                } else {
                    nextHref = nh + (nh.contains("?") ? "&" : "?") + "client_id=\(clientID)"
                }
            } else {
                nextHref = nil
            }
            // Safety cap pour éviter boucle infinie ou bibliothèques énormes
            if allURLs.count > 500 { break }
        }

        return Array(Set(allURLs.map(\.absoluteString)))
            .compactMap(URL.init(string:))
    }

    private func resolveUser(profileURL: URL, clientID: String) async throws -> UserResolve? {
        var components = URLComponents(string: "https://api-v2.soundcloud.com/resolve")!
        components.queryItems = [
            URLQueryItem(name: "url", value: profileURL.absoluteString),
            URLQueryItem(name: "client_id", value: clientID)
        ]
        guard let url = components.url else { return nil }
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse {
            if http.statusCode == 401 || http.statusCode == 403 { return nil }
            if !(200..<300).contains(http.statusCode) {
                throw SoundCloudScrapeError.fetchFailed(http.statusCode)
            }
        }
        return try? JSONDecoder().decode(UserResolve.self, from: data)
    }

    private func fetchTracksPage(url urlString: String) async throws -> TracksPage {
        guard let url = URL(string: urlString) else {
            throw SoundCloudScrapeError.fetchFailed(0)
        }
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw SoundCloudScrapeError.fetchFailed(http.statusCode)
        }
        return try JSONDecoder().decode(TracksPage.self, from: data)
    }

    // MARK: — Stratégie B : __sc_hydration (fallback)

    private func fetchViaHydration(profileURL: URL) async throws -> [URL] {
        var request = URLRequest(url: profileURL)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw SoundCloudScrapeError.fetchFailed(http.statusCode)
        }
        guard let html = String(data: data, encoding: .utf8) else { return [] }

        let pattern = #""permalink_url"\s*:\s*"(https?://soundcloud\.com/[a-zA-Z0-9_/-]+)""#
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let nsRange = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = regex.matches(in: html, options: [], range: nsRange)

        let username = profileURL.path.components(separatedBy: "/").filter { !$0.isEmpty }.first

        var seen = Set<String>()
        var result: [URL] = []
        for match in matches {
            guard match.numberOfRanges > 1,
                  let range = Range(match.range(at: 1), in: html) else { continue }
            let urlStr = String(html[range])
            let path = URL(string: urlStr)?.path ?? ""
            let parts = path.components(separatedBy: "/").filter { !$0.isEmpty }
            // Doit être /user/track-slug
            guard parts.count == 2 else { continue }
            if let username, parts[0].lowercased() != username.lowercased() { continue }
            if seen.insert(urlStr.lowercased()).inserted, let url = URL(string: urlStr) {
                result.append(url)
            }
        }
        return result
    }
}
