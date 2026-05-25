//
//  PlaylistsView.swift
//  Stereo · Views/Playlists/PlaylistsView.swift
//
//  Dispatch sur app.pageArg :
//  — nil → grille de toutes les playlists
//  — playlistID → vue détail de cette playlist
//

import SwiftUI

struct PlaylistsView: View {
    @Environment(AppState.self) private var app
    @Environment(LibraryStore.self) private var library

    var body: some View {
        if let id = app.pageArg, let playlist = library.playlist(by: id) {
            PlaylistDetailView(playlist: playlist)
        } else {
            PlaylistsGrid()
        }
    }
}

// MARK: — Grille de toutes les playlists

private struct PlaylistsGrid: View {
    @Environment(AppState.self) private var app
    @Environment(LibraryStore.self) private var library

    var body: some View {
        @Bindable var app = app

        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Playlists")
                        .font(Theme.serif(size: 28, weight: .semibold))
                    Text("\(library.playlists.count) playlists")
                        .font(Theme.typewriter(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(24)

            if library.playlists.isEmpty {
                Text("Aucune playlist")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 200), spacing: 16)],
                        spacing: 16
                    ) {
                        ForEach(library.playlists) { pl in
                            Button {
                                app.page = .playlists
                                app.pageArg = pl.id
                            } label: {
                                PlaylistCard(playlist: pl)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
    }
}

private struct PlaylistCard: View {
    var playlist: PlaylistRef

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.tintFromId(playlist.id))
                    .aspectRatio(1, contentMode: .fit)

                VStack {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(Theme.ink.opacity(0.6))
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.name)
                    .font(Theme.hand(size: 16))
                    .foregroundStyle(Theme.inkLight)
                    .lineLimit(1)
                Text("\(playlist.trackCount) morceaux")
                    .font(Theme.typewriter(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: — Vue détail d'une playlist

private struct PlaylistDetailView: View {
    var playlist: PlaylistRef

    @Environment(AppState.self) private var app
    @Environment(LibraryStore.self) private var library

    private var tracks: [Track] {
        library.playlistTracks[playlist.id] ?? []
    }

    private var isLoading: Bool {
        library.loadingPlaylists.contains(playlist.id) && tracks.isEmpty
    }

    var body: some View {
        @Bindable var app = app

        VStack(alignment: .leading, spacing: 0) {
            header

            if isLoading {
                loadingState
            } else if tracks.isEmpty {
                emptyState
            } else {
                if app.libraryViewMode == .shelf {
                    ShelfView(tracks: tracks)
                } else {
                    TrackListView(tracks: tracks)
                }
            }
        }
        .task(id: playlist.id) {
            await library.loadPlaylist(id: playlist.id)
        }
    }

    @ViewBuilder
    private var header: some View {
        @Bindable var app = app

        HStack(alignment: .top, spacing: 14) {
            Button {
                app.pageArg = nil
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.inkLight)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle().stroke(Theme.borderStrong, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .help("Retour aux playlists")
            .keyboardShortcut(.leftArrow, modifiers: [.command])

            VStack(alignment: .leading, spacing: 2) {
                Text("PLAYLIST")
                    .font(Theme.typewriter(size: 10))
                    .tracking(1.5)
                    .foregroundStyle(Theme.textMute)
                Text(playlist.name)
                    .font(Theme.scribble(size: 32))
                    .foregroundStyle(Theme.inkLight)
                    .lineLimit(1)
                Text("\(tracks.count) / \(playlist.trackCount) morceaux \(loadedSuffix)")
                    .font(Theme.typewriter(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Picker("Vue", selection: $app.libraryViewMode) {
                ForEach(LibraryViewMode.allCases, id: \.self) { mode in
                    Image(systemName: mode.icon).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 100)

            Button {
                library.playPlaylist(id: playlist.id)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                    Text("Lire")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Theme.ocre)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(playlist.trackCount == 0)

            Button {
                Task { await library.reloadPlaylist(id: playlist.id) }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkLight)
                    .frame(width: 32, height: 32)
                    .background(Circle().stroke(Theme.borderStrong, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(library.loadingPlaylists.contains(playlist.id))
            .help("Recharger")
        }
        .padding(24)
    }

    private var loadedSuffix: String {
        if library.loadingPlaylists.contains(playlist.id) {
            return "· chargement…"
        }
        return ""
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("chargement des morceaux de \(playlist.name)…")
                .font(Theme.typewriter(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundStyle(.secondary)
            Text("Playlist vide")
                .font(Theme.scribble(size: 18))
                .foregroundStyle(Theme.inkLight)
            Text("ajoute des morceaux à cette playlist depuis Apple Music")
                .font(Theme.typewriter(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
