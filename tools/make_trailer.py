"""Render a short game trailer from actual gameplay captures using FFmpeg."""
from pathlib import Path
import subprocess
import shutil
import os

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "build" / "trailer"
OUT.mkdir(parents=True, exist_ok=True)
for local_name, system_name in (("serif.ttf","georgiab.ttf"),("sans.ttf","bahnschrift.ttf")):
    font = OUT / local_name
    if not font.exists():
        shutil.copyfile(Path(os.environ.get("WINDIR","C:/Windows")) / "Fonts" / system_name, font)
FFMPEG = shutil.which("ffmpeg") or r"C:\ffmpeg\bin\ffmpeg.exe"
W, H, FPS = 1920, 1080, 30
GOLD = "0xe9c88a"
CREAM = "0xfff4dd"
seq = 0

def run(*args):
    subprocess.run([FFMPEG, "-hide_banner", "-loglevel", "error", "-y", *map(str,args)], cwd=ROOT, check=True)

def text(content, y, size=44, color=CREAM, font="sans", x="(w-text_w)/2"):
    global seq
    seq += 1
    p = OUT / f"text-{seq}.txt"
    p.write_text(content, encoding="utf-8")
    return f"drawtext=fontfile=build/trailer/{font}.ttf:textfile=build/trailer/{p.name}:fontsize={size}:fontcolor={color}:x={x}:y={y}:shadowcolor=black@0.8:shadowx=2:shadowy=3"

def header(title):
    return [
        "drawbox=x=0:y=0:w=iw:h=88:color=0x08131b@0.94:t=fill",
        "drawbox=x=62:y=30:w=5:h=29:color="+GOLD+":t=fill",
        text(title,25,33,GOLD,x="88"),
        "drawbox=x=0:y=1022:w=iw:h=58:color=0x08131b@0.94:t=fill",
        text("SLAY THE EXTRÊME DROITE",1040,19,x="62"),
        text("IMAGES DE LA DÉMO  ·  EN DÉVELOPPEMENT",1040,18,"0xb7c2c3",x="w-text_w-62")
    ]

def segment(index, source, start, duration, filters, still=False, zoom=False):
    name=OUT/f"segment-{index:02}.mp4"
    inp=["-loop","1","-framerate",str(FPS),"-i",str(source)] if still else ["-ss",str(start),"-i",str(source)]
    f=[f"scale={W}:{H}:force_original_aspect_ratio=increase",f"crop={W}:{H}","setsar=1",f"fps={FPS}"]
    if zoom:
        f.append(f"zoompan=z='1+on*0.00024':x='iw/2-iw/zoom/2':y='ih/2-ih/zoom/2':d=1:s={W}x{H}:fps={FPS}")
    f+=filters
    run(*inp,"-t",duration,"-vf",",".join(f),"-an","-c:v","libx264","-preset","fast","-crf","20","-pix_fmt","yuv420p","-threads","4",name)
    print(f"Rendered {name.name}: {duration}s",flush=True)
    return name

intro=[
    "drawbox=x=0:y=0:w=iw:h=ih:color=0x06131b@0.58:t=fill",
    text("UN JEU CONÇU PAR KINGRABBIT",195,29,GOLD),
    text("SLAY THE",300,82,CREAM,"serif"),
    text("EXTRÊME DROITE",410,118,CREAM,"serif"),
    "drawbox=x=800:y=575:w=320:h=3:color="+GOLD+":t=fill",
    text("PRENEZ LA PAROLE. JOUEZ VOS CARTES.",625,33,GOLD),
    text("DÉMO JOUABLE  ·  EN DÉVELOPPEMENT",901,24,"0xc0ceca"),
    "fade=t=in:st=0:d=0.35"
]
outro=[
    "drawbox=x=0:y=0:w=iw:h=ih:color=0x06131b@0.76:t=fill",
    text("SLAY THE EXTRÊME DROITE",205,76,CREAM,"serif"),
    text("Un jeu conçu par kingrabbit",320,33,GOLD),
    "drawbox=x=515:y=436:w=890:h=105:color=0xe9c88a:t=fill",
    text("LA DÉMO EST DISPONIBLE",469,43,"0x14202a"),
    text("WINDOWS  ·  TÉLÉCHARGEMENT SUR GITHUB",590,26,CREAM),
    text("github.com/kingrabbit89/slay-the-extreme-droite",648,28,GOLD),
    text("JEU EN DÉVELOPPEMENT",778,25,"0xbdccca"),
    text("MUSIQUE  ·  PLANÈTE BRÛLÉE — PLANÈTE BOUM BOUM",921,25,CREAM),
    "fade=t=out:st=4.0:d=0.5"
]
game=ROOT/"build/SlayTheExtremeDroite-combat-v02.mp4"
clips=[
    segment(0,ROOT/"demo/assets/grand-debat.png",0,2.8,intro,still=True,zoom=True),
    segment(1,game,1.7,3.0,header("PRENEZ LA PAROLE")),
    segment(2,game,4.9,3.0,header("ANTICIPEZ LA RIPOSTE")),
    segment(3,game,13.8,3.2,header("ENCHAÎNEZ VOS ARGUMENTS")),
    segment(4,game,27.0,2.0,header("FAITES TOMBER LES RUMEURS")),
    segment(5,ROOT/"build/trailer/reward.png",0,2.3,header("CONSTRUISEZ VOTRE DECK"),still=True),
    segment(6,ROOT/"build/trailer/boss.avi",1.25,4.2,header("AFFRONTEZ LA MACHINE À PEUR")),
    segment(7,ROOT/"demo/assets/grand-debat.png",0,4.5,outro,still=True,zoom=True),
]
listing=OUT/"concat.txt"
listing.write_text("".join(f"file '{p.name}'\n" for p in clips),encoding="utf-8")
run("-f","concat","-safe","0","-i",listing,"-c","copy",OUT/"picture.mp4")
final=ROOT/"build/SlayTheExtremeDroite-clip-v0.2.mp4"
run("-i",OUT/"picture.mp4","-ss","20","-i",ROOT/"demo/assets/audio/planete-brulee.mp3",
    "-map","0:v:0","-map","1:a:0","-t","25",
    "-c:v","libx264","-preset","fast","-crf","20",
    "-vf","format=yuv420p,setsar=1,setparams=range=limited:color_primaries=bt709:color_trc=bt709:colorspace=bt709",
    "-af","loudnorm=I=-16:TP=-1.5:LRA=9,afade=t=in:st=0:d=0.35,afade=t=out:st=23.5:d=1.5",
    "-c:a","aac","-b:a","192k","-ar","48000","-movflags","+faststart",
    "-metadata","title=Slay the Extrême Droite — Clip de la démo",
    "-metadata","artist=kingrabbit",
    "-metadata","comment=Jeu en développement. Musique : Planète brûlée — Planète Boum Boum.",
    final)
run("-ss","1.8","-i",final,"-frames:v","1",ROOT/"docs/images/clip.jpg")
preview = (
    "[0:v]split=4[a][b][c][d];"
    "[a]trim=start=0.5:end=1.7,setpts=PTS-STARTPTS[a1];"
    "[b]trim=start=3:end=5,setpts=PTS-STARTPTS[b1];"
    "[c]trim=start=17:end=19,setpts=PTS-STARTPTS[c1];"
    "[d]trim=start=21:end=23.4,setpts=PTS-STARTPTS[d1];"
    "[a1][b1][c1][d1]concat=n=4:v=1:a=0,fps=8,scale=540:-1:flags=lanczos,split[p][q];"
    "[p]palettegen=stats_mode=diff[pal];[q][pal]paletteuse=dither=bayer:bayer_scale=3"
)
run("-i",final,"-filter_complex",preview,"-loop","0",ROOT/"docs/images/clip.gif")
print(f"TRAILER_OK: {final.name}",flush=True)
