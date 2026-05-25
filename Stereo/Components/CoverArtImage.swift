//
//  CoverArtImage.swift
//  Stereo · Components/CoverArtImage.swift
//
//  Variante optimisée de CoverArt : rend le pattern SwiftUI une SEULE FOIS via
//  ImageRenderer puis cache la NSImage en RAM. Les scrolls suivants n'ont plus
//  qu'à afficher un Image(nsImage:) — coût quasi nul comparé à un Canvas
//  redessiné à chaque frame.
//
//  Justification : avec 100+ albums sans pochette résolue (premier lancement,
//  artistes obscurs), les Canvas de CoverArt sont rejoués à chaque scroll, ce
//  qui sature le main thread et provoque le lag. Le cache rend la fluidité
//  équivalente à l'affichage de vraies pochettes.
//
//  Encombrement : 12 styles × 8 palettes au pire = ~96 NSImage de ~150 Ko = ~14 Mo
//  cap absolu. En pratique on cache par id donc chaque album a sa propre image,
//  mais on plafonne à 200 entrées et on évict en FIFO simple.
//

import SwiftUI
import AppKit

@MainActor
final class CoverArtCache {
    static let shared = CoverArtCache()

    private var cache: [String: NSImage] = [:]
    private var insertionOrder: [String] = []
    private let cap = 200

    /// Taille de rendu (par défaut 400×400 pour Retina 2× sur cards ~200px).
    /// Identique au downsample des vraies pochettes — cohérence visuelle.
    private let pixelSize: CGFloat = 400

    func image(for id: String) -> NSImage? {
        if let img = cache[id] { return img }

        let cover = CoverArt(id: id)
            .frame(width: pixelSize, height: pixelSize)

        let renderer = ImageRenderer(content: cover)
        renderer.scale = 1.0  // pixelSize est déjà en pixels physiques
        guard let nsImage = renderer.nsImage else { return nil }

        // Évict FIFO si on dépasse le cap
        if insertionOrder.count >= cap, let oldest = insertionOrder.first {
            cache.removeValue(forKey: oldest)
            insertionOrder.removeFirst()
        }
        cache[id] = nsImage
        insertionOrder.append(id)
        return nsImage
    }

    /// Vide le cache (utile en debug ou après bascule day/night massive).
    func clear() {
        cache.removeAll()
        insertionOrder.removeAll()
    }
}

/// View qui affiche un pattern procédural caché en NSImage RAM.
/// Drop-in remplacement de `CoverArt(id:)` dans les contextes scrollables.
struct CoverArtImage: View {
    var id: String

    var body: some View {
        if let img = CoverArtCache.shared.image(for: id) {
            Image(nsImage: img)
                .resizable()
                .interpolation(.medium)
                .scaledToFill()
        } else {
            // Fallback si le renderer échoue — devrait jamais arriver
            CoverArt(id: id)
        }
    }
}
