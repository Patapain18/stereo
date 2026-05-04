//
//  DeckView.swift
//  Stereo · Views/NowPlaying/DeckView.swift
//
//  Style "hi-fi" du NowPlaying — un deck rectangulaire avec cassette dans un
//  cadre noir profond, 3 boîtes d'indicateurs (speed/counter/type), waveform
//  et 5 boutons transport.
//

import SwiftUI

struct DeckHiFiView: View {
    var track: Track
    @Environment(PlayerState.self) private var player
    @Environment(\.musicController) private var controller

    var body: some View {
        VStack(spacing: 0) {
            header
            cassetteFrame
            indicators
            waveformBlock
            transport
        }
        .padding(30)
        .frame(width: 600)
        .background(
            LinearGradient(
                colors: [Color(red: 0.29, green: 0.25, blue: 0.17),
                         Color(red: 0.17, green: 0.13, blue: 0.09)],
                startPoint: .top, endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10).stroke(Theme.ink, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.6), radius: 25, x: 0, y: 24)
    }

    private var header: some View {
        HStack {
            Text("▸ DECK · COMPACT CASSETTE")
                .font(Theme.typewriter(size: 10))
                .tracking(2)
                .foregroundStyle(Theme.ocre)
            Spacer()
            HStack(spacing: 6) {
                Circle()
                    .fill(player.isPlaying ? Theme.copperRed : Color(red: 0.35, green: 0.29, blue: 0.20))
                    .frame(width: 8, height: 8)
                    .shadow(color: player.isPlaying ? Theme.copperRed.opacity(0.7) : .clear, radius: 4)
                Circle()
                    .fill(player.isPlaying ? Theme.oliveGreen : Color(red: 0.35, green: 0.29, blue: 0.20))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.bottom, 14)
    }

    private var cassetteFrame: some View {
        ZStack {
            CassetteThumb(track: track)
                .frame(width: 360, height: 225)
        }
        .padding(30)
        .background(Color(red: 0.04, green: 0.04, blue: 0.03))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.85), radius: 30, x: 0, y: 0)
    }

    private var indicators: some View {
        HStack(spacing: 10) {
            indicatorBox(label: "SPEED", value: "x1.00", color: Theme.ocre)
            indicatorBox(
                label: "COUNTER",
                value: String(format: "%04d", Int(player.progress * 9999)),
                color: Theme.ocre
            )
            indicatorBox(label: "TYPE", value: "CrO₂", color: Theme.ocre)
        }
        .padding(.top, 14)
    }

    private func indicatorBox(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(label)
                .font(Theme.typewriter(size: 9))
                .tracking(1)
                .foregroundStyle(Color(red: 0.48, green: 0.44, blue: 0.35))
            Text(value)
                .font(Theme.typewriter(size: 12))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .background(Color(red: 0.04, green: 0.04, blue: 0.03))
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(
            RoundedRectangle(cornerRadius: 3).stroke(Theme.ink, lineWidth: 1)
        )
    }

    private var waveformBlock: some View {
        VStack(spacing: 4) {
            Waveform(progress: player.progress, playing: player.isPlaying, color: Theme.ocre, onSeek: { p in
                controller.seek(to: p * track.duration)
            })
            .frame(height: 28)

            HStack {
                Text(player.positionLabel)
                    .font(Theme.typewriter(size: 11))
                    .foregroundStyle(Theme.beige)
                Spacer()
                Text("—" + remainingLabel)
                    .font(Theme.typewriter(size: 11))
                    .foregroundStyle(Theme.beige)
            }
        }
        .padding(.top, 14)
    }

    private var remainingLabel: String {
        let remaining = max(0, track.duration - player.position)
        return PlayerState.format(seconds: remaining)
    }

    private var transport: some View {
        HStack(spacing: 8) {
            deckButton("⏮", w: 44, primary: false) { controller.previousTrack() }
            deckButton("◂◂", w: 44, primary: false) {
                controller.seek(to: max(0, player.position - track.duration * 0.05))
            }
            deckButton(player.isPlaying ? "⏸" : "▶", w: 60, primary: true) {
                controller.togglePlay()
            }
            deckButton("▸▸", w: 44, primary: false) {
                controller.seek(to: min(track.duration, player.position + track.duration * 0.05))
            }
            deckButton("⏭", w: 44, primary: false) { controller.nextTrack() }
        }
        .padding(.top, 14)
    }

    private func deckButton(_ glyph: String, w: CGFloat, primary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(glyph)
                .font(.system(size: 16))
                .foregroundStyle(primary ? Theme.ink : Theme.inkLight)
                .frame(width: w, height: 38)
                .background(primary ? Theme.ocre : Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(primary ? Theme.ink : Theme.borderStrong, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
