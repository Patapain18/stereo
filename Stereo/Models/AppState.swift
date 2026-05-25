//
//  AppState.swift  (REMPLACE celui du Sprint 1)
//  Stereo · Models/AppState.swift
//

import Foundation
import Observation

enum Page: String, CaseIterable {
    case library, playlists, favorites, search, soundcloud

    var title: String {
        switch self {
        case .library:    return "Bibliothèque"
        case .playlists:  return "Playlists"
        case .favorites:  return "Favoris"
        case .search:     return "Rechercher"
        case .soundcloud: return "SoundCloud"
        }
    }

    var icon: String {
        switch self {
        case .library:    return "books.vertical"
        case .playlists:  return "square.stack"
        case .favorites:  return "heart"
        case .search:     return "magnifyingglass"
        case .soundcloud: return "waveform"
        }
    }
}

enum LibraryViewMode: String, CaseIterable {
    case shelf, list

    var icon: String {
        switch self {
        case .shelf: return "square.grid.2x2"
        case .list: return "list.bullet"
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
final class AppState {
    var isNightMode: Bool = true
    var isScrubbing: Bool = false

    var page: Page = .library
    var pageArg: String? = nil          // playlist ID si page == .playlists
    var libraryViewMode: LibraryViewMode = .shelf

    // Sprint 4 polish
    var radioVisible: Bool = true       // panneau radio à droite
    var showDust: Bool = true           // particules de poussière en background
    var nowPlayingOpen: Bool = false    // overlay vue plein écran
    var deckStyle: DeckStyle = .walkman // style du now playing
}
