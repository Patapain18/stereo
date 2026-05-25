//
//  CassetteThumb.swift
//  Stereo · Components/CassetteThumb.swift
//
//  Vignette cassette pour la grille étagère et le mini-player.
//
//  Sprint 3 : si l'ArtworkLoader a résolu une pochette pour ce track, on
//  l'affiche en background à la place de la couleur de fallback. L'étiquette
//  reste lisible par-dessus.
//

import SwiftUI

struct CassetteThumb: View {
    var track: Track?

    @Environment(ArtworkLoader.self) private var artwork

    private var title: String {
        guard let t = track else { return "—" }
        return t.album.isEmpty ? t.title : t.album
    }

    private var subtitle: String {
        track?.artist ?? "rien"
    }

    private var tint: Color {
        Color.tintFromId(track?.id ?? "x")
    }

    private var image: NSImage? {
        guard let id = track?.id else { return nil }
        return artwork.image(for: id)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // Fond : pochette HD si dispo, sinon CoverArt généré (12 patterns)
                if let img = image {
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: w, height: h)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            // Léger voile sombre pour que l'étiquette reste lisible
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.black.opacity(0.15))
                        )
                } else {
                    CoverArtImage(id: track?.id ?? "x")
                        .frame(width: w, height: h)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(.black.opacity(0.4), lineWidth: 0.5)
                        )
                }

                // Étiquette
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.handwritten(size: 14))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(Theme.mono(size: 9))
                        .foregroundStyle(Theme.ink.opacity(0.6))
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(maxWidth: w * 0.8, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 2).fill(Theme.label))
                .offset(y: -h * 0.15)

                // Bobines
                HStack(spacing: w * 0.20) {
                    Circle().fill(.black.opacity(0.7)).frame(width: w * 0.13)
                    Circle().fill(.black.opacity(0.7)).frame(width: w * 0.13)
                }
                .offset(y: h * 0.18)
            }
        }
        .aspectRatio(1.6, contentMode: .fit)
        .onAppear {
            if let t = track { artwork.ensureLoaded(for: t) }
        }
        .onChange(of: track?.id) { _, _ in
            if let t = track { artwork.ensureLoaded(for: t) }
        }
    }
}

/// Génère une couleur stable à partir d'un id
extension Color {
    static func tintFromId(_ id: String) -> Color {
        let palette: [Color] = [
            Color(red: 0.85, green: 0.78, blue: 0.62),  // crème
            Color(red: 0.82, green: 0.62, blue: 0.55),  // terracotta
            Color(red: 0.55, green: 0.70, blue: 0.65),  // vert d'eau
            Color(red: 0.70, green: 0.55, blue: 0.65),  // mauve
            Color(red: 0.78, green: 0.70, blue: 0.50),  // moutarde
            Color(red: 0.55, green: 0.62, blue: 0.78),  // bleu poudre
        ]
        let h = abs(id.hashValue) % palette.count
        return palette[h]
    }
}
