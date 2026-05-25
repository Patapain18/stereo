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
        .commands { keyboardCommands }
    }

    // MARK: — Raccourcis clavier (menu bar macOS)

    @CommandsBuilder
    private var keyboardCommands: some Commands {
        CommandMenu("Lecture") {
            Button("Play / Pause") {
                router?.togglePlay()
            }
            .keyboardShortcut(.space, modifiers: [.command, .shift])

            Button("Suivant") {
                router?.nextTrack()
            }
            .keyboardShortcut(.rightArrow, modifiers: .command)

            Button("Précédent") {
                router?.previousTrack()
            }
            .keyboardShortcut(.leftArrow, modifiers: .command)

            Divider()

            Button("Ouvrir le deck") {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                    app.nowPlayingOpen = true
                }
            }
            .keyboardShortcut("d", modifiers: .command)
            .disabled(app.nowPlayingOpen)
        }

        CommandMenu("Vue") {
            Button("Bibliothèque") { goToPage(.library) }
                .keyboardShortcut("1", modifiers: .command)
            Button("Fichiers locaux") { goToPage(.local) }
                .keyboardShortcut("2", modifiers: .command)
            Button("Playlists") { goToPage(.playlists) }
                .keyboardShortcut("3", modifiers: .command)
            Button("Favoris") { goToPage(.favorites) }
                .keyboardShortcut("4", modifiers: .command)
            Button("Rechercher") { goToPage(.search) }
                .keyboardShortcut("5", modifiers: .command)
            Button("SoundCloud") { goToPage(.soundcloud) }
                .keyboardShortcut("6", modifiers: .command)

            Divider()

            Button(app.isNightMode ? "Mode jour" : "Mode nuit") {
                withAnimation(.easeInOut(duration: 0.25)) {
                    app.isNightMode.toggle()
                }
            }
            .keyboardShortcut("t", modifiers: .command)

            Button(app.sidebarVisible ? "Masquer la sidebar" : "Afficher la sidebar") {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    app.sidebarVisible.toggle()
                }
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])

            Button(app.radioVisible ? "Masquer la stéréo" : "Afficher la stéréo") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    app.radioVisible.toggle()
                }
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
        }
    }

    private func goToPage(_ page: Page) {
        withAnimation(.easeInOut(duration: 0.15)) {
            app.page = page
            app.pageArg = nil
        }
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
