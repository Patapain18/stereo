# Stéréo

> Une app native macOS qui te synchronise avec Apple Music et te montre une cassette qui tourne en temps réel. Côté lecteur c'est Apple Music, côté interface c'est ta stéréo perso vintage.

![macOS](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![Status](https://img.shields.io/badge/Status-v0.1.0--alpha-yellow)

## ☕ L'idée

Apple Music a une super bibliothèque, mais une UI sans âme. Stéréo est un compagnon natif : tu lances un morceau dans Apple Music, et tu vois une cassette tourner avec tes vraies pochettes, ton VU mètre animé, ton walkman doré quand tu veux du plein écran. Tout est synchronisé en temps réel via AppleScript.

> **Pas un player.** Stéréo n'a pas de droits Apple Music — c'est Apple Music qui joue. Stéréo affiche, contrôle, et ajoute une couche d'ambiance.

## ✨ Features (v0.1.0)

- **Synchronisation temps réel** avec Apple Music (titre, artiste, position, état play/pause, 4Hz polling)
- **Bibliothèque** complète (jusqu'à 500 morceaux chargés) en grille étagère ou liste
- **Lecture par clic** : clique une cassette → Apple Music joue ce morceau
- **Pochettes HD** : résolution automatique des artwork via iTunes Search API
- **12 styles de pochettes générées** (stripes, blob, rings, sun, mountain, grid, wave, halftone, dotGrid, arch, leaf, tape) en fallback quand iTunes n'a pas la pochette
- **Recherche** : dans ta bibliothèque locale **OU** dans le catalogue Apple Music public
- **Favoris** persistés en local (UserDefaults)
- **Playlists** Apple Music utilisateur listées dans la sidebar
- **Panneau radio** à droite avec deck card, VU mètre, waveform interactive
- **Now Playing immersif** plein écran avec 3 styles de deck :
  - 🟡 **Walkman** — doré vintage avec scrolling tape et compteur 4 chiffres
  - 🎚 **Hi-Fi** — deck rectangulaire avec indicateurs SPEED / COUNTER / TYPE
  - 📻 **Boombox** — 2 speakers ronds, antenne, poignée
- **Easter egg** : un crayon en bas à droite du Now Playing — clique pour rembobiner 10 sec
- **Particules de poussière** flottantes pour l'ambiance hi-fi vintage
- **Polices custom** : Caveat (script), Kalam (manuscrit), Special Elite (typewriter)

## 🛠 Stack

- **SwiftUI** (macOS 14+)
- **AppleScript bridge** via `NSAppleScript` pour parler à Apple Music
- **DistributedNotificationCenter** pour les events de changement de track
- **iTunes Search API** (publique, sans clé) pour la résolution d'artwork et la recherche catalogue
- **xcodegen** pour générer le projet `.xcodeproj` depuis `project.yml`
- Zero dépendance tierce — pas de Swift Package Manager

## 📦 Installation

> **Pré-requis :** macOS 14 (Sonoma) ou plus récent · Apple Music installé · au moins 1 morceau dans la bibliothèque

1. Télécharge `Stereo.dmg` depuis [Releases](#)
2. Ouvre le `.dmg` et drag `Stereo.app` vers `/Applications`
3. **Premier lancement** : clic-droit sur Stereo.app → **Ouvrir** → confirmer (Gatekeeper bloque les apps non notarisées au double-clic)
4. macOS demande *« Stereo souhaite contrôler l'application Music »* → **Autoriser**
5. Lance un morceau dans Apple Music → la cassette se synchronise

### Si l'autorisation est refusée par erreur

Réglages système → Confidentialité et sécurité → **Automatisation** → coche **Music** sous **Stereo**.

## 🧱 Build depuis les sources

```bash
git clone <ce-repo>
cd Stereo
brew install xcodegen
xcodegen generate
open Stereo.xcodeproj
# puis ⌘R dans Xcode
```

## ⚠️ Limitations connues

- **iTunes Search throttle** : si tu fais trop de recherches catalogue d'affilée, Apple peut renvoyer 403. Le rate limiter local protège mais en cas de blocage, attends 1-2 minutes.
- **Artwork tracks streamés** : les tracks Apple Music streamés (pas téléchargés) n'exposent pas leur artwork via AppleScript. La résolution se fait via iTunes Search par titre+artiste, qui peut échouer pour les morceaux obscurs ou en langue non latine.
- **Mode jour** : le toggle existe mais le mode jour n'a pas été aussi travaillé que le mode nuit. Il y a peut-être des contrastes à ajuster.
- **Pas notarisée** : sans Apple Developer Program ($99/an), Gatekeeper warn au premier lancement (clic-droit → Ouvrir résout).

## 🎯 Roadmap

- [ ] Vue PlaylistDetail (cliquer sur une playlist → ses tracks)
- [ ] ArtistsView + ArtistDetail
- [ ] Cache disque pour les artwork (actuellement mémoire seulement)
- [ ] Persister la position au redémarrage
- [ ] Raccourcis clavier (Espace = play/pause, ←/→ = prev/next)
- [ ] Tonearm SVG pour le boombox
- [ ] Animation `matchedGeometryEffect` entre la grille et le NowPlaying
- [ ] Effet typewriter qui écrit les titres caractère par caractère
- [ ] Mode jour parfait
- [ ] App iOS / Apple Watch (avec Apple Developer Program)

## 📐 Architecture

```
Stereo/
├── Models/              · Track, AppState, PlayerState
├── Services/            · MusicController (AppleScript), MusicWatcher (polling),
│                          MusicLibrary, ITunesSearch, ArtworkLoader, Favorites, LibraryStore
├── Views/
│   ├── Sidebar/         · Navigation + playlists + theme toggle
│   ├── Library/         · LibraryView, ShelfView, TrackListView
│   ├── Search/          · SearchView (local OU catalogue iTunes)
│   ├── Favorites/       · FavoritesView
│   ├── Playlists/       · PlaylistsView
│   ├── Radio/           · RadioPanel (panneau droite)
│   ├── NowPlaying/      · NowPlayingView, DeckView (hi-fi), BoomboxView
│   └── MiniPlayer/      · MiniPlayer (bas de fenêtre)
├── Components/          · CassetteView, CassetteThumb, CoverArt (12 styles),
│                          DustParticles, VUMeter, Waveform
├── Style/               · Theme.swift (couleurs, polices)
└── Resources/Fonts/     · Caveat, Kalam, SpecialElite (Google Fonts)
```

## 📜 Licenses

- **Code** : à toi
- **Caveat & Kalam** : Open Font License (OFL)
- **Special Elite** : Apache License 2.0

## 🙏 Crédits

Idée et code : Mathis Soupizon · Co-développé avec [Claude Code](https://claude.com/claude-code)
Maquettes design : [Claude Design](https://claude.ai/design)
