//
//  AlbumDetailView.swift
//  Stereo · Views/Library/AlbumDetailView.swift
//
//  Vue détail d'un album : grande pochette à gauche + meta + boutons d'action,
//  liste des tracks à droite (ou en dessous selon la largeur).
//

import SwiftUI

struct AlbumDetailView: View {
    var album: Album

    @Environment(AppState.self) private var app
    @Environment(Favorites.self) private var favorites
    @Environment(PlayerState.self) private var player
    @Environment(\.playbackRouter) private var router

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            tracksList
        }
    }

    // MARK: — Header

    @ViewBuilder
    private var header: some View {
        HStack(alignment: .top, spacing: 22) {
            // Bouton retour
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    app.libraryAlbumDetail = nil
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.inkLight)
                    .frame(width: 32, height: 32)
                    .background(Circle().stroke(Theme.borderStrong, lineWidth: 1))
            }
            .buttonStyle(.pressFeedback)
            .keyboardShortcut(.leftArrow, modifiers: [.command])
            .help("Retour à la bibliothèque")
            .padding(.top, 4)

            // Grande pochette de l'album (cherche dans tous les tracks de l'album)
            AlbumCoverArt(album: album, cornerRadius: 10)
                .frame(width: 200, height: 200)
                .shadow(color: .black.opacity(0.45), radius: 16, x: 0, y: 10)

            // Meta + actions
            VStack(alignment: .leading, spacing: 8) {
                Text("ALBUM")
                    .font(Theme.typewriter(size: 10))
                    .tracking(1.5)
                    .foregroundStyle(Theme.textMute)
                Text(album.name)
                    .font(Theme.serif(size: 32, weight: .semibold))
                    .foregroundStyle(Theme.inkLight)
                    .lineLimit(2)
                Text(album.artist)
                    .font(Theme.hand(size: 18))
                    .foregroundStyle(Theme.beige)
                Text(album.summary)
                    .font(Theme.typewriter(size: 11))
                    .foregroundStyle(Theme.textMute)
                    .padding(.top, 2)

                Spacer(minLength: 0)

                // Actions
                HStack(spacing: 10) {
                    Button {
                        if let first = album.tracks.first {
                            router?.play(first)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                            Text("Lire l'album")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Theme.ocre)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.pressFeedback)
                    .disabled(album.tracks.isEmpty)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(24)
    }

    // MARK: — Tracks list

    private var tracksList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(album.tracks.enumerated()), id: \.element.id) { index, track in
                    AlbumTrackRow(
                        track: track,
                        index: index + 1,
                        isCurrent: player.current?.id == track.id,
                        isFavorite: favorites.contains(track),
                        onPlay: { router?.play(track) },
                        onToggleFav: { favorites.toggle(track) }
                    )
                    Divider().opacity(0.18)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}

private struct AlbumTrackRow: View {
    var track: Track
    var index: Int
    var isCurrent: Bool
    var isFavorite: Bool
    var onPlay: () -> Void
    var onToggleFav: () -> Void

    @State private var hovered: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            // Numéro de piste (ou bouton play au hover)
            ZStack {
                Text("\(index)")
                    .font(Theme.typewriter(size: 11))
                    .foregroundStyle(Theme.textMute)
                    .opacity(hovered ? 0 : 1)
                Image(systemName: "play.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.ocre)
                    .opacity(hovered ? 1 : 0)
            }
            .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(Theme.serif(size: 13, weight: isCurrent ? .semibold : .regular))
                    .foregroundStyle(isCurrent ? Theme.ocre : Theme.inkLight)
                    .lineLimit(1)
                Text(track.artist)
                    .font(Theme.typewriter(size: 10))
                    .foregroundStyle(Theme.textMute)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onToggleFav) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 12))
                    .foregroundStyle(isFavorite ? Theme.tapeRed : Theme.textMute)
                    .opacity(hovered || isFavorite ? 1 : 0)
            }
            .buttonStyle(.pressFeedback)

            Text(PlayerState.format(seconds: track.duration))
                .font(Theme.typewriter(size: 10))
                .foregroundStyle(Theme.textMute)
                .frame(width: 44, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .contentShape(Rectangle())
        .background(hovered ? Theme.surfaceHover.opacity(0.4) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onHover { hovered = $0 }
        .onTapGesture(count: 2, perform: onPlay)
    }
}
