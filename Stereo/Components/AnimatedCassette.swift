//
//  AnimatedCassette.swift
//  Stereo · Components/AnimatedCassette.swift
//
//  Cassette détaillée avec bobines qui tournent en synchro avec la lecture.
//  Utilisée dans le NowPlayingView à côté du deck pour donner un héros visuel
//  iconique sans dupliquer la pochette (qui est déjà dans la cassette du deck
//  + en background floué).
//

import SwiftUI

struct AnimatedCassette: View {
    var track: Track?
    var isPlaying: Bool

    /// Durée du track en minutes arrondies (pour l'étiquette style "12 MIN")
    private var durationString: String {
        guard let secs = track?.duration, secs > 0 else { return "—" }
        let minutes = Int((secs / 60).rounded())
        return "\(max(1, minutes))"
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let cornerR = min(w, h) * 0.04

            ZStack {
                // — Coque cassette
                RoundedRectangle(cornerRadius: cornerR, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.21, green: 0.18, blue: 0.15),
                                Color(red: 0.13, green: 0.11, blue: 0.09)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerR, style: .continuous)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    )
                    .overlay(
                        // Léger reflet poli supérieur
                        RoundedRectangle(cornerRadius: cornerR, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.07), .clear, .clear],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                    )

                // — Étiquette papier au-dessus du milieu
                paperLabel(width: w, height: h)
                    .offset(y: -h * 0.22)

                // — Slot transparent pour les bobines (effet "vitre")
                RoundedRectangle(cornerRadius: cornerR * 0.5)
                    .fill(Color.black.opacity(0.55))
                    .frame(width: w * 0.78, height: h * 0.30)
                    .offset(y: h * 0.10)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerR * 0.5)
                            .stroke(Color.black.opacity(0.85), lineWidth: 1)
                            .frame(width: w * 0.78, height: h * 0.30)
                            .offset(y: h * 0.10)
                    )

                // — Bobines qui tournent
                HStack(spacing: w * 0.27) {
                    Reel(side: .left, isPlaying: isPlaying)
                        .frame(width: w * 0.16, height: w * 0.16)
                    Reel(side: .right, isPlaying: isPlaying)
                        .frame(width: w * 0.16, height: w * 0.16)
                }
                .offset(y: h * 0.10)

                // — Bande magnétique visible en bas
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.23, green: 0.15, blue: 0.10),
                                Color(red: 0.10, green: 0.07, blue: 0.05)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(width: w * 0.82, height: h * 0.05)
                    .offset(y: h * 0.32)
                    .overlay(
                        // Lignes pour suggérer le défilement de la bande
                        ScrollingTapeLines(playing: isPlaying)
                            .frame(width: w * 0.82, height: h * 0.05)
                            .offset(y: h * 0.32)
                    )

                // — 4 vis pour le côté hi-fi
                let screwR: CGFloat = max(3, w * 0.012)
                let inset: CGFloat = w * 0.04
                ForEach([CGPoint(x: inset, y: inset),
                         CGPoint(x: w - inset, y: inset),
                         CGPoint(x: inset, y: h - inset),
                         CGPoint(x: w - inset, y: h - inset)], id: \.self) { p in
                    screw.frame(width: screwR * 2, height: screwR * 2).position(p)
                }
            }
        }
        .aspectRatio(1.6, contentMode: .fit)
    }

    // MARK: — Étiquette pré-printée style cassette vintage (TDK / Maxell vibe)

    private func paperLabel(width w: CGFloat, height h: CGFloat) -> some View {
        let labelHeight = h * 0.22
        return HStack(spacing: 0) {
            // Bande de couleur ocre à gauche avec branding "A" (Side A)
            ZStack {
                Color(red: 0.74, green: 0.45, blue: 0.18)
                Text("A")
                    .font(Theme.typewriter(size: labelHeight * 0.45))
                    .foregroundStyle(.white)
                    .fontWeight(.bold)
            }
            .frame(width: labelHeight * 0.6)

            // Contenu principal
            HStack(alignment: .center, spacing: w * 0.015) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("STÉRÉO PERSO")
                        .font(Theme.typewriter(size: labelHeight * 0.28))
                        .tracking(1.2)
                        .foregroundStyle(Theme.ink)
                        .fontWeight(.semibold)
                    Text("HIGH BIAS · TYPE II")
                        .font(Theme.typewriter(size: labelHeight * 0.18))
                        .tracking(1)
                        .foregroundStyle(Theme.ink.opacity(0.55))
                }
                Spacer(minLength: 0)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(durationString)
                        .font(Theme.typewriter(size: labelHeight * 0.40))
                        .foregroundStyle(Theme.ink)
                        .contentTransition(.numericText())
                        .animation(.easeOut(duration: 0.3), value: durationString)
                    Text("MIN")
                        .font(Theme.typewriter(size: labelHeight * 0.18))
                        .tracking(1)
                        .foregroundStyle(Theme.ink.opacity(0.55))
                }
            }
            .padding(.horizontal, w * 0.02)
        }
        .frame(width: w * 0.78, height: labelHeight)
        .background(
            ZStack {
                Theme.label
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.06)],
                    startPoint: .leading, endPoint: .trailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)
    }

    // MARK: — Vis

    private var screw: some View {
        ZStack {
            Circle().fill(Color(red: 0.08, green: 0.07, blue: 0.05))
            Rectangle().fill(Color.black.opacity(0.65)).frame(width: 4, height: 0.8)
        }
    }
}

// MARK: — Reel (bobine qui tourne)

private struct Reel: View {
    enum Side { case left, right }
    var side: Side
    var isPlaying: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isPlaying)) { context in
            // 180°/sec, sens horaire
            let seconds = context.date.timeIntervalSinceReferenceDate
            let angle = seconds * 180

            ZStack {
                // Disque extérieur sombre
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.21, green: 0.18, blue: 0.15),
                                Color(red: 0.06, green: 0.05, blue: 0.04)
                            ],
                            center: .center,
                            startRadius: 2, endRadius: 40
                        )
                    )
                    .overlay(
                        Circle().stroke(Color.black.opacity(0.7), lineWidth: 1.2)
                    )

                // 6 rayons rotatifs
                ForEach(0..<6, id: \.self) { i in
                    Capsule()
                        .fill(Theme.beige.opacity(0.85))
                        .frame(width: 3, height: 24)
                        .rotationEffect(.degrees(Double(i) * 60))
                }
                .rotationEffect(.degrees(angle))

                // Moyeu central
                Circle()
                    .fill(Theme.beige)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .fill(Color(red: 0.06, green: 0.05, blue: 0.04))
                            .frame(width: 4, height: 4)
                    )
            }
        }
    }
}

// MARK: — Lignes de bande qui défilent

private struct ScrollingTapeLines: View {
    var playing: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !playing)) { context in
            let offset = (context.date.timeIntervalSinceReferenceDate * 30).truncatingRemainder(dividingBy: 12)
            Canvas { ctx, size in
                let spacing: CGFloat = 6
                var x: CGFloat = -spacing + CGFloat(offset)
                while x < size.width + spacing {
                    let rect = CGRect(x: x, y: 0, width: 1, height: size.height)
                    ctx.fill(Path(rect), with: .color(.white.opacity(0.08)))
                    x += spacing
                }
            }
        }
    }
}

extension CGPoint: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}

#Preview {
    AnimatedCassette(
        track: Track(
            id: "preview",
            title: "Sigilfunk - EP",
            artist: "Irokz",
            album: "EP",
            duration: 180,
            source: .soundcloud
        ),
        isPlaying: true
    )
    .frame(width: 360, height: 225)
    .padding(40)
    .background(Theme.background)
}
