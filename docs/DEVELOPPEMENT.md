# Slay the Extrême Droite — La Tribune

Démo autonome Windows, version 0.2. Godot 4.5 pour la présentation, Rust pour toutes les règles de jeu. Aucune installation de Slay the Spire 2 n'est nécessaire.

## Jouer

Double-cliquer sur **Jouer.cmd** à la racine du projet, ou sur **build/LaTribune/LaTribune.exe**. Conserver l'exécutable, le fichier `.pck` et la DLL dans le même dossier. Aucun compte, serveur ou accès Internet nécessaire.

- Cliquer sur une carte Attaque, puis sur l'adversaire.
- Les Compétences se jouent directement ; les effets demandant un choix ouvrent une sélection.
- **E** termine le tour ; **1–9 / 0** sélectionnent les cartes ; **D** ouvre le deck.
- **Échap** annule le ciblage ou ouvre la pause ; **F11** bascule le plein écran ; **M** coupe le son.
- Les piles, les règles et le journal sont consultables. Une option réduit les mouvements.
- Survoler les cartes de la main en éventail pour les agrandir et lire leur effet. La pause propose deux volumes indépendants : musique et bruitages.

La sauvegarde est automatique entre les étapes, dans le dossier `saves` de l'exécutable. Quitter pendant un combat permet de reprendre avant ce combat. Une victoire ou une défaite termine la sauvegarde de la traversée. En développement, le dossier `saves` se trouve à la racine du projet.

## Contenu

Une traversée d'environ 10 minutes avec Mathilde Panot : premier débat, choix entre un adversaire et un duo donnant une relique, permanence (soin ou amélioration), puis Machine à peur. Départ à 70 PV, 3 énergies par tour, 5 cartes piochées, 10 cartes de départ et relique Le perchoir.

Les **20 cartes du document fourni** sont implémentées, avec leurs améliorations, plus les deux cartes de base, les Amendements et le Brouhaha. Elles sont consultables depuis le titre ; deux récompenses par traversée permettent d'en ajouter au deck. Le premier choix propose volontairement Cascade / Interpellation / Motion pour faire découvrir les mécaniques. Les autres récompenses varient selon la graine.

Le jeu comprend la pioche et le remélange, la défausse, l'épuisement, les pouvoirs, les choix de cartes, les multi-impacts, Faiblesse, Vulnérable, les intentions et les bruitages. La musique **Planète brûlée — Planète Boum Boum**, fournie dans le dossier Musiques, est intégrée en boucle.

La V0.2 reprend le déroulement observé dans la vidéo de combat fournie : main en éventail, agrandissement au survol, carte jouée au centre, voyages arqués vers les piles avec traînées lumineuses, préparation des coups et recul, flashes et entailles, boucliers, dégâts flottants, disparition des ennemis, annonces de tour et distribution successive. Les cadres, gemmes et icônes de l'interface sont des SVG originaux générés par Rust ; les effets et mouvements sont rendus par Godot.

## Périmètre de cette version

C'est une première tranche jouable, pas encore le jeu complet. Bally et David ne sont pas jouables ; leurs ressources d'origine sont conservées. Il n'y a pas encore de boutique, d'événements narratifs, de plusieurs actes, de multijoueur ni de progression permanente. Les pièces sont un score de parcours dans cette version. Les personnages utilisent des poses, des interpolations et une déformation légère au shader ; ils ne disposent pas encore de squelettes articulés comme ceux de Slay the Spire 2. Les bruitages restent synthétisés.

Les pouvoirs identiques ne se cumulent pas : une copie améliorée remplace l'effet de base. Cette convention de prototype, explicitée dans les règles, limite les interactions non équilibrées. Les intentions et valeurs sont originales ; l'architecture s'inspire des responsabilités observables dans les fichiers fournis de Slay the Spire 2, sans reproduire son implémentation C#.

## Développer

Ouvrir `demo/project.godot` avec Godot 4.5. Le moteur Rust s'intègre par une véritable GDExtension, sans processus externe ni pont réseau. Les sources sont dans `crates/rules` et `crates/godot_bridge`.

```powershell
cargo test -p tribune_rules --locked
cargo run -p tribune_rules --bin balance --release --locked
pwsh -File tools/build.ps1 -Test -Export
```

Godot portable et le modèle Windows sont présents sous `tools` dans ce workspace. Le script de compilation attend Rust MSVC et les outils de compilation Windows. `Cargo.lock` fixe les dépendances ; le cœur de règles n'a aucune dépendance externe.

Voir `docs/ARCHITECTURE.md`, `docs/VALIDATION.md` et `docs/ASSETS.md` pour les décisions, vérifications et sources des ressources.
