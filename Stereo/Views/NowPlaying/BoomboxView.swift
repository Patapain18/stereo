//
//  BoomboxView.swift
//  Stereo · Views/NowPlaying/BoomboxView.swift
//
//  Style "boombox" du NowPlaying — 3 colonnes (speaker | center stack | speaker)
//  avec antenne et poignée. Inspiré de hifi-nowplaying.jsx.
//

import SwiftUI

struct BoomboxNPView: View {
    var track: Track
    @Environment(PlayerState.self) private var player
    @Environment(\.musicController) private var controller
    @Environment(\.cassetteNamespace) private var cassetteNS

    var body: some View {
        VStack(spacing: 0) {
            // Antenna (en haut, sortant du corps)
            antenna

            HStack(spacing: 14) {
                speaker
                centerStack
                speaker
            }
        }
        .padding(22)
        .frame(width: 720)
        .background(
            LinearGradient(
                colors: [Color(red: 0.35, green: 0.34, blue: 0.31),
                         Color(red: 0.16, green: 0.15, blue: 0.13)],
                startPoint: .top, endPoint: .bottom
            )
        )
        .overlay(handle, alignment: .top)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.ink, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.7), radius: 30, x: 0, y: 30)
    }

    private var antenna: some View {
        HStack {
            Spacer()
            Rectangle()
                .fill(LinearGradient(
                    colors: [Color(red: 0.81, green: 0.78, blue: 0.68),
                             Color(red: 0.35, green: 0.29, blue: 0.20)],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: 2, height: 60)
                .padding(.trailing, 60)
        }
        .frame(height: 60)
        .offset(y: 30)
    }

    private var handle: some View {
        Capsule()
            .stroke(Theme.ink, lineWidth: 3)
            .frame(width: 200, height: 56)
            .clipShape(Rectangle().offset(y: -14))
            .frame(width: 200, height: 28)
            .offset(y: -28)
    }

    // MARK: — Speaker

    private var speaker: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.10, green: 0.094, blue: 0.078),
                            Color(red: 0.16, green: 0.13, blue: 0.09),
                            Color(red: 0.04, green: 0.04, blue: 0.03)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .overlay(
                    Circle()
                        .stroke(Theme.ink, lineWidth: 2)
                )

            // Speaker cone (inner ring)
            Circle()
                .fill(Color(red: 0.16, green: 0.13, blue: 0.09))
                .frame(width: 90, height: 90)
                .overlay(
                    Circle().stroke(Color.white.opacity(0.04), lineWidth: 0.5)
                )
                .overlay(
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.clear, Color.white.opacity(0.03), .clear],
                                center: .center,
                                startRadius: 30,
                                endRadius: 50
                            )
                        )
                )

            // Center cone
            Circle()
                .fill(Theme.ocre)
                .frame(width: 14, height: 14)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 200)
        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 4)
    }

    // MARK: — Center stack

    private var centerStack: some View {
        VStack(spacing: 10) {
            // Cassette window
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.95, green: 0.93, blue: 0.86).opacity(0.20),
                             Color(red: 0.95, green: 0.93, blue: 0.86).opacity(0.05)],
                    startPoint: .top, endPoint: .bottom
                )
                Group {
                    if let ns = cassetteNS {
                        CassetteThumb(track: track)
                            .matchedGeometryEffect(id: cassetteMatchID, in: ns)
                    } else {
                        CassetteThumb(track: track)
                    }
                }
                .frame(maxWidth: 240)
                LinearGradient(
                    colors: [Color.white.opacity(0.18), .clear, .clear,
                             Color.white.opacity(0.06)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .allowsHitTesting(false)
            }
            .padding(16)
            .frame(maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4).stroke(Theme.ink, lineWidth: 2)
            )

            // Display strip
            HStack {
                Text(player.isPlaying ? "▸ PLAY" : "■ STOP")
                    .font(Theme.typewriter(size: 11))
                    .tracking(1.5)
                    .foregroundStyle(Theme.ocre)
                Spacer()
                Text(player.positionLabel)
                    .font(Theme.typewriter(size: 11))
                    .foregroundStyle(Theme.ocre)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.ink)
            .clipShape(RoundedRectangle(cornerRadius: 3))

            // Transport
            HStack(spacing: 4) {
                bbButton("⏮") { controller.previousTrack() }
                bbButton("◂◂") {
                    controller.seek(to: max(0, player.position - track.duration * 0.05))
                }
                bbButton(player.isPlaying ? "⏸" : "▶", primary: true) {
                    controller.togglePlay()
                }
                bbButton("▸▸") {
                    controller.seek(to: min(track.duration, player.position + track.duration * 0.05))
                }
                bbButton("⏭") { controller.nextTrack() }
            }
        }
    }

    private func bbButton(_ glyph: String, primary: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(glyph)
                .font(.system(size: 14))
                .foregroundStyle(primary ? Theme.ink : Theme.inkLight)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: primary
                            ? [Theme.ocre, Color(red: 0.54, green: 0.41, blue: 0.08)]
                            : [Color(red: 0.23, green: 0.21, blue: 0.19),
                               Color(red: 0.10, green: 0.094, blue: 0.078)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .overlay(
                    RoundedRectangle(cornerRadius: 2).stroke(Color.black.opacity(0.7), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
