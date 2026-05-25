//
//  SoundCloudLibrary.swift
//  Stereo · Services/SoundCloudLibrary.swift
//
//  Persistance locale (UserDefaults) des tracks SoundCloud que Mathis a ajoutés
//  via la page Stéréo dédiée. Pas d'API SoundCloud, donc pas de "bibliothèque
//  cloud" — c'est juste ses URLs sauvegardées.
//

import Foundation
import Observation

@Observable
@MainActor
final class SoundCloudLibrary {

    private let key = "stereo.soundcloud.library.v1"

    private(set) var tracks: [Track] = []
    var isAdding: Bool = false
    var lastError: String? = nil
    var lastSuccess: String? = nil

    /// Progress en cours d'import (pour la progress bar)
    var importTotal: Int = 0
    var importDone: Int = 0

    private let resolver = SoundCloudOEmbed.shared
    private let scraper = SoundCloudScraper.shared

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([Track].self, from: data) {
            tracks = saved
        }
    }

    /// Point d'entrée unique : auto-detect URL track (ajoute un track unique)
    /// ou URL profil (importe en bulk via le scraper).
    func addInput(_ urlString: String) async {
        let trimmed = urlString.trimmingCharacters(in: .whitespaces)
        guard let url = URL(string: trimmed), url.host?.contains("soundcloud.com") == true else {
            lastError = "URL SoundCloud invalide"
            lastSuccess = nil
            return
        }

        let parts = url.path.components(separatedBy: "/").filter { !$0.isEmpty }
        if parts.count >= 2 {
            // Track unique : /user/track-slug
            await addTrack(fromURL: trimmed)
        } else if parts.count == 1 {
            // Profil : /user
            await importProfile(url: trimmed)
        } else {
            lastError = "Impossible de comprendre cette URL (ni un track, ni un profil)"
            lastSuccess = nil
        }
    }

    /// Ajoute un track via son URL SoundCloud (récupère les métadonnées via oEmbed)
    func addTrack(fromURL urlString: String) async {
        isAdding = true
        lastError = nil
        lastSuccess = nil
        defer { isAdding = false }
        do {
            let track = try await resolver.fetchTrack(from: urlString)
            if !tracks.contains(where: { $0.id == track.id }) {
                tracks.insert(track, at: 0)
                save()
                lastSuccess = "« \(track.title) » ajouté"
            } else {
                lastSuccess = "« \(track.title) » est déjà dans ta bibliothèque"
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Importe tous les tracks publics d'un profil SoundCloud via scraping HTML.
    /// 3 stratégies de parsing en cascade (cf SoundCloudScraper).
    func importProfile(url profileURL: String) async {
        isAdding = true
        lastError = nil
        lastSuccess = nil
        importTotal = 0
        importDone = 0
        defer {
            isAdding = false
            importTotal = 0
            importDone = 0
        }

        do {
            let scrape = try await scraper.fetchProfile(url: profileURL)
            importTotal = scrape.trackURLs.count

            var added = 0
            var skipped = 0
            for trackURL in scrape.trackURLs {
                do {
                    let track = try await resolver.fetchTrack(from: trackURL.absoluteString)
                    if !tracks.contains(where: { $0.id == track.id }) {
                        tracks.insert(track, at: 0)
                        added += 1
                    } else {
                        skipped += 1
                    }
                } catch {
                    // Skip un track qui ne résout pas (privé, supprimé, etc.)
                }
                importDone += 1
            }
            save()

            // Feedback summary
            var summary = "\(added) track(s) ajouté(s)"
            if skipped > 0 { summary += ", \(skipped) déjà présent(s)" }
            summary += " (stratégie : \(scrape.strategy.rawValue))"
            if !scrape.warnings.isEmpty {
                summary += " ⚠ " + scrape.warnings.joined(separator: ", ")
            }
            lastSuccess = summary
        } catch {
            lastError = error.localizedDescription
        }
    }

    func remove(_ track: Track) {
        tracks.removeAll { $0.id == track.id }
        save()
    }

    func removeAll() {
        tracks.removeAll()
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(tracks) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
