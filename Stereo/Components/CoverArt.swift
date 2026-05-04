//
//  CoverArt.swift
//  Stereo · Components/CoverArt.swift
//
//  12 styles de pochette générée procéduralement, fidèle à hifi-primitives.jsx
//  (stripes, blob, rings, sun, mountain, grid, wave, halftone, dot-grid, arch, leaf, tape).
//
//  Sert de fallback quand l'ArtworkLoader n'a pas (encore) résolu la vraie pochette.
//  Les couleurs et le style sont hashés depuis le track.id pour rester stables.
//

import SwiftUI

enum CoverStyle: String, CaseIterable {
    case stripes, blob, rings, sun, mountain, grid, wave, halftone, dotGrid, arch, leaf, tape

    /// Hash déterministe : assigne un style à un id de track
    static func from(id: String) -> CoverStyle {
        let cases = CoverStyle.allCases
        let h = abs(id.hashValue) % cases.count
        return cases[h]
    }
}

struct CoverArt: View {
    var style: CoverStyle
    var accent: Color
    var accent2: Color

    init(style: CoverStyle, accent: Color, accent2: Color) {
        self.style = style
        self.accent = accent
        self.accent2 = accent2
    }

    /// Constructeur pratique : génère style + couleurs depuis un id stable
    init(id: String) {
        let s = CoverStyle.from(id: id)
        let palette = Color.coverPalette(for: id)
        self.init(style: s, accent: palette.0, accent2: palette.1)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                shape(width: w, height: h)
            }
            .clipped()
        }
    }

    @ViewBuilder
    private func shape(width w: CGFloat, height h: CGFloat) -> some View {
        switch style {
        case .stripes:
            StripesPattern(accent: accent, accent2: accent2)
        case .blob:
            BlobPattern(accent: accent, accent2: accent2, w: w, h: h)
        case .rings:
            RingsPattern(accent: accent, accent2: accent2)
        case .sun:
            SunPattern(accent: accent, accent2: accent2, w: w, h: h)
        case .mountain:
            MountainPattern(accent: accent, accent2: accent2, w: w, h: h)
        case .grid:
            GridPattern(accent: accent, accent2: accent2)
        case .wave:
            WavePattern(accent: accent, accent2: accent2, w: w, h: h)
        case .halftone:
            HalftonePattern(accent: accent, accent2: accent2)
        case .dotGrid:
            DotGridPattern(accent: accent, accent2: accent2)
        case .arch:
            ArchPattern(accent: accent, accent2: accent2, w: w, h: h)
        case .leaf:
            LeafPattern(accent: accent, accent2: accent2, w: w, h: h)
        case .tape:
            TapePattern(accent: accent, accent2: accent2, w: w, h: h)
        }
    }
}

// MARK: — Patterns individuels

private struct StripesPattern: View {
    var accent: Color, accent2: Color
    var body: some View {
        Canvas { ctx, size in
            let stripe: CGFloat = 8
            var x: CGFloat = -size.height
            while x < size.width + size.height {
                let path = Path { p in
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x + size.height, y: size.height))
                    p.addLine(to: CGPoint(x: x + size.height + stripe, y: size.height))
                    p.addLine(to: CGPoint(x: x + stripe, y: 0))
                    p.closeSubpath()
                }
                ctx.fill(path, with: .color(accent))
                let path2 = Path { p in
                    p.move(to: CGPoint(x: x + stripe, y: 0))
                    p.addLine(to: CGPoint(x: x + size.height + stripe, y: size.height))
                    p.addLine(to: CGPoint(x: x + size.height + stripe * 2, y: size.height))
                    p.addLine(to: CGPoint(x: x + stripe * 2, y: 0))
                    p.closeSubpath()
                }
                ctx.fill(path2, with: .color(accent2))
                x += stripe * 2
            }
        }
    }
}

private struct BlobPattern: View {
    var accent: Color, accent2: Color, w: CGFloat, h: CGFloat
    var body: some View {
        ZStack {
            accent
            BlobShape()
                .fill(accent2)
                .frame(width: w * 0.75, height: h * 0.75)
                .offset(x: -w * 0.06, y: -h * 0.06)
        }
    }
}

private struct BlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            let w = rect.width, h = rect.height
            p.move(to: CGPoint(x: w * 0.6, y: 0))
            p.addCurve(
                to: CGPoint(x: w, y: h * 0.5),
                control1: CGPoint(x: w * 0.95, y: 0),
                control2: CGPoint(x: w, y: h * 0.2)
            )
            p.addCurve(
                to: CGPoint(x: w * 0.5, y: h),
                control1: CGPoint(x: w, y: h * 0.85),
                control2: CGPoint(x: w * 0.85, y: h)
            )
            p.addCurve(
                to: CGPoint(x: 0, y: h * 0.55),
                control1: CGPoint(x: w * 0.15, y: h),
                control2: CGPoint(x: 0, y: h * 0.85)
            )
            p.addCurve(
                to: CGPoint(x: w * 0.6, y: 0),
                control1: CGPoint(x: 0, y: h * 0.2),
                control2: CGPoint(x: w * 0.25, y: 0)
            )
        }
    }
}

private struct RingsPattern: View {
    var accent: Color, accent2: Color
    var body: some View {
        Canvas { ctx, size in
            let cx = size.width / 2
            let cy = size.height / 2
            let maxR = max(size.width, size.height) * 0.8
            let bands: [(CGFloat, Color)] = [
                (1.00, accent2), (0.70, accent), (0.52, accent2),
                (0.36, accent), (0.18, accent2)
            ]
            for (factor, color) in bands {
                let r = maxR * factor
                let rect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
                ctx.fill(Path(ellipseIn: rect), with: .color(color))
            }
        }
    }
}

private struct SunPattern: View {
    var accent: Color, accent2: Color, w: CGFloat, h: CGFloat
    var body: some View {
        ZStack(alignment: .bottom) {
            accent
            Circle()
                .fill(accent2)
                .frame(width: w * 0.85, height: w * 0.85)
                .offset(y: w * 0.32)
            LinearGradient(
                colors: [accent2.opacity(0.4), .clear],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: h * 0.3)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(width: w, height: h)
        .clipped()
    }
}

private struct MountainPattern: View {
    var accent: Color, accent2: Color, w: CGFloat, h: CGFloat
    var body: some View {
        ZStack {
            accent2
            MountainShape()
                .fill(accent)
                .frame(width: w, height: h * 0.65)
                .frame(maxHeight: .infinity, alignment: .bottom)
            Circle()
                .fill(accent2)
                .brightness(0.15)
                .frame(width: w * 0.16, height: w * 0.16)
                .offset(x: w * 0.25, y: -h * 0.18)
        }
        .frame(width: w, height: h)
    }
}

private struct MountainShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: 0, y: rect.height))
            p.addLine(to: CGPoint(x: rect.width * 0.22, y: rect.height * 0.35))
            p.addLine(to: CGPoint(x: rect.width * 0.48, y: rect.height * 0.70))
            p.addLine(to: CGPoint(x: rect.width * 0.75, y: rect.height * 0.12))
            p.addLine(to: CGPoint(x: rect.width, y: rect.height))
            p.closeSubpath()
        }
    }
}

private struct GridPattern: View {
    var accent: Color, accent2: Color
    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(accent))
            let stroke = StrokeStyle(lineWidth: 1)
            let lineColor = accent2.opacity(0.33)
            let cells = 5
            for i in 0...cells {
                let frac = CGFloat(i) / CGFloat(cells)
                let x = frac * size.width
                let y = frac * size.height
                ctx.stroke(Path { p in
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x, y: size.height))
                }, with: .color(lineColor), style: stroke)
                ctx.stroke(Path { p in
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: size.width, y: y))
                }, with: .color(lineColor), style: stroke)
            }
        }
    }
}

private struct WavePattern: View {
    var accent: Color, accent2: Color, w: CGFloat, h: CGFloat
    var body: some View {
        ZStack {
            accent
            WaveShape(yOffset: 0.58, amplitude: 0.22)
                .fill(accent2)
            WaveShape(yOffset: 0.75, amplitude: 0.22)
                .fill(accent2.opacity(0.5))
        }
    }
}

private struct WaveShape: Shape {
    var yOffset: CGFloat
    var amplitude: CGFloat
    func path(in rect: CGRect) -> Path {
        Path { p in
            let baseY = rect.height * yOffset
            let amp = rect.height * amplitude
            p.move(to: CGPoint(x: 0, y: baseY))
            p.addQuadCurve(
                to: CGPoint(x: rect.width * 0.5, y: baseY),
                control: CGPoint(x: rect.width * 0.25, y: baseY - amp)
            )
            p.addQuadCurve(
                to: CGPoint(x: rect.width, y: baseY),
                control: CGPoint(x: rect.width * 0.75, y: baseY + amp)
            )
            p.addLine(to: CGPoint(x: rect.width, y: rect.height))
            p.addLine(to: CGPoint(x: 0, y: rect.height))
            p.closeSubpath()
        }
    }
}

private struct HalftonePattern: View {
    var accent: Color, accent2: Color
    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(accent2))
            let cells = 7
            let cellW = size.width / CGFloat(cells)
            let cellH = size.height / CGFloat(cells)
            for r in 0..<cells {
                for c in 0..<cells {
                    let cx = (CGFloat(c) + 0.5) * cellW
                    let cy = (CGFloat(r) + 0.5) * cellH
                    let dot = min(cellW, cellH) * 0.45
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: cx - dot/2, y: cy - dot/2, width: dot, height: dot)),
                        with: .color(accent)
                    )
                }
            }
            ctx.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(
                    Gradient(colors: [.clear, accent2.opacity(0.7)]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: size.width, y: size.height)
                )
            )
        }
    }
}

private struct DotGridPattern: View {
    var accent: Color, accent2: Color
    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(accent))
            let cells = 6
            let cellW = size.width / CGFloat(cells)
            let cellH = size.height / CGFloat(cells)
            for r in 0..<cells {
                for c in 0..<cells {
                    let cx = (CGFloat(c) + 0.5) * cellW
                    let cy = (CGFloat(r) + 0.5) * cellH
                    let dot = min(cellW, cellH) * 0.5
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: cx - dot/2, y: cy - dot/2, width: dot, height: dot)),
                        with: .color(accent2)
                    )
                }
            }
        }
    }
}

private struct ArchPattern: View {
    var accent: Color, accent2: Color, w: CGFloat, h: CGFloat
    var body: some View {
        ZStack {
            accent
            ArchShape()
                .fill(accent2)
            Rectangle()
                .fill(accent)
                .frame(height: 0.8)
                .offset(y: h * 0.30)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }
}

private struct ArchShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            let w = rect.width, h = rect.height
            p.move(to: CGPoint(x: w * 0.18, y: h))
            p.addLine(to: CGPoint(x: w * 0.18, y: h * 0.5))
            p.addQuadCurve(
                to: CGPoint(x: w * 0.82, y: h * 0.5),
                control: CGPoint(x: w * 0.5, y: 0)
            )
            p.addLine(to: CGPoint(x: w * 0.82, y: h))
            p.closeSubpath()
        }
    }
}

private struct LeafPattern: View {
    var accent: Color, accent2: Color, w: CGFloat, h: CGFloat
    var body: some View {
        ZStack {
            accent
            LeafShape()
                .fill(accent2)
                .overlay(
                    LeafShape()
                        .stroke(accent, lineWidth: 1)
                )
        }
    }
}

private struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            let w = rect.width, h = rect.height
            p.move(to: CGPoint(x: w * 0.13, y: h * 0.87))
            p.addQuadCurve(
                to: CGPoint(x: w * 0.83, y: h * 0.13),
                control: CGPoint(x: w * 0.23, y: h * 0.23)
            )
            p.addQuadCurve(
                to: CGPoint(x: w * 0.13, y: h * 0.87),
                control: CGPoint(x: w * 0.77, y: h * 0.73)
            )
        }
    }
}

private struct TapePattern: View {
    var accent: Color, accent2: Color, w: CGFloat, h: CGFloat
    var body: some View {
        ZStack {
            accent2
            Rectangle()
                .fill(accent)
                .frame(height: h * 0.4)
                .frame(maxHeight: .infinity, alignment: .center)
            HStack {
                Circle()
                    .fill(accent2)
                    .overlay(Circle().stroke(accent, lineWidth: 2))
                    .frame(width: w * 0.22, height: w * 0.22)
                Spacer()
                Circle()
                    .fill(accent2)
                    .overlay(Circle().stroke(accent, lineWidth: 2))
                    .frame(width: w * 0.22, height: w * 0.22)
            }
            .padding(.horizontal, w * 0.12)
        }
    }
}

// MARK: — Palette helper

extension Color {
    /// Génère 2 couleurs (accent, accent2) stables depuis un id.
    static func coverPalette(for id: String) -> (Color, Color) {
        let palettes: [(Color, Color)] = [
            (Color(red: 0.78, green: 0.59, blue: 0.34), Color(red: 0.52, green: 0.31, blue: 0.18)),  // ocre / cuivre
            (Color(red: 0.36, green: 0.42, blue: 0.23), Color(red: 0.69, green: 0.48, blue: 0.17)),  // mousse / mustard
            (Color(red: 0.55, green: 0.30, blue: 0.16), Color(red: 0.85, green: 0.70, blue: 0.45)),  // terracotta / sable
            (Color(red: 0.32, green: 0.42, blue: 0.55), Color(red: 0.85, green: 0.78, blue: 0.62)),  // bleu nuit / crème
            (Color(red: 0.65, green: 0.30, blue: 0.30), Color(red: 0.90, green: 0.83, blue: 0.65)),  // brique / papier
            (Color(red: 0.42, green: 0.55, blue: 0.45), Color(red: 0.93, green: 0.87, blue: 0.68)),  // vert sauge / ivoire
            (Color(red: 0.28, green: 0.22, blue: 0.18), Color(red: 0.78, green: 0.59, blue: 0.34)),  // brun / ocre
            (Color(red: 0.80, green: 0.50, blue: 0.30), Color(red: 0.30, green: 0.25, blue: 0.20)),  // rouille / brun
        ]
        let h = abs(id.hashValue) % palettes.count
        return palettes[h]
    }
}

#Preview {
    ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 12) {
            ForEach(CoverStyle.allCases, id: \.self) { style in
                VStack(spacing: 4) {
                    CoverArt(style: style, accent: Color(red: 0.78, green: 0.59, blue: 0.34), accent2: Color(red: 0.36, green: 0.42, blue: 0.23))
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    Text(style.rawValue).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
    .background(Theme.night)
}
