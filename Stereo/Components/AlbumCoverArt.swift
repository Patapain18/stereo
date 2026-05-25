//
//  AlbumCoverArt.swift
//  Stereo · Components/AlbumCoverArt.swift
//
//  Variante d'AlbumCover spécialisée pour les cards d'album : cherche la
//  première pochette disponible parmi TOUS les tracks de l'album, pas
//  seulement le premier. Permet d'afficher rapidement une pochette même si
//  on n'a pas visité le track de référence en grille.
//

import SwiftUI

struct AlbumCoverArt: View {
    var album: Album
    var cornerRadius: CGFloat = 6

    @Environment(ArtworkLoader.self) private var artwork

    /// Cherche dans le cache la première image disponible parmi les tracks
    private var image: NSImage? {
        artwork.firstImage(amongTracks: album.tracks)
    }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                if let img = image {
                    Image(nsImage: img)
                        .resizable()
                        .interpolation(.medium)  // qualité réduite = plus rapide au scroll
                        .scaledToFill()
                        .frame(width: side, height: side)
                        .clipped()
                } else {
                    // Fallback : CoverArt généré basé sur l'id album
                    CoverArt(id: album.id)
                        .frame(width: side, height: side)
                }

                // Léger reflet d'angle
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
            .shadow(color: .black.opacity(0.30), radius: 4, x: 0, y: 2)
            // drawingGroup() rasterise le rendu en une texture GPU → bcp moins
            // cher lors du scroll d'une grande grille (shadow + reflets calculés
            // une fois puis cachés)
            .drawingGroup()
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            artwork.ensureAlbumLoaded(tracks: album.tracks)
        }
    }
}
