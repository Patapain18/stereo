//
//  Waveform.swift
//  Stereo · Components/Waveform.swift
//
//  Forme d'onde stylisée, clickable pour seek. Hauteurs déterministes via
//  une seed sin/cos (comme dans hifi-primitives.jsx) — pas une vraie analyse audio.
//

import SwiftUI

struct Waveform: View {
    var progress: Double             // 0..1
    var playing: Bool = false
    var color: Color = Theme.ocre
    /// Callback quand l'utilisateur clique pour seek (0..1)
    var onSeek: ((Double) -> Void)?

    private let seed: [CGFloat] = (0..<64).map { i in
        let v = abs(sin(Double(i) * 1.7) * 12 + cos(Double(i) * 0.6) * 4)
        return 4 + CGFloat(v)
    }

    var body: some View {
        GeometryReader { geo in
            let bars = max(1, Int(geo.size.width / 4))
            HStack(alignment: .center, spacing: 1) {
                ForEach(0..<bars, id: \.self) { i in
                    let normalized = Double(i) / Double(bars)
                    let h = (seed[i % seed.count] / 16) * geo.size.height
                    let filled = normalized < progress
                    let isHead = playing && abs(normalized - progress) < 0.04
                    Capsule()
                        .fill(filled ? color : color.opacity(0.33))
                        .frame(width: 2, height: max(2, h))
                        .scaleEffect(y: isHead ? 1.15 : 1.0, anchor: .center)
                        .animation(.easeInOut(duration: 0.2), value: isHead)
                }
            }
            .frame(height: geo.size.height, alignment: .center)
            .contentShape(Rectangle())
            .onTapGesture { location in
                guard let onSeek else { return }
                let p = max(0, min(1, location.x / geo.size.width))
                onSeek(p)
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        Waveform(progress: 0.4, playing: true)
            .frame(width: 280, height: 22)
        Waveform(progress: 0.8, playing: false, color: Theme.copperRed)
            .frame(width: 280, height: 22)
    }
    .padding()
    .background(Theme.nightSurface)
}
