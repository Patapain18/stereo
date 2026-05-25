//
//  TrackListView.swift
//  Stereo · Views/Library/TrackListView.swift
//

import SwiftUI

struct TrackListView: View {
    var tracks: [Track]

    @Environment(LibraryStore.self) private var library
    @Environment(Favorites.self) private var favorites
    @Environment(PlayerState.self) private var player
    @Environment(\.playbackRouter) private var router

    private func play(_ track: Track) {
        if let r = router { r.play(track) } else { library.play(track) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                    TrackRow(
                        track: track,
                        index: index + 1,
                        isCurrent: player.current?.id == track.id
                    )
                    .onTapGesture(count: 2) { play(track) }
                    .contextMenu {
                        Button("Lire") { play(track) }
                        Button(favorites.contains(track) ? "Retirer favoris" : "Ajouter aux favoris") {
                            favorites.toggle(track)
                        }
                    }
                    Divider().opacity(0.3)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}

private struct TrackRow: View {
    var track: Track
    var index: Int
    var isCurrent: Bool

    @Environment(Favorites.self) private var favorites

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(Theme.mono(size: 10))
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .trailing)

            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(Theme.serif(size: 13, weight: isCurrent ? .semibold : .regular))
                    .foregroundStyle(isCurrent ? Theme.tapeRed : .primary)
                    .lineLimit(1)
                Text("\(track.artist) · \(track.album)")
                    .font(Theme.mono(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if favorites.contains(track) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Theme.tapeRed)
                    .font(.system(size: 11))
            }

            Text(PlayerState.format(seconds: track.duration))
                .font(Theme.mono(size: 10))
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
    }
}
