//
//  Favorites.swift
//  Stereo · Services/Favorites.swift
//
//  Favoris persistés dans UserDefaults (équivalent Swift de localStorage).
//

import Foundation
import Observation

@Observable
final class Favorites {
    private let key = "stereo.favorites.v1"
    private(set) var ids: Set<String> = []

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([String].self, from: data) {
            ids = Set(saved)
        }
    }

    func toggle(_ track: Track) {
        if ids.contains(track.id) {
            ids.remove(track.id)
        } else {
            ids.insert(track.id)
        }
        save()
    }

    func contains(_ track: Track) -> Bool {
        ids.contains(track.id)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(Array(ids)) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
