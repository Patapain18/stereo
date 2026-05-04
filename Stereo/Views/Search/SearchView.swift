//
//  SearchView.swift
//  Stereo · Views/Search/SearchView.swift
//
//  Recherche locale (dans la bibliothèque chargée) ou dans le catalogue Apple Music
//  public via iTunes Search API.
//

import SwiftUI

private enum SearchScope: String, CaseIterable {
    case local, catalog

    var label: String {
        switch self {
        case .local: return "Ma biblio"
        case .catalog: return "Catalogue Apple Music"
        }
    }
}

struct SearchView: View {
    @Environment(LibraryStore.self) private var library
    @Environment(Favorites.self) private var favorites

    @State private var query: String = ""
    @State private var scope: SearchScope = .local
    @State private var catalogResults: [Track] = []
    @State private var isSearching: Bool = false
    @State private var lastError: String? = nil

    private let itunes = ITunesSearch.shared

    private var localResults: [Track] {
        guard !query.isEmpty else { return [] }
        let q = query.lowercased()
        return library.tracks.filter {
            $0.title.lowercased().contains(q) ||
            $0.artist.lowercased().contains(q) ||
            $0.album.lowercased().contains(q)
        }
    }

    private var displayedResults: [Track] {
        scope == .local ? localResults : catalogResults
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Rechercher")
                    .font(Theme.serif(size: 28, weight: .semibold))

                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("titre, artiste, album…", text: $query)
                        .textFieldStyle(.plain)
                        .font(Theme.serif(size: 14))
                        .onSubmit { runCatalogSearchIfNeeded() }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.15)))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Picker("Source", selection: $scope) {
                    ForEach(SearchScope.allCases, id: \.self) { s in
                        Text(s.label).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: scope) { _, _ in runCatalogSearchIfNeeded() }
            }
            .padding(24)

            content
        }
    }

    @ViewBuilder
    private var content: some View {
        if query.isEmpty {
            placeholder(
                icon: "magnifyingglass",
                title: "Tape pour chercher",
                hint: scope == .local
                    ? "dans tes \(library.tracks.count) morceaux"
                    : "dans le catalogue Apple Music"
            )
        } else if scope == .catalog && isSearching {
            VStack(spacing: 12) {
                ProgressView()
                Text("recherche dans le catalogue…")
                    .font(Theme.mono(size: 11))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let err = lastError, scope == .catalog {
            placeholder(icon: "exclamationmark.triangle", title: "Erreur", hint: err)
        } else if displayedResults.isEmpty {
            placeholder(icon: "music.note.list", title: "Aucun résultat", hint: "essaye une autre orthographe")
        } else if scope == .catalog {
            CatalogResultsView(tracks: displayedResults)
        } else {
            TrackListView(tracks: displayedResults)
        }
    }

    private func placeholder(icon: String, title: String, hint: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .ultraLight))
                .foregroundStyle(.secondary)
            Text(title)
                .font(Theme.serif(size: 16))
            Text(hint)
                .font(Theme.mono(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func runCatalogSearchIfNeeded() {
        guard scope == .catalog, !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            catalogResults = []
            return
        }
        let q = query
        isSearching = true
        lastError = nil
        Task {
            do {
                let results = try await itunes.searchCatalog(query: q)
                if q == query {  // évite le race si l'utilisateur a re-tapé
                    catalogResults = results
                }
            } catch {
                lastError = error.localizedDescription
            }
            isSearching = false
        }
    }
}

/// Vue dédiée pour les résultats du catalogue (cliquer ouvre Apple Music dans
/// le navigateur ou l'app native via le deep link).
private struct CatalogResultsView: View {
    var tracks: [Track]

    @Environment(Favorites.self) private var favorites

    private let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 220), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(tracks) { track in
                    Button {
                        if let url = track.externalURL {
                            NSWorkspace.shared.open(url)
                        }
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
                        Button("Ouvrir dans Apple Music") {
                            if let url = track.externalURL { NSWorkspace.shared.open(url) }
                        }
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
