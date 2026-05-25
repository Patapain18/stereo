//
//  AlbumCover.swift
//  Stereo · Components/AlbumCover.swift
//
//  Pochette d'album pure et grande — utilisée dans les grilles, le mini-player,
//  le panneau radio. C'est le héros visuel des listes.
//
//  L'aspect "cassette" (étiquette papier + bobines + reflets) est réservé au
//  NowPlayingView (walkman, hi-fi, boombox) — vue immersive uniquement. Quand
//  l'utilisateur clique sur une cover ici, elle se transforme en cassette via
//  matchedGeometryEffect, ce qui donne un effet "déballer la cassette" cinéma.
//
//  Comportement :
//   - Si ArtworkLoader a une image en cache → affiche en grand
//   - Sinon → CoverArt généré (12 patterns) en fallback procédural
//   - Toujours carré (1:1)
//   - Coins arrondis discrets
//   - Léger reflet d'angle pour donner de la profondeur
//

import SwiftUI

struct AlbumCover: View {
    var track: Track?
    var cornerRadius: CGFloat = 6

    @Environment(ArtworkLoader.self) private var artwork

    private var image: NSImage? {
        guard let id = track?.id else { return nil }
        return artwork.image(for: id)
    }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                if let img = image {
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: side, height: side)
                        .clipped()
                } else if let track {
                    CoverArt(id: track.id)
                        .frame(width: side, height: side)
                } else {
                    // Empty state placeholder
                    Theme.surface
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: side * 0.30, weight: .ultraLight))
                                .foregroundStyle(Theme.textFaint)
                        )
                }

                // Léger reflet d'angle pour donner de la profondeur
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.10),
                        .clear, .clear,
                        Color.black.opacity(0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .allowsHitTesting(false)
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.black.opacity(0.25), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 3)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            if let t = track { artwork.ensureLoaded(for: t) }
        }
        .onChange(of: track?.id) { _, _ in
            if let t = track { artwork.ensureLoaded(for: t) }
        }
    }
}

#Preview {
    HStack {
        AlbumCover(track: nil)
            .frame(width: 200, height: 200)
        AlbumCover(track: nil)
            .frame(width: 100, height: 100)
    }
    .padding()
    .background(Theme.background)
}
