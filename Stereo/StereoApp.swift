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
    @State private var scLibrary = SoundCloudLibrary()
    @State private var scController = SoundCloudController()
    @State private var localLib = LocalLibrary()
    @State private var localPlayer = LocalPlayer()

    @State private var controller = MusicController()
    @State private var watcher: MusicWatcher? = nil
    @State private var router: PlaybackRouter? = nil

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(player)
                .environment(app)
                .environment(library)
                .environment(favorites)
                .environment(artwork)
                .environment(scLibrary)
                .environment(scController)
                .environment(localLib)
                .environment(localPlayer)
                .environment(\.musicController, controller)
                .environment(\.musicWatcher, watcher)
                .environment(\.playbackRouter, router)
                .task {
                    if watcher == nil {
                        let w = MusicWatcher(player: player)
                        w.start()
                        watcher = w
                    }
                    if router == nil, let w = watcher {
                        router = PlaybackRouter(
                            player: player,
                            watcher: w,
                            amController: controller,
                            scController: scController,
                            localPlayer: localPlayer,
                            libraryStore: library
                        )
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1100, height: 700)
    }
}

// MARK: — EnvironmentKey pour le router

private struct PlaybackRouterKey: EnvironmentKey {
    static let defaultValue: PlaybackRouter? = nil
}

extension EnvironmentValues {
    var playbackRouter: PlaybackRouter? {
        get { self[PlaybackRouterKey.self] }
        set { self[PlaybackRouterKey.self] = newValue }
    }
}
