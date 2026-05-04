# Contribuer à Stéréo

Merci de t'intéresser ! Stéréo est un side project perso, mais les contributions sont bienvenues.

## Avant de coder

1. **Ouvre une issue** d'abord pour discuter de ton idée — évite de coder pendant 3 heures un truc qui sera refusé.
2. Vérifie qu'il n'y a pas déjà une issue / PR similaire.

## Setup local

```bash
git clone https://github.com/Patapain18/stereo.git
cd stereo
brew install xcodegen
xcodegen generate
open Stereo.xcodeproj
```

Pré-requis : macOS 14+ · Xcode 15.4+ · Apple Music installé · au moins 1 morceau dans la bibliothèque pour tester.

## Style de code

- **Swift 5** standard, pas de force-unwrap (`!`) sauf cas exceptionnels documentés
- **Préférer `@Observable`** plutôt que `ObservableObject` (on cible macOS 14+)
- **TimelineView** plutôt que Timer pour les animations cycliques
- **Pas de dépendance tierce** (volontairement zero deps pour l'instant)
- Commits courts, en français ou anglais c'est égal

## Quoi contribuer ?

Le backlog est dans le README. Petits trucs sympa pour démarrer :

- 🎯 PlaylistDetail (cliquer sur une playlist dans la sidebar → ses tracks)
- ⌨️ Raccourcis clavier (Espace = play/pause, ←/→ = prev/next)
- 💾 Cache disque pour les artworks (actuellement mémoire only, perdu au relaunch)
- 🌞 Finir le mode jour (toggle existe mais peu testé visuellement)
- 🎨 Animation `matchedGeometryEffect` entre la grille et le NowPlaying

## Tester

Pas de test automatisé pour l'instant (tu peux en ajouter, c'est welcome). Test manuel :

1. Lance Apple Music avec un morceau
2. Cmd+R dans Xcode
3. Vérifie que la cassette se synchronise
4. Test : pause/play, next/prev, seek, click cassette, ouverture NowPlaying, toggle styles deck

## PRs

- 1 feature / fix par PR (évite les "mega PRs" qui mélangent plusieurs trucs)
- Description : qu'est-ce qui change, pourquoi, screenshot si UI
- Si ça impacte la sync Apple Music, mentionne-le explicitement (zone fragile)

Merci ! 🎵
