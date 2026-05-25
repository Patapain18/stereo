//
//  VUMeterStereo.swift
//  Stereo · Components/VUMeterStereo.swift
//
//  VU mètre stéréo (2 colonnes L + R) avec léger déphasage pour donner l'illusion
//  d'un vrai signal stéréo. Utilisé dans le DeckHiFiView.
//

import SwiftUI

struct VUMeterStereo: View {
    var playing: Bool
    var progress: Double
    var bars: Int = 16

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            channel(label: "L", phaseOffset: 0)
            channel(label: "R", phaseOffset: 0.7)
        }
    }

    private func channel(label: String, phaseOffset: Double) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(Theme.typewriter(size: 8))
                .tracking(1)
                .foregroundStyle(Theme.textMute)
            TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: !playing)) { context in
                let phase = context.date.timeIntervalSinceReferenceDate * 8 + phaseOffset * .pi
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(0..<bars, id: \.self) { i in
                        let isLit = lit(at: i, phase: phase)
                        let height = 3 + CGFloat(i) * 0.6
                        Capsule()
                            .fill(color(at: i, lit: isLit))
                            .frame(maxWidth: .infinity)
                            .frame(height: height)
                    }
                }
                .frame(height: 16)
            }
        }
    }

    private func lit(at i: Int, phase: Double) -> Bool {
        guard playing else { return false }
        let normalized = Double(i) / Double(bars)
        let oscillation = sin(Double(i) * 0.7 + phase) * 0.18
        let threshold = 0.3 + oscillation + progress * 0.4
        return normalized < threshold
    }

    private func color(at i: Int, lit: Bool) -> Color {
        let base: Color
        if i > bars - 4 { base = Theme.copperRed }
        else if i > bars - 8 { base = Theme.ocre }
        else { base = Theme.oliveGreen }
        return lit ? base : base.opacity(0.13)
    }
}

#Preview {
    VUMeterStereo(playing: true, progress: 0.4)
        .frame(width: 280, height: 60)
        .padding(24)
        .background(Theme.nightSurface)
}
