# Vérifications de la V0.2

Le 24 octobre, l'export renommé `SlayTheExtremeDroite.exe` passe le même test intégré jusqu'à la victoire. Le clip de présentation dure 25 secondes, en H.264/AAC, 1920 × 1080 à 30 i/s. Les plans de combat sont issus du jeu ; les écrans d'ouverture et de fin sont des titres de montage. Le boss est enregistré depuis la scène réelle avec `demo/tests/capture_boss.gd`, sans utiliser de sauvegarde personnelle.

Vérifications effectuées le 23 octobre 2026 sous Windows x64, Godot 4.5 stable et Rust 1.99.1, sur une GeForce GTX 1660 Ti en OpenGL 3.3.

Mise à jour du 24 octobre : nouvelle interface, animations de combat et musique MP3. Les 19 tests Rust passent toujours. Le test graphique étendu passe dans le projet puis dans l'exécutable Windows exporté : sélection à la souris, attaque et PV, défense et Bloc, tour ennemi, défausse et pioche, agrandissement d'une carte par événement de souris, mode mouvements réduits, chargement/lecture/boucle du MP3, fenêtre des volumes, puis parcours complet jusqu'à la victoire. Code de sortie 0 et marqueur `UI_SMOKE_OK`.

Captures supplémentaires examinées : impact, bouclier, distribution en mouvement, carte au survol et réglages audio. Une partie du premier combat est enregistrée avec le mode Movie Maker de Godot, jusqu'à sa récompense : `build/SlayTheExtremeDroite-combat-v02.mp4`, 31,4 secondes, 1440 × 810 à 30 i/s, avec la musique et les bruitages du jeu. Les séquences ont été inspectées en planches de frames. La copie intégrée de Planète brûlée a le même SHA-256 que le fichier fourni.

## Moteur Rust

`cargo test -p tribune_rules --locked` : **19 tests réussis**.

Les tests couvrent : reproductibilité de la pioche, combo d'obstruction (24 dégâts / 11 Bloc / 3 énergies), refus atomique des actions invalides, Faiblesse et expiration, absorption et remise à zéro du Bloc, Écologie limitée à un déclenchement, plafond de Motion, quatrième carte, limite de main/remélange, sélection de Votation, Foulard et Statut, Brouhaha éthéré, récompense et halte à usage unique, sauvegarde/rejet de corruption, défaite, pouvoirs uniques et amélioration, absence de déclenchement rétroactif de Présidente, exécution de toutes les cartes et parcours complets des deux routes.

`cargo run -p tribune_rules --bin balance --release --locked` : **200 traversées**, graines 1 à 100 sur chaque route. Résultat du bot de contrôle : 82 victoires sur le parcours simple, 88 sur le parcours avec duo/relique ; PV moyens des gagnants 25,1 et 23,4. Le bot explore deux actions à l'avance et privilégie certaines récompenses : ces chiffres ne représentent pas le taux de victoire de joueurs humains ni une validation finale de l'équilibrage.

## Intégration et rendu Godot

Un test `--smoke` lance la vraie scène avec la DLL Rust, injecte un clic de souris sur une carte, vérifie le ciblage, résout une attaque avec ses animations, puis rejoue un parcours de **106 commandes jusqu'à la victoire**. Il vérifie aussi l'écriture/lecture du checkpoint et la conservation de la sauvegarde lors d'un changement de réglages au titre.

Écrans capturés et inspectés : titre, carte de progression, combat, aide, récompenses, halte, boss, victoire. Les vérifications visuelles ont corrigé la taille des TextureRect et le retour à la ligne des textes des cartes. Les captures du projet sont dans `build/qa`, celles de l'export dans `build/qa-export`.

Le parcours du test termine avec 36 PV, 76 cartes jouées et 199 dégâts infligés. Les captures du test utilisent une graine fixe ; une nouvelle partie normale utilise une autre graine.

L'export Windows est lancé séparément avec son `.pck` et sa DLL native, puis rejoue le même test. Les messages de contrôle attendus sont `UI_SMOKE_OK` et un code de sortie nul. Dans l'environnement d'exécution restreint, Godot peut signaler l'accès refusé au cache de shaders ou au magasin de certificats Windows : ces messages ne concernent pas la logique du jeu, qui fonctionne hors ligne. La compilation/l'exécution ne dépendent d'aucun binaire de Slay the Spire 2.

## Limites des vérifications

Le moteur et le parcours intégré sont automatisés ; il reste à effectuer une vraie séance de jeu humaine pour le ressenti, le volume sonore, les choix de récompenses et la difficulté. Les captures fixes ne valident pas à elles seules la qualité de l'animation ou du mixage. Les exports Linux/macOS, la manette et les petits écrans n'ont pas été validés. Le jeu utilise un canevas 1600 × 900, mis à l'échelle de la fenêtre.
