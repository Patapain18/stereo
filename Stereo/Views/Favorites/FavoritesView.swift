//
//  FavoritesView.swift
//  Stereo · Views/Favorites/FavoritesView.swift
//

import SwiftUI

struct FavoritesView: View {
    @Environment(LibraryStore.self) private var library
    @Environment(Favorites.self) private var favorites

    private var favTracks: [Track] {
        library.tracks.filter { favorites.contains($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Favoris")
                        .font(Theme.serif(size: 28, weight: .semibold))
                    Text("\(favTracks.count) morceaux")
                        .font(Theme.mono(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(24)

            if favTracks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 40, weight: .ultraLight))
                        .foregroundStyle(.secondary)
                    Text("Aucun favori pour l'instant")
                        .font(Theme.serif(size: 14))
                    Text("Clic droit sur un morceau → Ajouter aux favoris")
                        .font(Theme.mono(size: 10))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ShelfView(tracks: favTracks)
            }
        }
    }
}
