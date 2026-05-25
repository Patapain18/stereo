//
//  AlbumGridView.swift
//  Stereo · Views/Library/AlbumGridView.swift
//
//  Grille de cards Album — la vue par défaut de la bibliothèque. Un OST de
//  24 tracks devient une seule carte Album au lieu de 24 pochettes identiques.
//  Click sur une carte → AlbumDetailView avec les tracks de l'album.
//

import SwiftUI

struct AlbumGridView: View {
    var albums: [Album]

    @Environment(AppState.self) private var app

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 18)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 22) {
                ForEach(albums) { album in
                    AlbumCard(album: album) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            app.libraryAlbumDetail = album.id
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}

private struct AlbumCard: View {
    var album: Album
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                AlbumCover(track: album.coverTrack)
                VStack(alignment: .leading, spacing: 2) {
                    Text(album.name)
                        .font(Theme.serif(size: 14, weight: .medium))
                        .foregroundStyle(Theme.inkLight)
                        .lineLimit(1)
                    Text(album.artist)
                        .font(Theme.typewriter(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    if album.tracks.count > 1 {
                        Text("\(album.tracks.count) morceaux")
                            .font(Theme.typewriter(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .buttonStyle(.pressFeedback)
    }
}
