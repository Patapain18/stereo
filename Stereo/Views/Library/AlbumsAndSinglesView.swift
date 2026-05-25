//
//  AlbumsAndSinglesView.swift
//  Stereo · Views/Library/AlbumsAndSinglesView.swift
//
//  Vue Albums avec 2 sections : vrais albums en grille (pochettes carrées
//  cliquables) puis Singles en grille séparée (tracks orphelins).
//

import SwiftUI

struct AlbumsAndSinglesView: View {
    var albums: [Album]
    var singles: [Track]

    @Environment(AppState.self) private var app
    @Environment(\.playbackRouter) private var router
    @Environment(Favorites.self) private var favorites

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 18)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if !albums.isEmpty {
                    section(title: "Albums", count: albums.count) {
                        LazyVGrid(columns: columns, spacing: 22) {
                            ForEach(albums) { album in
                                AlbumCardLight(album: album) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        app.libraryAlbumDetail = album.id
                                    }
                                }
                            }
                        }
                    }
                }

                if !singles.isEmpty {
                    section(title: "Singles", count: singles.count) {
                        LazyVGrid(columns: columns, spacing: 22) {
                            ForEach(singles) { track in
                                SingleCard(track: track)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private func section<Content: View>(title: String, count: Int, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title)
                    .font(Theme.serif(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.inkLight)
                Text("\(count)")
                    .font(Theme.typewriter(size: 11))
                    .foregroundStyle(Theme.textMute)
            }
            content()
        }
    }
}

// MARK: — Album card

private struct AlbumCardLight: View {
    var album: Album
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                AlbumCoverArt(album: album)
                VStack(alignment: .leading, spacing: 2) {
                    Text(album.name)
                        .font(Theme.serif(size: 14, weight: .medium))
                        .foregroundStyle(Theme.inkLight)
                        .lineLimit(1)
                    Text(album.artist)
                        .font(Theme.typewriter(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text("\(album.tracks.count) morceaux")
                        .font(Theme.typewriter(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.pressFeedback)
    }
}

// MARK: — Single card

private struct SingleCard: View {
    var track: Track
    @Environment(\.playbackRouter) private var router
    @Environment(Favorites.self) private var favorites

    var body: some View {
        Button {
            router?.play(track)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                AlbumCover(track: track)
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(Theme.serif(size: 14, weight: .medium))
                        .foregroundStyle(Theme.inkLight)
                        .lineLimit(1)
                    Text(track.artist)
                        .font(Theme.typewriter(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(.pressFeedback)
        .contextMenu {
            Button("Lire") { router?.play(track) }
            Divider()
            Button(favorites.contains(track) ? "Retirer des favoris" : "Ajouter aux favoris") {
                favorites.toggle(track)
            }
        }
    }
}
