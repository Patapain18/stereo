//
//  AppState.swift  (REMPLACE celui du Sprint 1)
//  Stereo · Models/AppState.swift
//

import Foundation
import Observation

enum Page: String, CaseIterable {
    case library, local, playlists, favorites, search, soundcloud

    var title: String {
        switch self {
        case .library:    return "Bibliothèque"
        case .local:      return "Fichiers locaux"
        case .playlists:  return "Playlists"
        case .favorites:  return "Favoris"
        case .search:     return "Rechercher"
        case .soundcloud: return "SoundCloud"
        }
    }

    var icon: String {
        switch self {
        case .library:    return "music.note"
        case .local:      return "folder"
        case .playlists:  return "music.note.list"
        case .favorites:  return "heart"
        case .search:     return "magnifyingglass"
        case .soundcloud: return "waveform"
        }
    }
}

enum LibraryViewMode: String, CaseIterable {
    case albums, shelf, list

    var icon: String {
        switch self {
        case .albums: return "rectangle.stack.fill"
        case .shelf:  return "square.grid.2x2"
        case .list:   return "list.bullet"
        }
    }

    var label: String {
        switch self {
        case .albums: return "Albums"
        case .shelf:  return "Morceaux (grille)"
        case .list:   return "Morceaux (liste)"
        }
    }
}

enum DeckStyle: String, CaseIterable {
    case walkman, deck, boombox

    var label: String {
        switch self {
        case .walkman: return "walkman"
        case .deck:    return "hi-fi"
        case .boombox: return "boombox"
        }
    }
}

@Observable
@MainActor
final class AppState {
    // MARK: — État UI persisté entre les lancements
    //
    // Les didSet écrivent dans UserDefaults. À l'init on relit ce qui était
    // sauvegardé. Ainsi Mathis retrouve son setup au prochain démarrage.

    var isNightMode: Bool = true {
        didSet { UserDefaults.standard.set(isNightMode, forKey: Keys.isNightMode) }
    }
    var isScrubbing: Bool = false  // état transitoire, pas persisté

    var page: Page = .library {
        didSet { UserDefaults.standard.set(page.rawValue, forKey: Keys.page) }
    }
    var pageArg: String? = nil  // transitoire, pas persisté

    var libraryViewMode: LibraryViewMode = .albums {
        didSet { UserDefaults.standard.set(libraryViewMode.rawValue, forKey: Keys.libraryViewMode) }
    }

    /// ID de l'album affiché en détail dans la bibliothèque. nil = grille.
    var libraryAlbumDetail: String? = nil

    // Sprint 4 polish
    var sidebarVisible: Bool = true {
        didSet { UserDefaults.standard.set(sidebarVisible, forKey: Keys.sidebarVisible) }
    }
    var radioVisible: Bool = true {
        didSet { UserDefaults.standard.set(radioVisible, forKey: Keys.radioVisible) }
    }
    var showDust: Bool = true {
        didSet { UserDefaults.standard.set(showDust, forKey: Keys.showDust) }
    }
    var nowPlayingOpen: Bool = false  // transitoire
    var deckStyle: DeckStyle = .walkman {
        didSet { UserDefaults.standard.set(deckStyle.rawValue, forKey: Keys.deckStyle) }
    }

    // MARK: — Init avec restoration

    init() {
        let d = UserDefaults.standard
        if d.object(forKey: Keys.isNightMode) != nil {
            isNightMode = d.bool(forKey: Keys.isNightMode)
        }
        if d.object(forKey: Keys.sidebarVisible) != nil {
            sidebarVisible = d.bool(forKey: Keys.sidebarVisible)
        }
        if d.object(forKey: Keys.radioVisible) != nil {
            radioVisible = d.bool(forKey: Keys.radioVisible)
        }
        if d.object(forKey: Keys.showDust) != nil {
            showDust = d.bool(forKey: Keys.showDust)
        }
        if let raw = d.string(forKey: Keys.page), let p = Page(rawValue: raw) {
            page = p
        }
        if let raw = d.string(forKey: Keys.libraryViewMode), let m = LibraryViewMode(rawValue: raw) {
            libraryViewMode = m
        }
        if let raw = d.string(forKey: Keys.deckStyle), let s = DeckStyle(rawValue: raw) {
            deckStyle = s
        }
    }

    private enum Keys {
        static let isNightMode = "stereo.app.isNightMode"
        static let sidebarVisible = "stereo.app.sidebarVisible"
        static let radioVisible = "stereo.app.radioVisible"
        static let showDust = "stereo.app.showDust"
        static let page = "stereo.app.page"
        static let libraryViewMode = "stereo.app.libraryViewMode"
        static let deckStyle = "stereo.app.deckStyle"
    }
}
