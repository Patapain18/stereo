//
//  ContentView.swift  (REMPLACE celui du Sprint 1+2)
//  Stereo · Views/ContentView.swift
//
//  Sprint 4 polish : layout 3 colonnes (sidebar + page + radio panel) avec
//  particules de poussière en background pour l'ambiance hi-fi vintage.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        @Bindable var app = app

        ZStack {
            mainShell

            if app.nowPlayingOpen {
                NowPlayingView(onClose: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        app.nowPlayingOpen = false
                    }
                })
                .transition(.opacity)
                .zIndex(10)
            }
        }
    }

    private var mainShell: some View {
        @Bindable var app = app
        return NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 230, max: 300)
        } detail: {
            ZStack {
                // — Background : papier ou nuit
                (app.isNightMode ? Theme.night : Theme.paper)
                    .ignoresSafeArea()

                // — Particules de poussière en arrière-plan
                if app.showDust {
                    DustParticles(
                        count: 22,
                        color: app.isNightMode ? Theme.ocre.opacity(0.6) : Theme.cassetteBody.opacity(0.4)
                    )
                }

                // — Contenu
                HStack(spacing: 0) {
                    // Colonne principale : page courante + mini-player
                    VStack(spacing: 0) {
                        pageContent
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        MiniPlayer()
                    }

                    // Séparateur + RadioPanel
                    if app.radioVisible {
                        Divider()
                            .background(Theme.border)

                        RadioPanel()
                            .frame(width: 320)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Theme.night.opacity(0.6),
                                        Theme.nightDeep.opacity(0.7)
                                    ],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            app.radioVisible.toggle()
                        }
                    } label: {
                        Image(systemName: app.radioVisible ? "rectangle.righthalf.inset.filled" : "rectangle.righthalf.inset.filled.arrow.right")
                    }
                    .help(app.radioVisible ? "Masquer la stéréo" : "Afficher la stéréo")
                }
            }
        }
        .frame(minWidth: 980, minHeight: 640)
    }

    @ViewBuilder
    private var pageContent: some View {
        switch app.page {
        case .library:    LibraryView()
        case .playlists:  PlaylistsView()
        case .favorites:  FavoritesView()
        case .search:     SearchView()
        }
    }
}

// MARK: — EnvironmentKeys

private struct MusicControllerKey: EnvironmentKey {
    static let defaultValue = MusicController()
}

private struct MusicWatcherKey: EnvironmentKey {
    static let defaultValue: MusicWatcher? = nil
}

extension EnvironmentValues {
    var musicController: MusicController {
        get { self[MusicControllerKey.self] }
        set { self[MusicControllerKey.self] = newValue }
    }

    var musicWatcher: MusicWatcher? {
        get { self[MusicWatcherKey.self] }
        set { self[MusicWatcherKey.self] = newValue }
    }
}
