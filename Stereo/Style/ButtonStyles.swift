//
//  ButtonStyles.swift
//  Stereo · Style/ButtonStyles.swift
//
//  ButtonStyles réutilisables pour le tap feedback. Centralise les animations
//  press/release pour éviter d'avoir à les répéter dans chaque vue.
//

import SwiftUI

/// Style classique : scale 0.94 + opacity 0.85 quand pressed.
/// Spring rapide pour un feedback gratifiant immédiat.
struct PressFeedbackStyle: ButtonStyle {
    var pressScale: CGFloat = 0.94
    var pressOpacity: Double = 0.85

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressScale : 1.0)
            .opacity(configuration.isPressed ? pressOpacity : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressFeedbackStyle {
    /// Helper : `.buttonStyle(.pressFeedback)`
    static var pressFeedback: PressFeedbackStyle { PressFeedbackStyle() }
}
