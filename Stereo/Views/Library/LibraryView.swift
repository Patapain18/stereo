//
//  LibraryView.swift
//  Stereo · Views/Library/LibraryView.swift
//

import SwiftUI

struct LibraryView: View {
    @Environment(AppState.self) private var app
    @Environment(LibraryStore.self) private var library
    @Environment(Favorites.self) private var favorites
    @Environment(PlayerState.self) private var player

    var body: some View {
        @Bindable var app = app

        VStack(alignment: .leading, spacing: 0) {
            header

            if library.isLoading && library.tracks.isEmpty {
                loadingState
            } else if library.tracks.isEmpty {
                emptyState
            } else {
                if app.libraryViewMode == .shelf {
                    ShelfView(tracks: library.tracks)
                } else {
                    TrackListView(tracks: library.tracks)
                }
            }
        }
        .task {
            await library.loadIfNeeded()
        }
    }

    private var header: some View {
        @Bindable var app = app
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Bibliothèque")
                    .font(Theme.serif(size: 28, weight: .semibold))
                Text("\(library.tracks.count) morceaux · Apple Music")
                    .font(Theme.mono(size: 11))
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
                Task { await library.reload() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(library.isLoading)
        }
        .padding(24)
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Chargement de ta bibliothèque…")
                .font(Theme.mono(size: 11))
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
