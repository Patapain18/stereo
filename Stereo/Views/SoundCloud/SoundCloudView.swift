//
//  SoundCloudView.swift
//  Stereo · Views/SoundCloud/SoundCloudView.swift
//
//  Page dédiée SoundCloud — collection de tracks SC ajoutés à la main.
//  L'API SoundCloud étant fermée, on ne peut pas synchroniser la bibliothèque
//  d'un compte : Mathis doit coller les URLs des tracks qu'il veut suivre.
//
//  Une fois ajoutés, click sur une cassette = lecture intégrée via le
//  SoundCloudController (WKWebView caché) ; ça pause Apple Music au passage.
//

import SwiftUI
import AppKit

struct SoundCloudView: View {
    @Environment(SoundCloudLibrary.self) private var scLibrary
    @Environment(Favorites.self) private var favorites
    @Environment(\.playbackRouter) private var router

    @State private var urlInput: String = ""
    @FocusState private var focused: Bool

    private let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 220), spacing: 16)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            addBar
            content
        }
    }

    // MARK: — Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SoundCloud")
                    .font(Theme.serif(size: 28, weight: .semibold))
                Text("\(scLibrary.tracks.count) tracks ajoutés · lecture intégrée")
                    .font(Theme.typewriter(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 12)
    }

    // MARK: — Add bar

    private var addBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: "link")
                    .foregroundStyle(Theme.ocre)
                TextField("colle une URL SoundCloud (ex: https://soundcloud.com/artist/track)",
                          text: $urlInput)
                    .textFieldStyle(.plain)
                    .font(Theme.serif(size: 14))
                    .focused($focused)
                    .onSubmit(addTrack)

                Button(action: addTrack) {
                    HStack(spacing: 6) {
                        if scLibrary.isAdding {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "plus")
                        }
                        Text("ajouter")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Theme.ocre)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(scLibrary.isAdding || urlInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.white.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.15)))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            if let err = scLibrary.lastError {
                Text("⚠ \(err)")
                    .font(Theme.typewriter(size: 10))
                    .foregroundStyle(Theme.copperRed)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }

    // MARK: — Content

    @ViewBuilder
    private var content: some View {
        if scLibrary.tracks.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(scLibrary.tracks) { track in
                        trackCard(track)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.path")
                .font(.system(size: 42, weight: .ultraLight))
                .foregroundStyle(.secondary)
            Text("ta collection SoundCloud est vide")
                .font(Theme.scribble(size: 22))
                .foregroundStyle(Theme.inkLight)
            VStack(spacing: 4) {
                Text("ajoute un track en collant son URL ci-dessus.")
                    .font(Theme.typewriter(size: 11))
                    .foregroundStyle(.secondary)
                Text("astuce : depuis l'app/site SC, clic droit sur un track → Copier le lien.")
                    .font(Theme.typewriter(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 40)
    }

    private func trackCard(_ track: Track) -> some View {
        Button {
            router?.play(track)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                CassetteThumb(track: track)
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(Theme.serif(size: 13, weight: .medium))
                        .foregroundStyle(Theme.inkLight)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Image(systemName: "waveform")
                            .font(.system(size: 9))
                            .foregroundStyle(Theme.ocre)
                        Text(track.artist)
                            .font(Theme.typewriter(size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Lire") { router?.play(track) }
            Divider()
            Button(favorites.contains(track) ? "Retirer des favoris" : "Ajouter aux favoris") {
                favorites.toggle(track)
            }
            Button("Ouvrir dans SoundCloud") {
                if let url = track.externalURL { NSWorkspace.shared.open(url) }
            }
            Divider()
            Button("Supprimer de Stéréo", role: .destructive) {
                scLibrary.remove(track)
            }
        }
    }

    // MARK: — Actions

    private func addTrack() {
        let url = urlInput.trimmingCharacters(in: .whitespaces)
        guard !url.isEmpty else { return }
        Task {
            await scLibrary.addTrack(fromURL: url)
            if scLibrary.lastError == nil {
                urlInput = ""
            }
        }
    }
}
