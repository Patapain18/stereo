//
//  FavoritesView.swift
//  Stereo · Views/Favorites/FavoritesView.swift
//
//  Recherche les tracks favorites dans TOUTES les sources : bibliothèque Apple
//  Music, bibliothèque SoundCloud, fichiers locaux. Avant cette refonte, seuls
//  les favoris de la biblio Apple Music apparaissaient (bug subtil).
//

import SwiftUI

struct FavoritesView: View {
    @Environment(LibraryStore.self) private var library
    @Environment(SoundCloudLibrary.self) private var scLibrary
    @Environment(LocalLibrary.self) private var localLib
    @Environment(Favorites.self) private var favorites
    @Environment(AppState.self) private var app

    /// Tracks favorites trouvés dans n'importe quelle source connue
    private var favTracks: [Track] {
        let all = library.tracks + scLibrary.tracks + localLib.tracks
        return all.filter { favorites.contains($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            content
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Favoris")
                    .font(Theme.serif(size: 28, weight: .semibold))
                Text("\(favTracks.count) morceau\(favTracks.count > 1 ? "x" : "")")
                    .font(Theme.typewriter(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(24)
    }

    @ViewBuilder
    private var content: some View {
        if favTracks.isEmpty {
            EmptyStateView(
                icon: "heart",
                title: "aucun favori pour l'instant",
                hint: "ajoute tes morceaux préférés avec un clic droit\n→ « Ajouter aux favoris »",
                actionLabel: "Aller à la bibliothèque",
                actionIcon: "books.vertical",
                action: {
                    app.page = .library
                    app.pageArg = nil
                }
            )
        } else {
            if app.libraryViewMode == .shelf {
                ShelfView(tracks: favTracks)
            } else {
                TrackListView(tracks: favTracks)
            }
        }
    }
}
