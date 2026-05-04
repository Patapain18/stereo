# Politique de sécurité

## Versions supportées

Stéréo est encore en alpha (v0.1.x). Seule la dernière release reçoit des correctifs.

| Version | Supportée |
|---------|-----------|
| 0.1.x   | ✅ |
| < 0.1   | ❌ |

## Ce que Stéréo fait avec tes données

- **Aucune donnée n'est envoyée à un serveur tiers**, sauf les requêtes vers `itunes.apple.com/search` (API publique d'Apple) qui contiennent uniquement le titre + artiste d'un morceau pour récupérer son artwork.
- **Aucune télémétrie**, aucun tracking, aucune analytics.
- **Favoris** stockés localement dans `UserDefaults` (donc dans le compte utilisateur macOS, pas accessibles à d'autres apps).
- **Pas de credentials** Apple Music demandés — Stéréo passe par AppleScript pour parler à l'app Music déjà connectée à ton compte.
- **Aucune écriture** dans `~/Documents` ou autre, à part la sauvegarde optionnelle d'une pochette de test (`stereo-test-cover.png` sur le bureau, uniquement si tu lances le script de test du POC).

## Permissions macOS demandées

- **Apple Events → Music** : permet de lire ce qui joue et contrôler la lecture. Demandé au premier lancement, peut être révoqué dans Réglages système → Confidentialité et sécurité → Automatisation.
- **Réseau** : pour iTunes Search API (artwork + recherche catalogue) et téléchargement des images depuis les CDN Apple.

Aucune autre permission n'est demandée (pas d'accès aux fichiers, à la caméra, au micro, à la localisation, etc.).

## Signaler une vulnérabilité

Si tu trouves une vulnérabilité (fuite de données, escalade de privilèges, etc.) :

1. **Ne pas l'ouvrir en issue publique** sur GitHub
2. Contacte directement le mainteneur via le formulaire de [GitHub Security Advisories](https://github.com/Patapain18/stereo/security/advisories/new) — c'est privé tant que ce n'est pas publié

Tu peux aussi me ping en DM sur GitHub (`@Patapain18`).

## Garanties

Aucune. C'est un side project en alpha distribué sous licence MIT. Voir `LICENSE`. Si tu installes Stéréo, tu acceptes que ça puisse planter / mal interagir avec Apple Music / consommer des cycles CPU pour faire des choses étranges.

Que des bonnes intentions, mais aucune garantie professionnelle.
