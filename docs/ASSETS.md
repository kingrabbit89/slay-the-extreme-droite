# Ressources et direction artistique

## Ressources fournies

- `demo/assets/grand-debat.png` est une copie de `Recherches visuelles/da90e89c-aa1c-48ec-a5e7-6547c6df17a8.png`.
- `cards-a.png` provient de `dcb167c6-9f34-4ba9-bb09-20b5bbcc18f0.png` ; `cards-b.png` de `29971677-fc47-4d80-b81d-e41e5158418d.png`.
- Les illustrations sont lues par régions AtlasTexture ; tous les noms, coûts et effets utilisés par le jeu sont du vrai texte, calculé à partir du catalogue Rust.
- La planche Mathilde `dacefef0-72cf-4854-9ec2-a431cfbe696e.png` a servi de référence visuelle. Le ZIP Bally, les autres planches et les captures conceptuelles sont conservés dans leur dossier d'origine.

## Planche de personnages

Fichier intégré : `demo/assets/actors.png`. Généré avec l'outil intégré **imagegen**, en utilisant la compétence imagegen, le 23 octobre 2026. L'image RGBA contient une transparence réelle, vérifiée. Elle comprend trois poses de Mathilde et trois adversaires fictifs (colporteur, éditorialiste, automate). Le jeu anime ces poses par interpolations et effets ; ce n'est pas encore une animation squelettique.

Prompt final utilisé :

> Create a production-ready game sprite atlas with REAL TRANSPARENT background, landscape 1536x1024. Reference image shows Mathilde Panot character design for a French satirical political deckbuilder. Preserve her recognizable face, curvy sturdy build, blonde ponytail, emerald green dress and dark navy jacket. Painterly dark fantasy 2D game aesthetic with strong ink-like silhouette, rich shading, warm rim lighting. Exactly six isolated full-body sprites, in a STRICT uniform grid of 3 columns x 2 rows. Each sprite centered in its cell, completely separated with generous transparent margins, feet at same relative baseline. Top row: Mathilde Panot facing RIGHT, 1 neutral ready stance holding papers, 2 pointing forward assertively with flying papers, 3 defending with papers held protectively. Bottom row: three FICTIONAL opponents facing LEFT, 1 a scrawny masked newspaper hawker wearing a charcoal coat and carrying newspapers, 2 an arrogant masked television pundit in burgundy suit holding a microphone, 3 a towering sinister brass television automaton on two mechanical legs, screen glowing red like an eye, ornate gothic loudspeakers on its shoulders. These are metaphorical fictional debate opponents. All 6 characters same painterly art style, full body, no background scenery, NO TEXT, no labels, no grid lines, no shadows extending beyond each cell. This is a sprite asset sheet, not a UI mockup. Do not crop heads or feet.

## Son et effets

La V0.2 utilise `demo/assets/audio/planete-brulee.mp3`, copie du fichier fourni `Musiques/Planète Boum Boum Planète Brûlée CLIP OFFICIEL.mp3`. Lecture en boucle, musique et effets réglables séparément. Le fichier musical fourni n'a pas été réencodé. La boucle synthétique précédente reste dans les sources mais n'est plus jouée.

`crates/rules/src/bin/soundscape.rs` génère une boucle musicale de 32 secondes et huit bruitages : clic, papier, attaque, bloc, impact, victoire, défaite, pouvoir. Synthèse originale par oscillateurs, enveloppes et bruit déterministe. Aucun échantillon ou musique de Slay the Spire 2 n'est utilisé.

Les mouvements de papier, poussières, faisceaux, flashes, nombres flottants et réactions utilisent les nœuds et tweens Godot. Le style conserve le décor nocturne, les rouges/verts de la recherche visuelle et des panneaux sombres bordés d'or. Les polices demandées sont des polices système (Georgia / Bahnschrift / Segoe UI) avec le repli Godot ; aucune police Windows n'est redistribuée.

La vidéo `2026-10-23 23-43-18.mkv` (46,517 secondes, 1080p / 60 i/s) sert uniquement de référence d'observation. Des planches de lecture à 5 i/s ont permis d'examiner les transitions de tour et les attaques : montée d'une carte, anticipation, impact, recul et trajet vers la défausse. Aucun sprite, son ou extrait de cette vidéo n'est intégré dans le jeu.

`crates/rules/src/bin/interface_assets.rs` génère les cadres de cartes, la gemme d'énergie, le bouton de tour et les icônes SVG. `demo/ui/combat_fx.gd` produit les trajectoires courbes, traînées, particules, entailles et boucliers ; `actor.gdshader` anime légèrement le haut des silhouettes en gardant les pieds ancrés. Ces ressources sont originales.
