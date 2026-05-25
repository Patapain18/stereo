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

    private let resolver = SoundCloudOEmbed.shared

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([Track].self, from: data) {
            tracks = saved
        }
    }

    /// Ajoute un track via son URL SoundCloud (récupère les métadonnées via oEmbed)
    func addTrack(fromURL urlString: String) async {
        isAdding = true
        lastError = nil
        defer { isAdding = false }
        do {
            let track = try await resolver.fetchTrack(from: urlString)
            // Évite les doublons par id
            if !tracks.contains(where: { $0.id == track.id }) {
                tracks.insert(track, at: 0)
                save()
            }
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
