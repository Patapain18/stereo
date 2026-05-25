//
//  BrushedMetalBackground.swift
//  Stereo · Components/BrushedMetalBackground.swift
//
//  Effet "brushed metal" pour le corps du deck hi-fi. Combinaison :
//   1. Gradient de base (brun cuivré)
//   2. Pattern de lignes horizontales très fines avec opacités variables
//      (effet brossage)
//   3. Reflet en haut (effet métal poli sous éclairage)
//

import SwiftUI

struct BrushedMetalBackground: View {
    var baseTop: Color = Color(red: 0.29, green: 0.25, blue: 0.17)
    var baseBottom: Color = Color(red: 0.17, green: 0.13, blue: 0.09)

    var body: some View {
        ZStack {
            // 1. Gradient de base
            LinearGradient(
                colors: [baseTop, baseBottom],
                startPoint: .top, endPoint: .bottom
            )

            // 2. Brossage : lignes horizontales
            BrushStripes()
                .blendMode(.overlay)
                .opacity(0.5)

            // 3. Reflet supérieur (effet poli)
            LinearGradient(
                colors: [
                    Color.white.opacity(0.10),
                    .clear,
                    .clear
                ],
                startPoint: .top, endPoint: .bottom
            )

            // 4. Ombre inférieure (assise)
            LinearGradient(
                colors: [
                    .clear,
                    .clear,
                    Color.black.opacity(0.25)
                ],
                startPoint: .top, endPoint: .bottom
            )
        }
    }
}

private struct BrushStripes: View {
    var body: some View {
        Canvas { ctx, size in
            var y: CGFloat = 0
            var seed: UInt32 = 0x9E3779B9
            while y < size.height {
                seed = seed &* 1664525 &+ 1013904223
                let opacity = 0.04 + Double((seed >> 16) & 0xFFF) / Double(0xFFF) * 0.10

                let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                ctx.fill(Path(rect), with: .color(.white.opacity(opacity)))

                seed = seed &* 1664525 &+ 1013904223
                let step = 1 + CGFloat((seed >> 8) & 0x3)
                y += step
            }
        }
    }
}

#Preview {
    BrushedMetalBackground()
        .frame(width: 600, height: 600)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding()
        .background(Theme.background)
}
