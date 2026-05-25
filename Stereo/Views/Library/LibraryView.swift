//
//  LibraryView.swift
//  Stereo · Views/Library/LibraryView.swift
//
//  Dispatch sur 4 états :
//   1. Loading (premier chargement)
//   2. Empty (rien dans la biblio)
//   3. Album detail (si app.libraryAlbumDetail est set)
//   4. Liste/grille selon app.libraryViewMode :
//       - .albums → AlbumGridView (par défaut, le plus aéré)
//       - .shelf  → ShelfView (grille de tracks)
//       - .list   → TrackListView (liste plate)
//

import SwiftUI

struct LibraryView: View {
    @Environment(AppState.self) private var app
    @Environment(LibraryStore.self) private var library

    private var albumsAndSingles: (albums: [Album], singles: [Track]) {
        library.tracks.groupedByAlbumAndSingles()
    }

    private var allAlbums: [Album] {
        library.tracks.groupedByAlbum()
    }

    private var currentAlbum: Album? {
        guard let id = app.libraryAlbumDetail else { return nil }
        return allAlbums.first { $0.id == id }
    }

    var body: some View {
        Group {
            if let album = currentAlbum {
                AlbumDetailView(album: album)
            } else {
                mainContent
            }
        }
        .task {
            await library.loadIfNeeded()
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if library.isLoading && library.tracks.isEmpty {
                loadingState
            } else if library.tracks.isEmpty {
                emptyState
            } else {
                modeContent
            }
        }
    }

    @ViewBuilder
    private var modeContent: some View {
        switch app.libraryViewMode {
        case .albums:
            AlbumsAndSinglesView(
                albums: albumsAndSingles.albums,
                singles: albumsAndSingles.singles
            )
        case .shelf:
            ShelfView(tracks: library.tracks)
        case .list:
            TrackListView(tracks: library.tracks)
        }
    }

    private var header: some View {
        @Bindable var app = app
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Bibliothèque")
                    .font(Theme.serif(size: 28, weight: .semibold))
                Text(headerSummary)
                    .font(Theme.typewriter(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()

            Picker("Vue", selection: $app.libraryViewMode) {
                ForEach(LibraryViewMode.allCases, id: \.self) { mode in
                    Image(systemName: mode.icon)
                        .tag(mode)
                        .help(mode.label)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 130)

            Button {
                Task { await library.reload() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkLight)
                    .frame(width: 32, height: 32)
                    .background(Circle().stroke(Theme.borderStrong, lineWidth: 1))
            }
            .buttonStyle(.pressFeedback)
            .disabled(library.isLoading)
            .help("Recharger la bibliothèque")
        }
        .padding(24)
    }

    private var headerSummary: String {
        if library.tracks.isEmpty { return "—" }
        switch app.libraryViewMode {
        case .albums:
            let nbAlbums = albumsAndSingles.albums.count
            let nbSingles = albumsAndSingles.singles.count
            return "\(nbAlbums) albums · \(nbSingles) singles · \(library.tracks.count) morceaux"
        case .shelf, .list:
            return "\(library.tracks.count) morceaux · Apple Music"
        }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Chargement de ta bibliothèque…")
                .font(Theme.typewriter(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "music.note.house",
            title: "ta bibliothèque est vide",
            hint: "ouvre Apple Music et ajoute des morceaux à ta bibliothèque pour qu'ils apparaissent ici. ils seront synchronisés automatiquement."
        )
    }
}
