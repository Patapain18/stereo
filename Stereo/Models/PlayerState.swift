//
//  PlayerState.swift
//  Stereo · Models/PlayerState.swift
//
//  L'état actuel de la lecture, observable par toutes les vues.
//  C'est l'équivalent d'un store React (Zustand, Redux...) pour la lecture.
//
//  En Swift moderne, on utilise @Observable. Toute vue qui lit une de ses
//  propriétés se redessine automatiquement quand elle change.
//

import Foundation
import Observation

@Observable
final class PlayerState {
    /// Le morceau en cours de lecture (nil si rien)
    var current: Track?

    /// True si Apple Music est en train de jouer
    var isPlaying: Bool = false

    /// Position actuelle dans la chanson, en secondes
    var position: Double = 0

    /// Durée totale du morceau, en secondes
    var duration: Double = 0

    /// Volume Apple Music, entre 0 et 1
    var volume: Double = 0.7

    // MARK: — Helpers

    /// Progression entre 0 et 1
    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(1, max(0, position / duration))
    }

    /// Position formatée "1:23"
    var positionLabel: String { Self.format(seconds: position) }

    /// Durée formatée "3:45"
    var durationLabel: String { Self.format(seconds: duration) }

    /// Convertit un nombre de secondes en "M:SS"
    static func format(seconds: Double) -> String {
        let total = Int(seconds.rounded())
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}
