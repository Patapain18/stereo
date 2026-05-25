//
//  NowPlayingView.swift
//  Stereo · Views/NowPlaying/NowPlayingView.swift
//
//  Vue plein écran "now playing" — walkman immersif inspiré de hifi-nowplaying.jsx.
//  Version simplifiée du walkman : pas de pencil easter egg ni de scrolling tape
//  pour cette première itération. Les styles deck (hi-fi) et boombox sont prévus
//  pour une future session.
//

import SwiftUI
import AppKit

struct NowPlayingView: View {
    @Environment(AppState.self) private var app
    @Environment(PlayerState.self) private var player
    @Environment(\.musicController) private var controller
    @Environment(\.cassetteNamespace) private var cassetteNS

    var onClose: () -> Void

    var body: some View {
        @Bindable var app = app

        ZStack {
            // — Background : pochette HD floue fullscreen + halos colorés
            backgroundLayer

            // — Particules de poussière
            DustParticles(count: 36, color: Theme.ocre.opacity(0.7))

            // — Contenu
            VStack(spacing: 0) {
                topBar
                Spacer()
                if let track = player.current {
                    HStack(alignment: .center, spacing: 50) {
                        trackMetaPanel(track: track)
                        DeckHiFiView(track: track)
                    }
                    .padding(.horizontal, 40)
                } else {
                    emptyState
                }
                Spacer()
            }

            // — Easter egg : crayon en bas à droite (rembobine 10s)
            if app.showDust, player.current != nil {
                PencilEasterEgg(onUse: {
                    let newPos = max(0, player.position - 10)
                    controller.seek(to: newPos)
                })
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.bottom, 28)
                .padding(.trailing, 28)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.night)
        .transition(.opacity.combined(with: .scale(scale: 1.02)))
    }

    private func trackMetaPanel(track: Track) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            // — Pochette HD comme illustration (la cassette est dans le deck)
            Group {
                if let ns = cassetteNS {
                    AlbumCover(track: track, cornerRadius: 8)
                        .matchedGeometryEffect(id: cassetteMatchID, in: ns)
                } else {
                    AlbumCover(track: track, cornerRadius: 8)
                }
            }
            .frame(width: 360, height: 360)
            .shadow(color: .black.opacity(0.55), radius: 22, x: 0, y: 16)

            VStack(alignment: .leading, spacing: 4) {
                Text("~ MAINTENANT ~")
                    .font(Theme.typewriter(size: 11))
                    .tracking(2)
                    .foregroundStyle(Theme.ocre)
                Text(track.title)
                    .font(Theme.scribble(size: 44))
                    .foregroundStyle(Theme.inkLight)
                    .lineLimit(2)
                    .lineSpacing(-8)
                Text(track.artist)
                    .font(Theme.hand(size: 17))
                    .foregroundStyle(Theme.beige)
                if !track.album.isEmpty {
                    Text("album · \(track.album)")
                        .font(Theme.hand(size: 13))
                        .foregroundStyle(Theme.textMute)
                        .italic()
                }
            }
        }
        .frame(width: 360, alignment: .leading)
    }

    // MARK: — Background

    @Environment(ArtworkLoader.self) private var artworkLoader

    private var backgroundLayer: some View {
        ZStack {
            // Fond nuit de base
            Theme.night

            // — Pochette HD floue fullscreen (effet wallpaper)
            // Si on a une image en cache pour le track actuel, on l'étale en
            // background avec un gros blur. La couleur dominante de l'album
            // devient l'ambiance du deck.
            if let track = player.current,
               let img = artworkLoader.image(for: track.id) {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 60)
                    .opacity(0.40)
                    .saturation(1.2)
                    .ignoresSafeArea()
                    .overlay(
                        // Voile pour assurer la lisibilité
                        LinearGradient(
                            colors: [
                                Theme.night.opacity(0.45),
                                Theme.night.opacity(0.75)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    )
                    .transition(.opacity)
            }

            // — Halo ocre en haut à droite (toujours présent, ambiance)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.ocre.opacity(0.22), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 240
                    )
                )
                .frame(width: 480, height: 480)
                .offset(x: 380, y: -240)

            // — Halo vert en bas à gauche
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.oliveGreen.opacity(0.15), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 240
                    )
                )
                .frame(width: 480, height: 480)
                .offset(x: -380, y: 280)
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.4), value: player.current?.id)
    }

    // MARK: — Top bar

    private var topBar: some View {
        HStack {
            Button(action: onClose) {
                Text("↩ retour à la stéréo")
                    .font(Theme.hand(size: 15))
                    .foregroundStyle(Theme.beige)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])

            Spacer()

            if let track = player.current {
                Text("~ EN COURS · \(sourceLabel(track.source)) · HI-FI ~")
                    .font(Theme.typewriter(size: 11))
                    .tracking(2)
                    .foregroundStyle(Theme.ocre)
            }

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.beige)
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 22)
    }

    // MARK: — Walkman body

    private func walkmanBlock(track: Track) -> some View {
        VStack(spacing: 22) {
            walkmanBody(track: track)

            VStack(spacing: 6) {
                Text(track.title)
                    .font(Theme.scribble(size: 38))
                    .foregroundStyle(Theme.inkLight)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(track.artist)
                    .font(Theme.hand(size: 17))
                    .foregroundStyle(Theme.beige)
            }
            .frame(maxWidth: 480)
            .padding(.horizontal, 24)
        }
    }

    private func walkmanBody(track: Track) -> some View {
        VStack(spacing: 12) {
            // Brand strip
            HStack {
                Text("STÉRÉO")
                    .font(Theme.typewriter(size: 10))
                    .tracking(1.5)
                    .foregroundStyle(Color(red: 0.83, green: 0.66, blue: 0.17))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Theme.ink)

                Spacer()

                Text("WK · 04")
                    .font(Theme.typewriter(size: 9))
                    .tracking(1.5)
                    .foregroundStyle(Theme.ink.opacity(0.6))
            }

            // Cassette window — clear plastic
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.95, green: 0.93, blue: 0.86).opacity(0.30),
                             Color(red: 0.95, green: 0.93, blue: 0.86).opacity(0.10)],
                    startPoint: .top, endPoint: .bottom
                )

                // Cassette — matchedGeometryEffect pour la transition fluide
                // depuis/vers la mini cassette du MiniPlayer
                Group {
                    if let ns = cassetteNS {
                        CassetteThumb(track: track)
                            .matchedGeometryEffect(id: cassetteMatchID, in: ns)
                    } else {
                        CassetteThumb(track: track)
                    }
                }
                .frame(width: 280, height: 175)
                .padding(.bottom, 24)

                // Glass reflection
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.25),
                        .clear, .clear,
                        Color.white.opacity(0.10)
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .allowsHitTesting(false)
            }
            .frame(height: 220)
            .overlay(
                ScrollingTape(playing: player.isPlaying, progress: player.progress)
                    .frame(height: 22)
                    .padding(.horizontal, 12 * 4)
                    .padding(.bottom, 6),
                alignment: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Theme.ink, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.4), radius: 14, x: 0, y: 4)

            // Display screen
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(player.isPlaying ? "▸ PLAY" : "■ STOP") · SIDE A")
                        .font(Theme.typewriter(size: 8))
                        .tracking(1)
                        .foregroundStyle(Theme.ocre.opacity(0.5))
                    Text("\(player.positionLabel) / \(player.durationLabel)")
                        .font(Theme.typewriter(size: 11))
                        .foregroundStyle(Theme.ocre)
                        .shadow(color: Theme.ocre.opacity(0.4), radius: 3)
                }
                Spacer()
                CounterDisplay(value: Int(player.progress * 9999), playing: player.isPlaying)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.ink)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.black.opacity(0.7), lineWidth: 1)
            )

            // Transport
            HStack(spacing: 6) {
                walkmanButton(label: "◂◂", sub: "REW") {
                    controller.previousTrack()
                }
                walkmanButton(label: "▸▸", sub: "FF") {
                    controller.nextTrack()
                }
                walkmanButton(label: "▶", sub: "PLAY", primary: true) {
                    controller.togglePlay()
                }
                walkmanButton(label: "■", sub: "STOP") {
                    controller.pause()
                }
                walkmanButton(label: "●", sub: "REC") { }
            }
            .padding(6)
            .background(Color.black.opacity(0.25))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.black.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))

            // Volume slider (sert ici de scrubber position)
            HStack(spacing: 10) {
                Text("POS")
                    .font(Theme.typewriter(size: 9))
                    .tracking(1)
                    .foregroundStyle(Theme.ink.opacity(0.65))

                ScrubberSlider(
                    progress: player.progress,
                    onSeek: { p in
                        controller.seek(to: p * track.duration)
                    }
                )
                .frame(height: 14)
            }
        }
        .padding(16)
        .frame(width: 380, height: 520)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.83, green: 0.66, blue: 0.17),
                    Color(red: 0.72, green: 0.54, blue: 0.12),
                    Color(red: 0.60, green: 0.45, blue: 0.08)
                ],
                startPoint: .top, endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.ink, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.7), radius: 30, x: 0, y: 30)
    }

    private func walkmanButton(label: String, sub: String, primary: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 14))
                    .foregroundStyle(primary ? Theme.ocre : Theme.inkLight)
                Text(sub)
                    .font(Theme.typewriter(size: 7))
                    .tracking(1)
                    .foregroundStyle((primary ? Theme.ocre : Theme.inkLight).opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: primary
                        ? [Color(red: 0.29, green: 0.23, blue: 0.13), Color(red: 0.16, green: 0.13, blue: 0.09)]
                        : [Color(red: 0.23, green: 0.18, blue: 0.13), Color(red: 0.10, green: 0.08, blue: 0.06)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.black.opacity(0.7), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: — Empty state

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "music.note")
                .font(.system(size: 56, weight: .ultraLight))
                .foregroundStyle(Theme.beige)
            Text("aucun morceau en cours")
                .font(Theme.scribble(size: 22))
                .foregroundStyle(Theme.inkLight)
            Text("lance un morceau dans Apple Music")
                .font(Theme.typewriter(size: 11))
                .foregroundStyle(Theme.textMute)
        }
    }

    // MARK: — Helpers

    private func sourceLabel(_ s: TrackSource) -> String {
        switch s {
        case .appleMusic: return "AM"
        case .soundcloud: return "SC"
        case .iTunesSearch: return "ITUNES"
        case .localFile: return "LOCAL"
        }
    }
}

// MARK: — Counter mécanique 4 chiffres

private struct CounterDisplay: View {
    var value: Int
    var playing: Bool

    private var digits: [Character] {
        Array(String(format: "%04d", max(0, min(9999, value))))
    }

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<digits.count, id: \.self) { i in
                Text(String(digits[i]))
                    .font(Theme.typewriter(size: 13))
                    .foregroundStyle(Theme.ocre)
                    .frame(width: 14, height: 18)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.16, green: 0.13, blue: 0.09),
                                Color(red: 0.04, green: 0.04, blue: 0.03),
                                Color(red: 0.16, green: 0.13, blue: 0.09)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 1))
                    .shadow(color: Theme.ocre.opacity(0.4), radius: 3)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(Color(red: 0.04, green: 0.04, blue: 0.03))
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(Theme.ink, lineWidth: 1)
        )
    }
}

// MARK: — Scrubber slider (style walkman)

private struct ScrubberSlider: View {
    var progress: Double
    var onSeek: (Double) -> Void

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.ink)
                    .frame(height: 6)
                    .overlay(
                        Capsule().stroke(Color.black.opacity(0.4), lineWidth: 1)
                    )

                Capsule()
                    .fill(LinearGradient(colors: [Theme.ocre, Color(red: 0.83, green: 0.66, blue: 0.17)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * progress, height: 6)

                Circle()
                    .fill(LinearGradient(colors: [Color(red: 0.83, green: 0.66, blue: 0.17), Color(red: 0.54, green: 0.41, blue: 0.08)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.black.opacity(0.7), lineWidth: 1))
                    .shadow(color: .black.opacity(0.5), radius: 1, y: 1)
                    .offset(x: max(0, geo.size.width * progress - 7))
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                onSeek(max(0, min(1, location.x / geo.size.width)))
            }
        }
    }
}

// MARK: — Scrolling tape (animation bande qui défile)

struct ScrollingTape: View {
    var playing: Bool
    var progress: Double

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0/30.0, paused: !playing)) { context in
            let phase = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 6)
            let offset = phase / 6 * 60  // shift pattern de 60pt par cycle (6s)
            ZStack(alignment: .leading) {
                // Fond brun-noir
                Color(red: 0.23, green: 0.14, blue: 0.09)

                // Pattern stripes diagonales animées
                Canvas { ctx, size in
                    let stripe: CGFloat = 6
                    var x: CGFloat = -size.height + offset
                    while x < size.width + size.height {
                        let path = Path { p in
                            p.move(to: CGPoint(x: x, y: 0))
                            p.addLine(to: CGPoint(x: x + size.height, y: size.height))
                            p.addLine(to: CGPoint(x: x + size.height + 1, y: size.height))
                            p.addLine(to: CGPoint(x: x + 1, y: 0))
                            p.closeSubpath()
                        }
                        ctx.fill(path, with: .color(.white.opacity(0.08)))
                        x += stripe
                    }
                }

                // Voile sombre central
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.5), .clear],
                    startPoint: .top, endPoint: .bottom
                )

                // Curseur de progression
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, Theme.ocre.opacity(0.2), .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                    .frame(width: geo.size.width * progress)
                    .overlay(
                        Rectangle()
                            .fill(Theme.ocre)
                            .frame(width: 1)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Theme.ink, lineWidth: 1)
            )
        }
    }
}

// MARK: — Pencil easter egg (rembobinage à l'ancienne)

struct PencilEasterEgg: View {
    var onUse: () -> Void

    @State private var winding: Bool = false
    @State private var rotation: Double = -12

    var body: some View {
        Button {
            onUse()
            winding = true
            withAnimation(.linear(duration: 1.2)) {
                rotation += 360
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                winding = false
            }
        } label: {
            PencilShape()
                .frame(width: 100, height: 14)
                .rotationEffect(.degrees(rotation), anchor: .trailing)
        }
        .buttonStyle(.plain)
        .help("rembobiner avec le crayon (-10s)")
    }
}

private struct PencilShape: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height

            // Tip (triangle)
            let tipPath = Path { p in
                p.move(to: CGPoint(x: 0, y: h / 2))
                p.addLine(to: CGPoint(x: 14, y: 4))
                p.addLine(to: CGPoint(x: 14, y: 10))
                p.closeSubpath()
            }
            ctx.fill(tipPath, with: .color(Color(red: 0.91, green: 0.78, blue: 0.60)))
            ctx.stroke(tipPath, with: .color(Theme.ink), lineWidth: 0.6)

            // Tip lead (graphite)
            let leadPath = Path { p in
                p.move(to: CGPoint(x: 0, y: h / 2))
                p.addLine(to: CGPoint(x: 6, y: 5.5))
                p.addLine(to: CGPoint(x: 6, y: 8.5))
                p.closeSubpath()
            }
            ctx.fill(leadPath, with: .color(Theme.ink))

            // Body (yellow)
            ctx.fill(
                Path(CGRect(x: 14, y: 4, width: 70, height: 6)),
                with: .color(Color(red: 0.83, green: 0.66, blue: 0.17))
            )
            ctx.stroke(
                Path(CGRect(x: 14, y: 4, width: 70, height: 6)),
                with: .color(Theme.ink),
                lineWidth: 0.6
            )

            // Ferrule
            ctx.fill(
                Path(CGRect(x: 84, y: 3, width: 8, height: 8)),
                with: .color(Color(red: 0.60, green: 0.53, blue: 0.41))
            )
            ctx.stroke(
                Path(CGRect(x: 84, y: 3, width: 8, height: 8)),
                with: .color(Theme.ink),
                lineWidth: 0.6
            )
            // Ferrule stripes
            for y in [5.0, 9.0] {
                ctx.stroke(
                    Path { p in
                        p.move(to: CGPoint(x: 84, y: y))
                        p.addLine(to: CGPoint(x: 92, y: y))
                    },
                    with: .color(Theme.ink),
                    lineWidth: 0.4
                )
            }

            // Eraser (red)
            ctx.fill(
                Path(roundedRect: CGRect(x: 92, y: 3.5, width: 7, height: 7), cornerRadius: 1),
                with: .color(Color(red: 0.77, green: 0.42, blue: 0.29))
            )
            ctx.stroke(
                Path(roundedRect: CGRect(x: 92, y: 3.5, width: 7, height: 7), cornerRadius: 1),
                with: .color(Theme.ink),
                lineWidth: 0.6
            )
            _ = w
            _ = h
        }
    }
}
