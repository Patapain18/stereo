//
//  VUMeter.swift
//  Stereo · Components/VUMeter.swift
//
//  VU mètre 22 segments animés, vert→jaune→rouge selon l'amplitude.
//  Fidèle à la maquette React (hifi-radio.jsx).
//

import SwiftUI

struct VUMeter: View {
    var playing: Bool
    var progress: Double  // 0..1
    var bars: Int = 22

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: !playing)) { context in
            let phase = context.date.timeIntervalSinceReferenceDate * 8
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<bars, id: \.self) { i in
                    let isLit = lit(at: i, phase: phase)
                    let height = 3 + CGFloat(i) * 0.8
                    Capsule()
                        .fill(color(at: i, lit: isLit))
                        .frame(maxWidth: .infinity)
                        .frame(height: height)
                }
            }
            .frame(height: 20)
        }
    }

    private func lit(at i: Int, phase: Double) -> Bool {
        guard playing else { return false }
        let normalized = Double(i) / Double(bars)
        let oscillation = sin(Double(i) * 0.7 + phase) * 0.2
        let threshold = 0.3 + oscillation + progress * 0.4
        return normalized < threshold
    }

    private func color(at i: Int, lit: Bool) -> Color {
        let base: Color
        if i > 17 { base = Theme.copperRed }
        else if i > 12 { base = Theme.ocre }
        else { base = Theme.oliveGreen }
        return lit ? base : base.opacity(0.13)
    }
}

#Preview {
    VStack(spacing: 24) {
        VUMeter(playing: true, progress: 0.3)
        VUMeter(playing: true, progress: 0.7)
        VUMeter(playing: false, progress: 0.5)
    }
    .padding(24)
    .background(Theme.nightSurface)
    .frame(width: 320)
}
