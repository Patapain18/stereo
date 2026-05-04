//
//  StereoApp.swift  (REMPLACE celui du Sprint 1)
//  Stereo · entry point
//

import SwiftUI

@main
struct StereoApp: App {

    @State private var player = PlayerState()
    @State private var app = AppState()
    @State private var library = LibraryStore()
    @State private var favorites = Favorites()
    @State private var artwork = ArtworkLoader()

    @State private var controller = MusicController()
    @State private var watcher: MusicWatcher? = nil

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(player)
                .environment(app)
                .environment(library)
                .environment(favorites)
                .environment(artwork)
                .environment(\.musicController, controller)
                .environment(\.musicWatcher, watcher)
                .task {
                    if watcher == nil {
                        let w = MusicWatcher(player: player)
                        w.start()
                        watcher = w
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1100, height: 700)
    }
}
