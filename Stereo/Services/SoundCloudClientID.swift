//
//  SoundCloudClientID.swift
//  Stereo · Services/SoundCloudClientID.swift
//
//  Extrait dynamiquement le `client_id` de SoundCloud depuis leurs bundles JS
//  publics. Ce client_id est nécessaire pour appeler l'API v2 publique
//  (api-v2.soundcloud.com) qui permet de lister les tracks d'un user.
//
//  Auto-réparation : si le bundle change ou si l'ID est invalidé par SC, on
//  re-extrait à la volée. Cache en mémoire pour la session.
//
//  Inspiré de l'approche utilisée par soundcloud-dl et autres outils similaires
//  depuis des années (le client_id change rarement, ~1×/an).
//

import Foundation

enum ClientIDError: LocalizedError {
    case homepageUnreachable
    case noBundleFound
    case noClientIDInBundles

    var errorDescription: String? {
        switch self {
        case .homepageUnreachable: return "Impossible de charger soundcloud.com"
        case .noBundleFound: return "Aucun bundle JS trouvé dans la page SoundCloud (leur HTML a probablement changé)"
        case .noClientIDInBundles: return "client_id introuvable dans les bundles JS SoundCloud — signaler sur GitHub"
        }
    }
}

actor SoundCloudClientID {
    static let shared = SoundCloudClientID()

    private var cachedID: String? = nil
    private var lastFetched: Date = .distantPast

    /// Récupère le client_id, depuis le cache si dispo, sinon en extraction live.
    /// Pass `forceRefresh: true` pour invalider le cache (utile après un 401).
    func get(forceRefresh: Bool = false) async throws -> String {
        if !forceRefresh, let cached = cachedID {
            return cached
        }
        let id = try await extractFromBundle()
        cachedID = id
        lastFetched = Date()
        print("🔑 SC client_id extrait : \(id.prefix(8))…")
        return id
    }

    /// Invalide le cache pour forcer une ré-extraction au prochain `get()`.
    func invalidate() {
        cachedID = nil
    }

    // MARK: — Extraction

    private func extractFromBundle() async throws -> String {
        let bundleURLs = try await fetchBundleURLs()
        // Cherche client_id dans chaque bundle (parallèle pour aller plus vite)
        for url in bundleURLs {
            if let id = try? await extractClientID(fromBundle: url) {
                return id
            }
        }
        throw ClientIDError.noClientIDInBundles
    }

    /// Récupère la liste des URLs des bundles JS référencés depuis la home SC.
    private func fetchBundleURLs() async throws -> [URL] {
        var request = URLRequest(url: URL(string: "https://soundcloud.com")!)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ClientIDError.homepageUnreachable
        }
        guard let html = String(data: data, encoding: .utf8) else {
            throw ClientIDError.homepageUnreachable
        }
        // Pattern : src="https://a-v2.sndcdn.com/assets/XX-HASH.js"
        let pattern = #"https://a-v2\.sndcdn\.com/assets/[0-9a-zA-Z_-]+\.js"#
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let nsRange = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = regex.matches(in: html, options: [], range: nsRange)
        var urls: [URL] = []
        var seen = Set<String>()
        for match in matches {
            if let range = Range(match.range, in: html) {
                let str = String(html[range])
                if seen.insert(str).inserted, let url = URL(string: str) {
                    urls.append(url)
                }
            }
        }
        guard !urls.isEmpty else { throw ClientIDError.noBundleFound }
        // Heuristique : le client_id est généralement dans un bundle "moyen-grand"
        // (50+ d'après nos tests). On essaye d'abord ceux-là pour aller vite.
        return urls.sorted {
            let n0 = bundleNumber(from: $0)
            let n1 = bundleNumber(from: $1)
            // Préférer 40-60 d'abord, puis le reste
            let s0 = (n0 >= 40 && n0 <= 70) ? 0 : 1
            let s1 = (n1 >= 40 && n1 <= 70) ? 0 : 1
            return s0 < s1
        }
    }

    private func bundleNumber(from url: URL) -> Int {
        let name = url.lastPathComponent  // ex "54-74445d1c.js"
        let parts = name.components(separatedBy: "-")
        return Int(parts.first ?? "") ?? 0
    }

    /// Cherche `client_id:"..."` dans un bundle JS donné.
    private func extractClientID(fromBundle url: URL) async throws -> String? {
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let js = String(data: data, encoding: .utf8) else { return nil }

        // Pattern attendu : client_id:"32-char-id" (mix alphanum, exclu OAuth Google)
        let pattern = #"client_id\s*:\s*"([A-Za-z0-9]{32})""#
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let nsRange = NSRange(js.startIndex..<js.endIndex, in: js)
        if let match = regex.firstMatch(in: js, options: [], range: nsRange),
           match.numberOfRanges > 1,
           let range = Range(match.range(at: 1), in: js) {
            let id = String(js[range])
            // Exclut l'OAuth Google qui contient des points
            if !id.contains(".") {
                return id
            }
        }
        return nil
    }
}
