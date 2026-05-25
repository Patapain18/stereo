//
//  DeckView.swift
//  Stereo · Views/NowPlaying/DeckView.swift
//
//  Style "hi-fi" du NowPlaying — un deck rectangulaire en brushed metal avec
//  cassette dans un cadre noir profond, indicateurs (speed/counter/type),
//  waveform, VU mètre stéréo, transport et glow sur le play actif.
//

import SwiftUI

struct DeckHiFiView: View {
    var track: Track
    @Environment(PlayerState.self) private var player
    @Environment(\.musicController) private var controller
    @Environment(\.cassetteNamespace) private var cassetteNS

    var body: some View {
        VStack(spacing: 0) {
            header
            cassetteFrame
            indicators
            waveformBlock
            stereoVU
            transport
        }
        .padding(30)
        .frame(width: 600)
        .background(
            BrushedMetalBackground()
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10).stroke(Theme.ink, lineWidth: 2)
        )
        .overlay(
            // Vis dans les 4 coins pour le look industriel
            ZStack {
                screw.position(x: 14, y: 14)
                screw.position(x: 586, y: 14)
                screw.position(x: 14, y: 586)
                screw.position(x: 586, y: 586)
            }
            .allowsHitTesting(false)
        )
        .shadow(color: .black.opacity(0.6), radius: 25, x: 0, y: 24)
    }

    private var screw: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.10, green: 0.08, blue: 0.06))
                .frame(width: 8, height: 8)
            Rectangle()
                .fill(Color.black.opacity(0.7))
                .frame(width: 5, height: 1)
        }
    }

    private var header: some View {
        HStack {
            Text("▸ DECK · COMPACT CASSETTE")
                .font(Theme.typewriter(size: 10))
                .tracking(2)
                .foregroundStyle(Theme.ocre)
            Spacer()
            HStack(spacing: 6) {
                breathingLED(color: Theme.copperRed, active: player.isPlaying)
                Circle()
                    .fill(player.isPlaying ? Theme.oliveGreen : Color(red: 0.35, green: 0.29, blue: 0.20))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.bottom, 14)
    }

    /// LED qui "respire" (opacity oscille) quand active.
    private func breathingLED(color: Color, active: Bool) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: !active)) { context in
            let phase = context.date.timeIntervalSinceReferenceDate
            let breathe = active ? (0.65 + 0.35 * sin(phase * 2.5)) : 0.20
            Circle()
                .fill(active ? color : Color(red: 0.35, green: 0.29, blue: 0.20))
                .frame(width: 8, height: 8)
                .shadow(color: color.opacity(active ? breathe * 0.9 : 0), radius: active ? 6 : 0)
                .opacity(active ? 0.6 + 0.4 * breathe : 1)
        }
    }

    private var cassetteFrame: some View {
        ZStack {
            Group {
                if let ns = cassetteNS {
                    CassetteThumb(track: track)
                        .matchedGeometryEffect(id: cassetteMatchID, in: ns)
                } else {
                    CassetteThumb(track: track)
                }
            }
            .frame(width: 360, height: 225)
        }
        .padding(30)
        .background(Color(red: 0.04, green: 0.04, blue: 0.03))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 2)
        )
        .overlay(
            // Reflet diagonal subtil sur le verre du cadre
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            .clear, .clear,
                            Color.white.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .allowsHitTesting(false)
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

    private var stereoVU: some View {
        VUMeterStereo(playing: player.isPlaying, progress: player.progress)
            .frame(height: 60)
            .padding(.top, 14)
            .padding(.horizontal, 80)
    }

    private var transport: some View {
        HStack(spacing: 8) {
            deckButton("⏮", w: 44, primary: false) { controller.previousTrack() }
            deckButton("◂◂", w: 44, primary: false) {
                controller.seek(to: max(0, player.position - track.duration * 0.05))
            }
            primaryPlayButton
            deckButton("▸▸", w: 44, primary: false) {
                controller.seek(to: min(track.duration, player.position + track.duration * 0.05))
            }
            deckButton("⏭", w: 44, primary: false) { controller.nextTrack() }
        }
        .padding(.top, 14)
    }

    /// Bouton play/pause central avec glow pulsant quand actif.
    private var primaryPlayButton: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: !player.isPlaying)) { context in
            let phase = context.date.timeIntervalSinceReferenceDate
            let glow = player.isPlaying ? (0.5 + 0.4 * sin(phase * 2.5)) : 0.0
            Button {
                controller.togglePlay()
            } label: {
                Text(player.isPlaying ? "⏸" : "▶")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 60, height: 38)
                    .background(Theme.ocre)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Theme.ink, lineWidth: 1)
                    )
                    .shadow(color: Theme.ocre.opacity(glow * 0.7), radius: 10 + glow * 8)
                    .shadow(color: Theme.ocre.opacity(glow * 0.4), radius: 18 + glow * 12)
            }
            .buttonStyle(.plain)
        }
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
