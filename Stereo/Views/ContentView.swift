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

    /// Namespace partagé pour les transitions matchedGeometryEffect entre
    /// la mini cassette du MiniPlayer et la grande cassette du NowPlayingView.
    @Namespace private var cassetteNamespace

    var body: some View {
        @Bindable var app = app

        ZStack {
            mainShell

            if app.nowPlayingOpen {
                NowPlayingView(onClose: {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        app.nowPlayingOpen = false
                    }
                })
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .environment(\.cassetteNamespace, cassetteNamespace)
        // Bascule l'appearance SwiftUI → toutes les couleurs adaptives de Theme
        // (inkLight, textMute, surface, border…) basculent automatiquement.
        .preferredColorScheme(app.isNightMode ? .dark : .light)
    }

    private var mainShell: some View {
        @Bindable var app = app
        return ZStack(alignment: .topLeading) {
            // — Background uniforme partout (plus de seam entre sidebar/main)
            Theme.background
                .ignoresSafeArea()

            // — Particules de poussière
            if app.showDust {
                DustParticles(
                    count: 22,
                    color: app.isNightMode ? Theme.ocre.opacity(0.6) : Theme.cassetteBody.opacity(0.4)
                )
            }

            // — Shell HStack manuel : sidebar | main | radio
            HStack(spacing: 0) {
                if app.sidebarVisible {
                    SidebarView()
                        .frame(width: 230)
                        .padding(.top, 28)  // respecte la zone des traffic lights
                        .transition(
                            .move(edge: .leading)
                                .combined(with: .opacity)
                        )
                }

                VStack(spacing: 0) {
                    ZStack {
                        pageContent
                            .id("\(app.page.rawValue)-\(app.pageArg ?? "")")
                            .transition(
                                .asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.985)),
                                    removal: .opacity
                                )
                            )
                    }
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: app.page)
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: app.pageArg)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    MiniPlayer()
                }

                if app.radioVisible {
                    RadioPanel()
                        .frame(width: 320)
                        .padding(.top, 28)  // pareil pour le panneau droit
                        .background(
                            LinearGradient(
                                colors: [
                                    Theme.night.opacity(0.6),
                                    Theme.nightDeep.opacity(0.7)
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .transition(
                            .move(edge: .trailing)
                                .combined(with: .opacity)
                        )
                }
            }

            // — Bouton flottant pour rouvrir la sidebar quand elle est cachée
            // (positionné à droite des traffic lights de macOS)
            if !app.sidebarVisible {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        app.sidebarVisible = true
                    }
                } label: {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.inkLight)
                        .frame(width: 28, height: 28)
                        .background(Theme.surface.opacity(0.7))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Theme.borderStrong, lineWidth: 1))
                }
                .buttonStyle(.pressFeedback)
                .padding(.leading, 80)
                .padding(.top, 14)
                .transition(.opacity.combined(with: .scale(scale: 0.85)))
                .help("Afficher la sidebar")
            }
        }
        .frame(minWidth: 980, minHeight: 640)
    }

    @ViewBuilder
    private var pageContent: some View {
        switch app.page {
        case .library:    LibraryView()
        case .local:      LocalView()
        case .playlists:  PlaylistsView()
        case .favorites:  FavoritesView()
        case .search:     SearchView()
        case .soundcloud: SoundCloudView()
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

/// Namespace partagé pour matchedGeometryEffect entre MiniPlayer et NowPlayingView.
/// `nil` quand on n'est pas dans la hierarchie ContentView (cas Preview).
private struct CassetteNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
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

    var cassetteNamespace: Namespace.ID? {
        get { self[CassetteNamespaceKey.self] }
        set { self[CassetteNamespaceKey.self] = newValue }
    }
}

/// ID stable utilisé par matchedGeometryEffect pour la cassette en cours.
/// Une seule cassette à la fois peut "matcher" — c'est toujours `player.current`.
let cassetteMatchID = "currentTrackCassette"
