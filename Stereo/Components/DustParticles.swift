//
//  DustParticles.swift
//  Stereo · Components/DustParticles.swift
//
//  Particules de poussière flottantes en arrière-plan, pour l'ambiance hi-fi
//  vintage. Animées via TimelineView (idiom SwiftUI moderne, pas de Timer manuel).
//

import SwiftUI

struct DustParticles: View {
    var count: Int = 18
    var color: Color = Theme.ocre

    /// Génère les paramètres de chaque particule (positions, deltas, durées)
    /// déterministes via l'index, comme dans la maquette React.
    private var dots: [Dot] {
        var result: [Dot] = []
        result.reserveCapacity(count)
        for i in 0..<count {
            let seedX: CGFloat = CGFloat((i * 137) % 100) / 100.0
            let seedY: CGFloat = CGFloat((i * 91) % 100) / 100.0
            let dx: CGFloat = CGFloat((i * 53) % 50) - 25.0
            let dy: CGFloat = -CGFloat((i * 41) % 60) - 30.0
            let delay: Double = Double(i) * 0.7
            let duration: Double = 7.0 + Double(i % 4)
            let size: CGFloat = 2.0 + CGFloat(i % 2)
            result.append(Dot(seedX: seedX, seedY: seedY, dx: dx, dy: dy, delay: delay, duration: duration, size: size))
        }
        return result
    }

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
                let now = context.date.timeIntervalSinceReferenceDate
                ZStack {
                    ForEach(0..<dots.count, id: \.self) { i in
                        let dot = dots[i]
                        let progress = ((now + dot.delay).truncatingRemainder(dividingBy: dot.duration)) / dot.duration
                        let x = dot.seedX * geo.size.width + dot.dx * progress
                        let y = dot.seedY * geo.size.height + dot.dy * progress
                        let opacity = sin(progress * .pi)  // fade in puis out

                        Circle()
                            .fill(color)
                            .frame(width: dot.size, height: dot.size)
                            .blur(radius: 0.5)
                            .opacity(opacity * 0.45)
                            .position(x: x, y: y)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private struct Dot {
        let seedX: CGFloat
        let seedY: CGFloat
        let dx: CGFloat
        let dy: CGFloat
        let delay: Double
        let duration: Double
        let size: CGFloat
    }
}

#Preview {
    ZStack {
        Theme.night.ignoresSafeArea()
        DustParticles(count: 24)
    }
    .frame(width: 800, height: 500)
}
