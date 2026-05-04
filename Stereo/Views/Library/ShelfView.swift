//
//  ShelfView.swift
//  Stereo · Views/Library/ShelfView.swift
//

import SwiftUI

struct ShelfView: View {
    var tracks: [Track]

    @Environment(LibraryStore.self) private var library
    @Environment(Favorites.self) private var favorites

    private let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 220), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(tracks) { track in
                    Button {
                        library.play(track)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            CassetteThumb(track: track)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(track.title)
                                    .font(Theme.serif(size: 13, weight: .medium))
                                    .lineLimit(1)
                                Text(track.artist)
                                    .font(Theme.mono(size: 10))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Lire maintenant") { library.play(track) }
                        Divider()
                        Button(favorites.contains(track) ? "Retirer des favoris" : "Ajouter aux favoris") {
                            favorites.toggle(track)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}
