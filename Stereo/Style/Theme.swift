//
//  Theme.swift
//  Stereo · Style/Theme.swift
//
//  Couleurs **adaptives** : chaque token change automatiquement entre mode nuit
//  et mode jour selon le `appearance` SwiftUI courant.
//
//  Pour basculer : on applique `.preferredColorScheme(.dark / .light)` au niveau
//  ContentView selon `app.isNightMode`. Toutes les couleurs définies ici via
//  `Color(NSColor(name:dynamicProvider:))` basculent automatiquement.
//
//  Les accents (ocre, copperRed, oliveGreen) restent fixes — leur identité
//  visuelle est leur force, pas leur adaptation.
//

import SwiftUI
import AppKit

enum Theme {

    // MARK: — Helper pour couleurs adaptives

    private static func adaptive(night: NSColor, day: NSColor) -> Color {
        Color(NSColor(name: nil, dynamicProvider: { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return isDark ? night : day
        }))
    }

    // MARK: — Fonds

    /// Fond principal de l'app
    static let background = adaptive(
        night: NSColor(red: 0.10, green: 0.09, blue: 0.08, alpha: 1),   // sombre
        day:   NSColor(red: 0.96, green: 0.93, blue: 0.86, alpha: 1)    // papier ivoire
    )

    /// Surface intermédiaire (gradient secondaire, deck card top)
    static let nightSurface = adaptive(
        night: NSColor(red: 0.13, green: 0.12, blue: 0.10, alpha: 1),
        day:   NSColor(red: 0.93, green: 0.90, blue: 0.82, alpha: 1)
    )

    /// Surface profonde (gradient deck card bottom)
    static let nightDeep = adaptive(
        night: NSColor(red: 0.08, green: 0.07, blue: 0.06, alpha: 1),
        day:   NSColor(red: 0.90, green: 0.86, blue: 0.76, alpha: 1)
    )

    /// Surface des cards
    static let surface = adaptive(
        night: NSColor(red: 0.16, green: 0.14, blue: 0.12, alpha: 1),
        day:   NSColor(red: 0.92, green: 0.88, blue: 0.78, alpha: 1)
    )

    /// Surface hover/sélectionnée
    static let surfaceHover = adaptive(
        night: NSColor(red: 0.20, green: 0.18, blue: 0.14, alpha: 1),
        day:   NSColor(red: 0.88, green: 0.83, blue: 0.71, alpha: 1)
    )

    /// Anciens alias pour rétro-compat
    static let paper = adaptive(
        night: NSColor(red: 0.96, green: 0.93, blue: 0.86, alpha: 1),
        day:   NSColor(red: 0.96, green: 0.93, blue: 0.86, alpha: 1)
    )
    static let night = background

    // MARK: — Encres et texte (adaptifs)

    /// Encre principale (texte de fond)
    static let ink = adaptive(
        night: NSColor(red: 0.10, green: 0.094, blue: 0.078, alpha: 1),  // ink sombre (cassette body)
        day:   NSColor(red: 0.10, green: 0.094, blue: 0.078, alpha: 1)   // pareil — utilisé pour fond cassette
    )

    /// Texte principal lisible sur le background actif
    static let inkLight = adaptive(
        night: NSColor(red: 0.953, green: 0.925, blue: 0.863, alpha: 1),  // ivoire
        day:   NSColor(red: 0.10, green: 0.094, blue: 0.078, alpha: 1)    // ink sombre
    )

    /// Variantes adoucies — opacité variable selon le contexte
    static let textSoft = adaptive(
        night: NSColor.white.withAlphaComponent(0.78),
        day:   NSColor.black.withAlphaComponent(0.72)
    )
    static let textMute = adaptive(
        night: NSColor.white.withAlphaComponent(0.55),
        day:   NSColor.black.withAlphaComponent(0.55)
    )
    static let textFaint = adaptive(
        night: NSColor.white.withAlphaComponent(0.35),
        day:   NSColor.black.withAlphaComponent(0.38)
    )

    // MARK: — Accents (fixes — leur identité ne change pas selon le mode)

    /// Ocre / cuivre — accent principal
    static let ocre = Color(red: 0.784, green: 0.596, blue: 0.345)       // #c89858

    /// Cuivre rouge — accent secondaire (LED REC, ruban cassette)
    static let copperRed = Color(red: 0.659, green: 0.337, blue: 0.212)  // #a85636
    static let tapeRed = copperRed

    /// Vert olive — VU mètre
    static let oliveGreen = Color(red: 0.420, green: 0.557, blue: 0.239) // #6b8e3d

    /// Vert très foncé — LED en pause
    static let oliveDark = Color(red: 0.247, green: 0.290, blue: 0.149)  // #3f4a26

    /// Beige clair — bobines, étiquette papier
    static let beige = Color(red: 0.741, green: 0.690, blue: 0.604)      // #bdb09a

    /// Étiquette papier (encore plus claire) — fixe
    static let label = Color(red: 0.95, green: 0.91, blue: 0.78)

    /// Brun foncé — coque cassette — fixe
    static let cassetteBody = Color(red: 0.169, green: 0.165, blue: 0.133)  // #2b2a22

    // MARK: — Bordures (adaptives)

    static let border = adaptive(
        night: NSColor.white.withAlphaComponent(0.08),
        day:   NSColor.black.withAlphaComponent(0.12)
    )
    static let borderStrong = adaptive(
        night: NSColor.white.withAlphaComponent(0.18),
        day:   NSColor.black.withAlphaComponent(0.22)
    )

    // MARK: — Polices

    private static let scribbleFamily = "Caveat"
    private static let handFamily = "Kalam"
    private static let typewriterFamily = "SpecialElite"

    static func mono(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static func serif(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func scribble(size: CGFloat) -> Font {
        .custom(scribbleFamily, size: size)
    }

    static func hand(size: CGFloat) -> Font {
        .custom(handFamily, size: size)
    }

    static func handwritten(size: CGFloat) -> Font {
        scribble(size: size)
    }

    static func typewriter(size: CGFloat) -> Font {
        .custom(typewriterFamily, size: size)
    }
}

// MARK: — Modificateurs réutilisables

extension View {
    func softPaperShadow() -> some View {
        self.shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }

    func deckCardShadow() -> some View {
        self.shadow(color: .black.opacity(0.30), radius: 12, x: 0, y: 6)
    }
}
