//
//  CassetteView.swift
//  Stereo · Components/CassetteView.swift
//
//  La cassette qui tourne. Pour le Sprint 1, on garde une version simple
//  mais déjà jolie : coque, étiquette, deux bobines qui tournent.
//
//  La rotation est pilotée par `progress` (0..1). Quand le morceau avance,
//  les bobines tournent. Quand on est en pause, elles s'arrêtent.
//

import SwiftUI

struct CassetteView: View {
    /// Titre affiché sur l'étiquette (souvent l'album ou un mix name)
    var title: String

    /// Sous-titre (artiste)
    var subtitle: String

    /// Progression de lecture (0..1)
    var progress: Double

    /// True = bobines en mouvement
    var isPlaying: Bool

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let radius = min(w, h) * 0.04

            ZStack {
                // — Coque cassette
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Theme.cassetteBody)
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .stroke(.white.opacity(0.06), lineWidth: 1)
                    )
                    .softPaperShadow()

                // — Étiquette papier
                VStack(spacing: 4) {
                    Text(title)
                        .font(Theme.handwritten(size: 22))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(Theme.mono(size: 11))
                        .foregroundStyle(Theme.ink.opacity(0.65))
                        .lineLimit(1)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: w * 0.78)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.label)
                )
                .offset(y: -h * 0.20)

                // — Bobines
                HStack(spacing: w * 0.30) {
                    Reel(progress: progress, isPlaying: isPlaying, side: .left)
                    Reel(progress: progress, isPlaying: isPlaying, side: .right)
                }
                .frame(width: w * 0.50, height: w * 0.18)
                .offset(y: h * 0.10)

                // — Slot bande magnétique
                Rectangle()
                    .fill(Color.black.opacity(0.85))
                    .frame(width: w * 0.78, height: 4)
                    .offset(y: h * 0.32)
            }
        }
        .aspectRatio(1.6, contentMode: .fit)
    }
}

/// Une bobine de cassette qui tourne.
///
/// On utilise `TimelineView(.animation, paused:)` qui est l'approche idiomatique
/// SwiftUI pour les animations gouvernées par un état booléen :
/// — quand `isPlaying = false`, la timeline est paused → l'angle est figé sur sa
///   dernière valeur (pas de fuite CPU non plus).
/// — quand `isPlaying = true`, la timeline tick à 30Hz → rotation fluide.
///
/// La rotation est dérivée de la date courante (180°/sec). Au resume après pause,
/// il peut y avoir un léger saut proportionnel à la durée de pause — acceptable
/// pour le Sprint 1, on raffinera au Sprint 4 (polish) si besoin.
private struct Reel: View {
    enum Side { case left, right }

    var progress: Double
    var isPlaying: Bool
    var side: Side

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isPlaying)) { context in
            let secondsSinceRefDate = context.date.timeIntervalSinceReferenceDate
            let angle = secondsSinceRefDate * 180  // 180°/sec, sens horaire

            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.7))

                // Dents intérieures (rotation visible)
                ForEach(0..<8) { i in
                    Capsule()
                        .fill(Theme.cassetteBody.opacity(0.9))
                        .frame(width: 4, height: 14)
                        .offset(y: -8)
                        .rotationEffect(.degrees(Double(i) * 45))
                }
                .padding(8)

                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            }
            .rotationEffect(.degrees(angle))
        }
    }
}

// MARK: — Preview pour Xcode Canvas

#Preview {
    CassetteView(
        title: "Bleu Pétrole",
        subtitle: "Alain Bashung",
        progress: 0.3,
        isPlaying: true
    )
    .frame(width: 320, height: 200)
    .padding()
    .background(Theme.night)
}
