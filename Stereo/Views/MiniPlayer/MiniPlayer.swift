//
//  MiniPlayer.swift
//  Stereo · Views/MiniPlayer/MiniPlayer.swift
//
//  Mini-player en bas de fenêtre, toujours visible.
//

import SwiftUI

struct MiniPlayer: View {
    @Environment(AppState.self) private var app
    @Environment(PlayerState.self) private var player
    @Environment(\.musicController) private var controller

    var body: some View {
        @Bindable var app = app

        HStack(spacing: 14) {
            // Mini cassette — clic pour ouvrir le now playing immersif
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    app.nowPlayingOpen = true
                }
            } label: {
                CassetteThumb(track: player.current)
                    .frame(width: 80, height: 50)
            }
            .buttonStyle(.plain)
            .disabled(player.current == nil)

            VStack(alignment: .leading, spacing: 2) {
                Text(player.current?.title ?? "Aucun morceau")
                    .font(Theme.serif(size: 13, weight: .medium))
                    .lineLimit(1)
                Text(player.current?.artist ?? "Lance un morceau dans Apple Music")
                    .font(Theme.mono(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                // Progress bar fine
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.1))
                            .frame(height: 2)
                        Capsule().fill(Theme.tapeRed)
                            .frame(width: geo.size.width * player.progress, height: 2)
                    }
                }
                .frame(height: 2)
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                Button { controller.previousTrack() } label: {
                    Image(systemName: "backward.fill")
                }
                Button { controller.togglePlay() } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(.white.opacity(0.1)))
                }
                Button { controller.nextTrack() } label: {
                    Image(systemName: "forward.fill")
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        app.nowPlayingOpen = true
                    }
                } label: {
                    Text("↗ deck")
                        .font(Theme.hand(size: 13))
                        .foregroundStyle(Theme.textMute)
                        .padding(.leading, 6)
                }
                .disabled(player.current == nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 14))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(Rectangle().fill(.white.opacity(0.06)).frame(height: 1), alignment: .top)
    }
}
