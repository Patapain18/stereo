//
//  RadioPanel.swift
//  Stereo · Views/Radio/RadioPanel.swift
//
//  Le panneau "stéréo" à droite — porting fidèle de hifi-radio.jsx.
//
//  Contient une deck card avec : LED REC/STOP, source, mini cassette, readout,
//  waveform interactive, VU mètre, transport buttons. Plus une carte source link
//  cliquable en dessous pour ouvrir le track dans son app native.
//

import SwiftUI
import AppKit

struct RadioPanel: View {
    @Environment(PlayerState.self) private var player
    @Environment(\.musicController) private var controller
    @Environment(\.playbackRouter) private var router

    var body: some View {
        VStack(spacing: 18) {
            header
            deckCard
            if let track = player.current {
                sourceLink(for: track)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 16)
    }

    // MARK: — Header

    private var header: some View {
        HStack {
            Text("STÉRÉO PERSO")
                .font(Theme.typewriter(size: 10))
                .tracking(2)
                .foregroundStyle(Theme.textMute)
            Spacer()
            Text("v.4")
                .font(Theme.typewriter(size: 10))
                .tracking(1)
                .foregroundStyle(Theme.textFaint)
        }
    }

    // MARK: — Deck card

    private var deckCard: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top) {
                LEDIndicator(playing: player.isPlaying)
                Spacer()
                if let src = player.current?.source {
                    Text(label(for: src))
                        .font(Theme.typewriter(size: 9))
                        .tracking(1.5)
                        .foregroundStyle(Theme.textFaint)
                }
            }

            CassetteThumb(track: player.current)
                .frame(maxWidth: 220)

            readout

            if let track = player.current {
                progressBlock(for: track)
            }

            VUMeter(playing: player.isPlaying, progress: player.progress)

            transport
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Theme.nightSurface, Theme.nightDeep],
                startPoint: .top, endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.borderStrong, lineWidth: 1)
        )
        .deckCardShadow()
    }

    @ViewBuilder
    private var readout: some View {
        VStack(spacing: 4) {
            Text(player.current?.title ?? "—")
                .font(Theme.scribble(size: 24))
                .foregroundStyle(Theme.inkLight)
                .lineLimit(1)
                .truncationMode(.tail)

            if let track = player.current {
                Text(track.artist)
                    .font(Theme.hand(size: 13))
                    .foregroundStyle(Theme.textMute)
                    .lineLimit(1)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    private func progressBlock(for track: Track) -> some View {
        VStack(spacing: 6) {
            Waveform(
                progress: player.progress,
                playing: player.isPlaying,
                color: Theme.ocre,
                onSeek: { p in
                    let target = p * track.duration
                    if let r = router { r.seek(toSeconds: target) } else { controller.seek(to: target) }
                }
            )
            .frame(height: 20)

            HStack {
                Text(player.positionLabel)
                    .font(Theme.typewriter(size: 10))
                    .foregroundStyle(Theme.textMute)
                Spacer()
                Text(player.durationLabel)
                    .font(Theme.typewriter(size: 10))
                    .foregroundStyle(Theme.textMute)
            }
        }
    }

    private var transport: some View {
        HStack(spacing: 12) {
            TransportButton(systemImage: "backward.fill") {
                if let r = router { r.previousTrack() } else { controller.previousTrack() }
            }
            TransportButton(
                systemImage: player.isPlaying ? "pause.fill" : "play.fill",
                primary: true
            ) {
                if let r = router { r.togglePlay() } else { controller.togglePlay() }
            }
            TransportButton(systemImage: "forward.fill") {
                if let r = router { r.nextTrack() } else { controller.nextTrack() }
            }
        }
    }

    private func sourceLink(for track: Track) -> some View {
        Button {
            if let url = track.externalURL {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: track.source == .appleMusic ? "music.note" : "waveform")
                    .foregroundStyle(Theme.ocre)
                    .font(.system(size: 14))

                VStack(alignment: .leading, spacing: 2) {
                    Text("ouvrir dans \(sourceName(track.source))")
                        .font(Theme.hand(size: 13))
                        .foregroundStyle(Theme.inkLight)
                        .lineLimit(1)
                    if !track.album.isEmpty {
                        Text(track.album.uppercased())
                            .font(Theme.typewriter(size: 9))
                            .tracking(1)
                            .foregroundStyle(Theme.textFaint)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Text("↗")
                    .foregroundStyle(Theme.textMute)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(track.externalURL == nil)
    }

    // MARK: — Helpers

    private func label(for source: TrackSource) -> String {
        switch source {
        case .appleMusic: return "AM"
        case .soundcloud: return "SC"
        case .iTunesSearch: return "ITUNES"
        case .localFile: return "LOCAL"
        }
    }

    private func sourceName(_ source: TrackSource) -> String {
        switch source {
        case .appleMusic: return "Apple Music"
        case .soundcloud: return "SoundCloud"
        case .iTunesSearch: return "Apple Music"
        case .localFile: return "le Finder"
        }
    }
}

// MARK: — LED REC/STOP

private struct LEDIndicator: View {
    var playing: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(playing ? Theme.copperRed : Theme.oliveDark)
                .frame(width: 6, height: 6)
                .shadow(color: playing ? Theme.copperRed.opacity(0.66) : .clear, radius: 3)

            Text(playing ? "REC" : "STOP")
                .font(Theme.typewriter(size: 9))
                .tracking(1.5)
                .foregroundStyle(Theme.textMute)
        }
    }
}

// MARK: — Transport button

private struct TransportButton: View {
    var systemImage: String
    var primary: Bool = false
    var action: () -> Void

    @State private var pressed: Bool = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: primary ? 16 : 13, weight: .medium))
                .foregroundStyle(primary ? Theme.ink : Theme.inkLight)
                .frame(
                    width: primary ? 48 : 40,
                    height: primary ? 48 : 40
                )
                .background(
                    Circle()
                        .fill(primary ? Theme.ocre : Theme.surface)
                )
                .overlay(
                    Circle()
                        .stroke(primary ? Theme.ink : Theme.borderStrong, lineWidth: primary ? 1.5 : 1)
                )
                .shadow(color: primary ? .black.opacity(0.25) : .clear, radius: 4, y: 2)
                .scaleEffect(pressed ? 0.94 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { _ in }
        .onLongPressGesture(minimumDuration: 0, pressing: { isPressing in
            withAnimation(.easeOut(duration: 0.12)) { pressed = isPressing }
        }, perform: {})
    }
}
