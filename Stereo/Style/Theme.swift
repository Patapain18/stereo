//
//  Theme.swift
//  Stereo · Style/Theme.swift
//
//  Sprint 4 polish : couleurs alignées sur la maquette React (palette ocre/sépia).
//

import SwiftUI

enum Theme {
    // MARK: — Fonds

    /// Fond papier ivoire (mode jour)
    static let paper = Color(red: 0.96, green: 0.93, blue: 0.86)

    /// Fond très sombre (mode nuit) — équivalent --bg principal
    static let night = Color(red: 0.10, green: 0.09, blue: 0.08)

    /// Surface intermédiaire sombre — équivalent --bg-2
    static let nightSurface = Color(red: 0.13, green: 0.12, blue: 0.10)  // #221f1a

    /// Surface plus profonde — équivalent --bg-3
    static let nightDeep = Color(red: 0.08, green: 0.07, blue: 0.06)     // #15130f

    /// Surface card en mode nuit — équivalent --surface
    static let surface = Color(red: 0.16, green: 0.14, blue: 0.12)

    /// Surface card hover — équivalent --surface-2
    static let surfaceHover = Color(red: 0.20, green: 0.18, blue: 0.14)

    // MARK: — Encres et texte

    /// Couleur encre noire (texte principal jour, fond cassette)
    static let ink = Color(red: 0.10, green: 0.094, blue: 0.078)         // #1a1814

    /// Texte principal en mode nuit (papier ivoire) — équivalent --text
    static let inkLight = Color(red: 0.953, green: 0.925, blue: 0.863)   // #f3ecdc

    /// Variantes d'opacité du texte
    static let textSoft = Color.white.opacity(0.78)
    static let textMute = Color.white.opacity(0.55)
    static let textFaint = Color.white.opacity(0.35)

    // MARK: — Accents

    /// Ocre / cuivre — accent principal (boutons primary, indicateurs lecture)
    static let ocre = Color(red: 0.784, green: 0.596, blue: 0.345)       // #c89858

    /// Cuivre rouge — accent secondaire (LED REC, ruban cassette, état actif)
    static let copperRed = Color(red: 0.659, green: 0.337, blue: 0.212)  // #a85636
    static let tapeRed = copperRed  // alias rétro-compat

    /// Vert olive — VU mètre (segments low/mid)
    static let oliveGreen = Color(red: 0.420, green: 0.557, blue: 0.239) // #6b8e3d

    /// Vert très foncé — LED en pause
    static let oliveDark = Color(red: 0.247, green: 0.290, blue: 0.149)  // #3f4a26

    /// Beige clair — bobines, étiquette papier
    static let beige = Color(red: 0.741, green: 0.690, blue: 0.604)      // #bdb09a

    /// Étiquette papier (encore plus claire)
    static let label = Color(red: 0.95, green: 0.91, blue: 0.78)

    /// Brun foncé — coque cassette
    static let cassetteBody = Color(red: 0.169, green: 0.165, blue: 0.133)  // #2b2a22

    // MARK: — Bordures

    static let border = Color.white.opacity(0.08)
    static let borderStrong = Color.white.opacity(0.18)

    // MARK: — Polices
    //
    // Polices custom embarquées dans le bundle via ATSApplicationFontsPath:
    // — Caveat : script grand format pour les titres "scribble"
    // — Kalam : manuscrit moyen pour les sous-titres "hand"
    // — Special Elite : typewriter pour les labels et métadonnées
    //
    // Si une police n'est pas chargée (cas dev / preview), `.custom` retombe
    // gracieusement sur Helvetica.

    private static let scribbleFamily = "Caveat"
    private static let handFamily = "Kalam"
    private static let typewriterFamily = "SpecialElite"

    static func mono(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static func serif(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    /// Style "scribble" — gros titres manuscrits (Caveat)
    static func scribble(size: CGFloat) -> Font {
        .custom(scribbleFamily, size: size)
    }

    /// Style "hand" — texte manuscrit moyen (Kalam)
    static func hand(size: CGFloat) -> Font {
        .custom(handFamily, size: size)
    }

    /// Conservé pour rétrocompat sprint 1+2
    static func handwritten(size: CGFloat) -> Font {
        scribble(size: size)
    }

    /// Style typewriter — labels, badges, métadonnées (Special Elite)
    static func typewriter(size: CGFloat) -> Font {
        .custom(typewriterFamily, size: size)
    }
}

// MARK: — Modificateurs réutilisables

extension View {
    /// Ombre douce style papier
    func softPaperShadow() -> some View {
        self.shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }

    /// Ombre prononcée pour les cards principales (deck card du RadioPanel)
    func deckCardShadow() -> some View {
        self.shadow(color: .black.opacity(0.30), radius: 12, x: 0, y: 6)
    }
}
