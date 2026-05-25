//
//  LocalView.swift
//  Stereo · Views/Local/LocalView.swift
//
//  Page dédiée aux fichiers locaux — bibliothèque indexée depuis les dossiers
//  ajoutés par l'utilisateur, avec scan via AVFoundation et lecture via AVPlayer.
//
//  Sans connexion internet requise (sauf pour résoudre les pochettes manquantes
//  via iTunes Search, mais les pochettes embarquées dans les fichiers sont
//  extraites directement).
//

import SwiftUI
import AppKit

struct LocalView: View {
    @Environment(LocalLibrary.self) private var localLib
    @Environment(Favorites.self) private var favorites
    @Environment(\.playbackRouter) private var router
    @Environment(AppState.self) private var app

    var body: some View {
        @Bindable var app = app

        VStack(alignment: .leading, spacing: 0) {
            header
            content
        }
    }

    // MARK: — Header

    private var header: some View {
        @Bindable var app = app
        return HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Fichiers locaux")
                    .font(Theme.serif(size: 28, weight: .semibold))
                if localLib.isScanning {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("scan en cours… \(localLib.scanProgress.current) / \(localLib.scanProgress.total)")
                            .font(Theme.typewriter(size: 11))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("\(localLib.tracks.count) morceaux · \(localLib.folders.count) dossier\(localLib.folders.count > 1 ? "s" : "")")
                        .font(Theme.typewriter(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Mode grille / liste
            if !localLib.tracks.isEmpty {
                Picker("Vue", selection: $app.libraryViewMode) {
                    ForEach(LibraryViewMode.allCases, id: \.self) { mode in
                        Image(systemName: mode.icon).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
            }

            Button {
                Task { await localLib.pickAndAddFolder() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "folder.badge.plus")
                    Text("Ajouter un dossier")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Theme.ocre)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(localLib.isScanning)

            Button {
                Task { await localLib.rescanAll() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkLight)
                    .frame(width: 32, height: 32)
                    .background(Circle().stroke(Theme.borderStrong, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(localLib.isScanning || localLib.folders.isEmpty)
            .help("Re-scanner tous les dossiers")
        }
        .padding(24)
    }

    // MARK: — Content

    @ViewBuilder
    private var content: some View {
        if localLib.folders.isEmpty {
            emptyStateNoFolder
        } else if localLib.tracks.isEmpty && !localLib.isScanning {
            emptyStateNoTracks
        } else {
            tracksGrid
        }
    }

    private var tracksGrid: some View {
        Group {
            if app.libraryViewMode == .shelf {
                ShelfView(tracks: localLib.tracks)
            } else {
                TrackListView(tracks: localLib.tracks)
            }
        }
    }

    private var emptyStateNoFolder: some View {
        VStack(spacing: 14) {
            Image(systemName: "folder")
                .font(.system(size: 56, weight: .ultraLight))
                .foregroundStyle(.secondary)
            Text("aucun dossier ajouté")
                .font(Theme.scribble(size: 22))
                .foregroundStyle(Theme.inkLight)
            Text("ajoute un dossier de musique sur ton Mac pour commencer.\nformats supportés : mp3, m4a, aac, wav, aiff, flac, alac")
                .font(Theme.typewriter(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                Task { await localLib.pickAndAddFolder() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "folder.badge.plus")
                    Text("Choisir un dossier")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Theme.ocre)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 40)
    }

    private var emptyStateNoTracks: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.house")
                .font(.system(size: 42, weight: .ultraLight))
                .foregroundStyle(.secondary)
            Text("aucun fichier audio trouvé")
                .font(Theme.scribble(size: 20))
                .foregroundStyle(Theme.inkLight)
            Text("dans tes \(localLib.folders.count) dossier\(localLib.folders.count > 1 ? "s" : "") ajouté\(localLib.folders.count > 1 ? "s" : "")")
                .font(Theme.typewriter(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
