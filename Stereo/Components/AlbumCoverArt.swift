//
//  AlbumCoverArt.swift
//  Stereo · Components/AlbumCoverArt.swift
//
//  Affiche la pochette d'un album avec un cache local @State pour éviter le
//  re-render en cascade : sans ça, chaque update du dictionnaire `cache` du
//  ArtworkLoader invalide TOUTES les cards de la grille (couplage @Observable).
//
//  Pattern : @State image local + polling court tant qu'on n'a pas trouvé.
//  Une fois cachedImage set, la card ne se re-render plus inutilement.
//

import SwiftUI

struct AlbumCoverArt: View {
    var album: Album
    var cornerRadius: CGFloat = 6

    @Environment(ArtworkLoader.self) private var artwork
    @State private var cachedImage: NSImage? = nil

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                if let img = cachedImage {
                    Image(nsImage: img)
                        .resizable()
                        .interpolation(.medium)
                        .scaledToFill()
                        .frame(width: side, height: side)
                        .clipped()
                } else {
                    CoverArt(id: album.id)
                        .frame(width: side, height: side)
                }
                LinearGradient(
                    colors: [Color.white.opacity(0.08), .clear, Color.black.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .allowsHitTesting(false)
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.black.opacity(0.22), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .task(id: album.id) {
            // Premier check immédiat
            cachedImage = artwork.firstImage(amongTracks: album.tracks)
            if cachedImage == nil {
                artwork.ensureAlbumLoaded(tracks: album.tracks)
            }
            // Poll toutes les 600ms tant qu'on n'a pas d'image (et que la task
            // est vivante = la card est visible). S'arrête dès que trouvé.
            while cachedImage == nil {
                try? await Task.sleep(nanoseconds: 600_000_000)
                if Task.isCancelled { return }
                if let img = artwork.firstImage(amongTracks: album.tracks) {
                    cachedImage = img
                    return
                }
            }
        }
    }
}
