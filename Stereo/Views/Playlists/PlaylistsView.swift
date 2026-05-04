//
//  PlaylistsView.swift
//  Stereo · Views/Playlists/PlaylistsView.swift
//

import SwiftUI

struct PlaylistsView: View {
    @Environment(AppState.self) private var app
    @Environment(LibraryStore.self) private var library

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Playlists")
                        .font(Theme.serif(size: 28, weight: .semibold))
                    Text("\(library.playlists.count) playlists")
                        .font(Theme.mono(size: 11))
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
                            PlaylistCard(playlist: pl)
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
                    .font(Theme.serif(size: 14, weight: .medium))
                    .lineLimit(1)
                Text("\(playlist.trackCount) morceaux")
                    .font(Theme.mono(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
