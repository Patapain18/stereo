## Qu'est-ce qui change

<!-- 1-2 phrases : qu'est-ce que cette PR ajoute / fixe / refactore -->

## Pourquoi

<!-- Lien vers l'issue résolue (`closes #X`) ou contexte si c'est self-contained -->

## Capture (si UI)

<!-- Drag-drop avant/après si la PR touche au visuel -->

## Test plan

- [ ] La build passe en local (`xcodebuild ... build`)
- [ ] L'app se lance et se synchronise avec Apple Music
- [ ] Pas de régression sur les sprints précédents (cassette tourne, bibliothèque charge, click joue un morceau, NowPlaying ouvre)
- [ ] Si nouvelle vue, testée avec `current=nil` (rien ne joue) ET avec un track
- [ ] Si touche AppleScript, testée avec un track local ET un track streamé Apple Music

## Notes pour le reviewer

<!-- Anything specific you want me to check, decisions tradeoffs you made -->
