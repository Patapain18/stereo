//
//  EmptyStateView.swift
//  Stereo · Components/EmptyStateView.swift
//
//  Composant réutilisable pour les états vides — cohérence visuelle entre
//  toutes les pages (Bibliothèque vide, Favoris vide, etc.).
//
//  Style : icône SF grosse + ultra-light + ocre, titre en scribble manuscrit,
//  hint en typewriter, et un CTA optionnel.
//

import SwiftUI

struct EmptyStateView: View {
    var icon: String
    var title: String
    var hint: String?
    var actionLabel: String? = nil
    var actionIcon: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 52, weight: .ultraLight))
                .foregroundStyle(Theme.ocre.opacity(0.65))
                .symbolRenderingMode(.monochrome)

            Text(title)
                .font(Theme.scribble(size: 26))
                .foregroundStyle(Theme.inkLight)
                .multilineTextAlignment(.center)

            if let hint {
                Text(hint)
                    .font(Theme.typewriter(size: 11))
                    .foregroundStyle(Theme.textMute)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .frame(maxWidth: 360)
            }

            if let actionLabel, let action {
                Button(action: action) {
                    HStack(spacing: 6) {
                        if let actionIcon {
                            Image(systemName: actionIcon)
                        }
                        Text(actionLabel)
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(Theme.ocre)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 30)
    }
}

#Preview("Avec CTA") {
    EmptyStateView(
        icon: "music.note.house",
        title: "ta bibliothèque est vide",
        hint: "lance Apple Music et ajoute des morceaux à ta bibliothèque pour les voir apparaître ici",
        actionLabel: "Ouvrir Apple Music",
        actionIcon: "arrow.up.right",
        action: {}
    )
    .frame(width: 600, height: 400)
    .background(Theme.background)
}

#Preview("Sans CTA") {
    EmptyStateView(
        icon: "heart.slash",
        title: "aucun favori pour l'instant",
        hint: "clic droit sur une cassette → Ajouter aux favoris"
    )
    .frame(width: 600, height: 400)
    .background(Theme.background)
}
