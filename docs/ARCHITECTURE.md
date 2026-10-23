# Architecture de la démo

## Ce que les fichiers de référence permettent de constater

Le répertoire fourni est une distribution Windows compilée, pas un dépôt source. `release_info.json` indique **v0.107.1**, commit **59260271**, daté du 18 juin 2026. Le répertoire contient un exécutable, un PCK de 1,9 Go, `sts2.dll` et sa documentation XML.

Les bibliothèques et métadonnées établissent la présence de Godot (`GodotSharp.dll`), de C#/.NET 9 (`sts2.runtimeconfig.json`, runtime 9.0.7), de Spine (`libspine_godot…dll`) et de FMOD (`fmod.dll`, `fmodstudio.dll`, `libGodotFmod…dll`). Cette inspection n'établit pas à elle seule le détail interne de toutes les règles ou la version exacte de l'éditeur Godot d'origine.

La documentation `sts2.xml` expose notamment :

- `Core.Combat.CombatState` : état de combat, rattaché à l'état de partie, créatures et piles de cartes (vers la ligne 1872).
- `Core.Combat.History.CombatHistory` : historique d'événements (vers la ligne 2100).
- `Core.Commands.Builders.AttackCommand` : commande d'attaque et contexte associés (vers la ligne 2425).
- `Core.Models.CardModel` et `Core.Entities.Cards.CardEnergyCost` : modèles de cartes et coûts modifiables (référencés notamment vers la ligne 5804).
- Les méthodes de création et de sérialisation du joueur référencent explicitement les modèles, inventaires et états de partie (vers la ligne 7062).
- `Core.Audio.FmodSfx` : couche de sons (vers la ligne 948).

Cela justifie une séparation entre **état**, **définitions**, **commandes**, **événements** et **présentation**. Ce sont les responsabilités reprises dans cette démo. Le code, les textures et les banques sonores de la distribution commerciale ne sont pas chargés par notre jeu. Aucune DLL du dossier de référence n'est embarquée.

## Transposition Godot + Rust

```text
Entrées souris / clavier
        ↓
Godot : main.gd / card_view.gd
        ↓ commandes validées
GDExtension : TribuneCore (crates/godot_bridge)
        ↓
Rust pur : Game, Card, Enemy, Intent, Power
        ↓ état + événements
Godot : cartes, sprites, tweens, particules, audio
```

`crates/rules/src/cards.rs` contient le catalogue immuable et les descriptions dérivées des valeurs normales/améliorées. `lib.rs` gère la progression et les commandes : `enter`, `play`, `choose`, `end_turn`, `reward`, `rest`. Le moteur vérifie coût, cible, phase et choix en cours avant de modifier l'état. Chaque instance de carte reçoit un identifiant propre.

Le cœur ne dépend ni de Godot, ni de l'horloge, ni du système de fichiers. Un générateur pseudo-aléatoire à état explicite rend les mélanges et récompenses reproductibles. Le bot de vérification clone l'état et explore des actions possibles ; il n'intervient jamais dans une partie humaine.

`crates/godot_bridge` traduit les états en dictionnaires et tableaux Godot. La DLL utilise **godot-rust 0.5.5**, API **4.5**, via GDExtension. Le nombre de cartes traité est faible : l'intérêt de Rust est surtout la fiabilité du domaine, les tests rapides, la reproductibilité et la base extensible.

La présentation reste en GDScript, adapté à la composition des contrôles, aux tweens et au travail avec l'éditeur. Les règles ne sont pas dupliquées dans l'interface. `soundscape.rs` génère de façon reproductible la musique et les effets WAV avec un petit synthétiseur Rust.

La V0.2 ajoute un générateur Rust de ressources SVG (`interface_assets.rs`). Godot orchestre les événements de combat dans leur ordre, anime les cartes par identifiant d'instance, conserve les effets transitoires entre deux rendus de main et bloque les commandes pendant la résolution. Les barres affichent les impacts successifs avant de rejoindre l'état final Rust. Les aléas des particules sont indépendants du générateur déterministe de la partie. `combat_fx.gd` dessine les effets ; `actor.gdshader` traite les mouvements secondaires sur le GPU. La musique MP3 fournie remplace la boucle synthétique en lecture.

Documentation officielle utilisée pour la liaison : [godot-rust](https://godot-rust.github.io/book/intro/hello-world), [API et versions](https://docs.rs/godot/0.5.5/godot/). Moteur portable : [Godot 4.5 stable](https://godotengine.org/download/archive/4.5-stable/).

## Ordre de résolution

1. Valider l'action sans mutation en cas d'erreur.
2. Dépenser l'énergie et retirer la carte de la main.
3. Résoudre son effet, avec choix explicite si nécessaire.
4. Mettre à jour les compteurs, déclencher relique/pouvoirs et déplacer la carte.
5. Vérifier la victoire ; l'interface consomme les événements pour animer le résultat.
6. Fin du tour : défausse, Brouhaha éthéré, intentions ennemies dans l'ordre, fin des altérations ennemies, nouveau tour.

Le Bloc du joueur est remis à zéro au début de son tour. Le Bloc d'un ennemi est remis à zéro au début de son action. Faiblesse réduit les dégâts de 25 %, Vulnérable augmente les dégâts reçus de 50 %, arrondis par impact. L'énergie revient à 3 ; la main est limitée à 10. Un Amendement non joué est défaussé ; un Amendement joué est épuisé. Les cartes temporaires ne rejoignent jamais le deck permanent.

## Sauvegarde et extension future

Les checkpoints versionnés `TRIBUNE1` stockent graine, RNG courant, étage, PV, pièces, relique, statistiques et deck amélioré. Ils sont validés avant chargement. Seuls les états entre rencontres sont persistés ; reprendre un combat le recommence depuis l'entrée. Les réglages son/mouvements sont séparés du code de partie dans le même ConfigFile.

Pour le jeu complet, les prochains travaux structurants sont : extraire des types de partie/combat séparés à mesure que le domaine grossit ; données de rencontres et de récompenses configurables ; gestion formelle des abonnements de pouvoirs ; versionnage de sauvegarde avec migration ; localisation ; système d'animations articulées ; événements, boutique et autres personnages. La V0.1 reste volontairement un seul crate de règles cohérent plutôt qu'une multiplication prématurée de services.
