from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parent.parent
source = root / "build" / "SlayTheExtremeDroite"
archive = root / "build" / "SlayTheExtremeDroite-demo-v0.2-Windows.zip"
guide = """SLAY THE EXTREME DROITE
Un jeu concu par kingrabbit
Demo 0.2 - Windows 10/11, 64 bits

DEMARRAGE
1. Extraire tout le ZIP (clic droit > Extraire tout).
2. Ouvrir le dossier SlayTheExtremeDroite.
3. Double-cliquer sur Jouer.cmd ou SlayTheExtremeDroite.exe.

Conserver SlayTheExtremeDroite.exe, SlayTheExtremeDroite.pck et tribune_godot.dll ensemble.
Aucune installation de Godot, Rust ou Slay the Spire 2 n'est necessaire.
Le jeu fonctionne hors ligne. La musique est incluse.

COMMENT JOUER
- Survoler une carte pour lire son effet.
- Cliquer une Attaque, puis l'adversaire a cibler.
- Les Competences se jouent directement.
- E : terminer le tour. 1 a 9 / 0 : selectionner une carte.
- D : consulter le deck. Echap : annuler / pause.
- F11 : plein ecran. M : couper / retablir le son.
- Dans la pause : volumes musique/bruitages et animations reduites.

CONTENU DU TEST
Une traversee d'environ 10 minutes : combats, choix de cartes,
halte et boss final. Personnage jouable : Mathilde Panot.
Les autres personnages et le jeu complet ne sont pas encore disponibles.

SAUVEGARDE
Le jeu cree son propre dossier saves a cote de l'executable.
La progression est enregistree entre les etapes.
Quitter pendant un combat fait reprendre avant ce combat.
Cette archive ne contient aucune sauvegarde personnelle.

POUR FAIRE UN RETOUR
Indiquer ce qui s'est passe, ce qui etait attendu et comment reproduire
le probleme. Une capture ou une courte video aide beaucoup.
Preciser aussi la version de Windows et, si possible, la carte graphique.
Les retours sur la lisibilite, les animations, le son et la difficulte
sont utiles. Aucun retour n'est envoye automatiquement.

CREDITS
Conception et direction du projet : kingrabbit.
Musique : Planete brulee - Planete Boum Boum.
Clip officiel : https://www.youtube.com/watch?v=Tph7Z_ypxgk
Le groupe : https://linktr.ee/planeteboumboum
Credits complets et informations sur les ressources : dossier docs.
"""
with ZipFile(archive, "w", ZIP_DEFLATED, compresslevel=6) as z:
    for name in ("SlayTheExtremeDroite.exe", "SlayTheExtremeDroite.pck", "tribune_godot.dll"):
        z.write(source / name, "SlayTheExtremeDroite/" + name)
    for p in sorted((source / "docs").rglob("*")):
        if p.is_file() and "images" not in p.relative_to(source).parts:
            z.write(p, "SlayTheExtremeDroite/" + p.relative_to(source).as_posix())
    z.writestr("SlayTheExtremeDroite/Jouer.cmd", '@echo off\r\ncd /d "%~dp0"\r\nstart "" "%~dp0SlayTheExtremeDroite.exe"\r\n')
    z.writestr("SlayTheExtremeDroite/LIRE-MOI.txt", guide.replace("\n", "\r\n").encode("utf-8-sig"))
with ZipFile(archive) as z:
    assert z.testzip() is None
    assert not any("/saves/" in n or ".." in Path(n).parts for n in z.namelist())
    assert len(z.read("SlayTheExtremeDroite/SlayTheExtremeDroite.pck")) == (source / "SlayTheExtremeDroite.pck").stat().st_size
    print(f"Archive verified: {archive.name}, {archive.stat().st_size:,} bytes, {len(z.namelist())} files")
    z.extractall(root / "build" / "package-check-v02")
