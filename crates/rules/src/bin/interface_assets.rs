//! Original vector interface skin, authored as deterministic SVG assets.
use std::{fs, path::Path};
fn write(dir: &Path, name: &str, w: i32, h: i32, body: &str) {
    fs::write(dir.join(format!("{name}.svg")),format!(r##"<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{body}</svg>"##)).unwrap();
}
fn main() {
    let dir = Path::new("demo/assets/ui");
    fs::create_dir_all(dir).unwrap();
    for (name, light, mid, dark) in [
        ("attack", "#e99876", "#a63e35", "#431f25"),
        ("skill", "#a4dae6", "#387fa1", "#17334a"),
        ("power", "#d3b5f2", "#7951a0", "#30213e"),
        ("rare", "#f3d48a", "#a5813e", "#3d3228"),
        ("status", "#b8b8b7", "#696969", "#292d31"),
    ] {
        let svg = format!(
            r##"<defs>
<linearGradient id="metal" x1="0" y1="0" x2="1" y2="1"><stop stop-color="{light}"/><stop offset=".26" stop-color="{mid}"/><stop offset=".55" stop-color="{dark}"/><stop offset=".8" stop-color="{mid}"/><stop offset="1" stop-color="{light}"/></linearGradient>
<linearGradient id="body" x2="0" y2="1"><stop stop-color="{dark}"/><stop offset="1" stop-color="#161f26"/></linearGradient>
<linearGradient id="silver" x2="0" y2="1"><stop stop-color="#b8b8ad"/><stop offset=".35" stop-color="#6b777c"/><stop offset=".55" stop-color="#414d55"/><stop offset="1" stop-color="#8c9695"/></linearGradient>
<radialGradient id="gem" cx=".38" cy=".3" r=".7"><stop stop-color="#ffe2a0"/><stop offset=".4" stop-color="#d77a35"/><stop offset="1" stop-color="#702c27"/></radialGradient></defs>
<path d="M14 6 L184 6 L195 21 L195 278 L184 295 L15 295 L5 279 L5 22 Z M17 45 L183 45 L183 151 L17 151 Z" fill-rule="evenodd" fill="url(#body)" stroke="#10171c" stroke-width="6"/>
<path d="M14 6 L184 6 L195 21 L195 278 L184 295 L15 295 L5 279 L5 22 Z" fill="none" stroke="url(#metal)" stroke-width="7"/>
<path d="M18 13 L180 13 L188 25 L188 276 L180 287 L20 287 L12 277 L12 25 Z" fill="none" stroke="{light}" stroke-width="1.1" opacity=".65"/>
<path d="M16 44 L184 44 L184 143 Q100 168 16 143 Z" fill="none" stroke="url(#metal)" stroke-width="5"/>
<path d="M7 29 L18 16 Q94 9 189 20 L197 39 L186 52 L181 38 Q98 34 21 44 L4 55 Z" fill="url(#silver)" stroke="#303942" stroke-width="1.5"/>
<path d="M21 18 Q100 11 187 22" fill="none" stroke="#e9e0c9" stroke-width="1.5" opacity=".8"/>
<path d="M64 153 L137 153 L145 169 L57 169 Z" fill="url(#silver)" stroke="#b2b8b2" stroke-width="1"/>
<path d="M10 271 L20 284 L65 284 M190 271 L179 284 L139 284" fill="none" stroke="{light}" stroke-width="2" opacity=".6"/>
<path d="M100 279 L107 286 L100 293 L93 286 Z" fill="{mid}" stroke="{light}"/>
<path d="M23 0 C43 13 48 25 40 39 C32 51 9 49 3 34 C-1 23 12 7 23 0Z" fill="#612729" stroke="#27282b" stroke-width="2"/>
<ellipse cx="23" cy="26" rx="16" ry="20" fill="url(#gem)" stroke="#f1ca71" stroke-width="2"/>
<path d="M14 17 Q17 9 25 9" fill="none" stroke="#fff5cb" stroke-width="2" opacity=".8"/>"##
        );
        write(dir, &format!("card-{name}"), 200, 300, &svg);
    }
    write(dir,"energy",160,160,r##"<defs><radialGradient id="b" cx=".36" cy=".3" r=".65"><stop stop-color="#62e3f3"/><stop offset=".4" stop-color="#147fb2"/><stop offset="1" stop-color="#092c5d"/></radialGradient><linearGradient id="s" x2="1" y2="1"><stop stop-color="#e9dba5"/><stop offset=".3" stop-color="#8b9598"/><stop offset=".6" stop-color="#404e5c"/><stop offset="1" stop-color="#cdc8a0"/></linearGradient></defs><path d="M80 5 L129 25 L154 80 L133 130 L80 156 L27 132 L6 80 L27 26Z" fill="#101d2a" stroke="#111923" stroke-width="6"/><path d="M80 8 L128 28 L149 80 L128 127 L80 150 L32 129 L11 80 L31 30Z" fill="url(#s)" stroke="#c0baa0" stroke-width="2"/><path d="M80 20 L119 38 L138 80 L119 119 L80 138 L41 119 L23 80 L41 40Z" fill="url(#b)" stroke="#65abbd" stroke-width="3"/><path d="M80 30 L111 44 L128 80 L111 111 L80 128 L49 112 L33 80 L50 49Z" fill="none" stroke="#82deee" stroke-width="1" opacity=".5"/><path d="M37 65 L46 44 L73 31" fill="none" stroke="#d9f8fa" stroke-width="4" opacity=".6"/></svg>"##.trim_end_matches("</svg>"));
    write(dir,"end-turn",250,90,r##"<defs><linearGradient id="s" x2="0" y2="1"><stop stop-color="#e0d8b7"/><stop offset=".2" stop-color="#92978e"/><stop offset=".6" stop-color="#45545b"/><stop offset="1" stop-color="#afa888"/></linearGradient><linearGradient id="b" x2="0" y2="1"><stop stop-color="#46606a"/><stop offset="1" stop-color="#182d3a"/></linearGradient></defs><path d="M25 5 L224 5 L247 45 L224 85 L25 85 L3 45Z" fill="#0a1117" stroke="#091017" stroke-width="5"/><path d="M25 5 L224 5 L247 45 L224 85 L25 85 L3 45Z" fill="url(#s)" stroke="#e2d8ae" stroke-width="1.5"/><path d="M31 14 L218 14 L236 45 L218 76 L31 76 L14 45Z" fill="url(#b)" stroke="#202d35" stroke-width="3"/><path d="M35 20 L214 20 L228 45 L214 69 L35 69 L22 45Z" fill="none" stroke="#889c9d" stroke-width="1"/></svg>"##.trim_end_matches("</svg>"));
    let icons=[
        ("heart",r##"<path d="M32 55 C18 45 2 33 6 18 C10 3 26 7 32 18 C38 7 55 3 59 18 C64 33 45 47 32 55Z" fill="#c73532" stroke="#542122" stroke-width="3"/><path d="M12 23 Q12 12 23 15" fill="none" stroke="#ff9880" stroke-width="4" stroke-linecap="round"/>"##),
        ("coin",r##"<circle cx="32" cy="32" r="26" fill="#ae7024" stroke="#352e26" stroke-width="3"/><circle cx="32" cy="32" r="21" fill="#e7b744" stroke="#ffe79b" stroke-width="2"/><path d="M41 21 C20 12 13 40 32 46 Q41 45 44 38 M17 29 L36 29 M17 35 L34 35" fill="none" stroke="#8f5b20" stroke-width="4"/>"##),
        ("sword",r##"<path d="M50 4 L59 5 L57 16 L29 43 L21 35Z" fill="#f2e5bc" stroke="#4b3830" stroke-width="3"/><path d="M54 8 L25 39" stroke="#b3c4c8" stroke-width="3"/><path d="M14 30 L34 50 M23 41 L8 56" stroke="#3b2925" stroke-width="10"/><path d="M14 30 L34 50 M23 41 L8 56" stroke="#d9573e" stroke-width="6"/>"##),
        ("shield",r##"<path d="M32 3 L57 14 L53 39 Q47 53 32 62 Q17 53 11 39 L7 14Z" fill="#a7d9e7" stroke="#183a50" stroke-width="3"/><path d="M32 9 L50 18 L47 38 Q41 49 32 55 Q22 49 17 38 L14 18Z" fill="#3a9bc3"/><path d="M32 12 L32 52 L18 36 L16 20Z" fill="#64cde7"/></svg>"##.trim_end_matches("</svg>")),
        ("relic",r##"<path d="M12 54 L52 54 L48 46 L16 46Z" fill="#bc9450" stroke="#44392d" stroke-width="3"/><path d="M21 46 L21 24 L43 24 L43 46Z" fill="#906a39" stroke="#d7b979" stroke-width="3"/><path d="M13 15 L48 10 L55 23 L19 30Z" fill="#e8d4a3" stroke="#594736" stroke-width="3"/><path d="M24 19 L44 17 M28 24 L46 21" stroke="#8c6a47" stroke-width="2"/>"##),
        ("map",r##"<path d="M9 6 L53 10 L56 55 L11 59 L15 39 L6 24Z" fill="#d9c7a0" stroke="#5e5441" stroke-width="3"/><path d="M22 49 Q44 37 26 30 Q13 21 41 16" fill="none" stroke="#a74b36" stroke-width="3" stroke-dasharray="5 4"/><path d="M36 11 L47 21 M46 10 L36 21" stroke="#a33c2f" stroke-width="4"/>"##),
        ("gear",r##"<path d="M26 4 L38 4 L40 13 L48 16 L55 12 L62 24 L55 30 L55 37 L61 44 L53 55 L44 51 L38 55 L35 63 L23 60 L23 51 L16 47 L7 49 L2 37 L10 32 L12 23 L6 17 L15 8 L23 13Z" fill="#8fa8a8" stroke="#2c414a" stroke-width="3"/><circle cx="32" cy="33" r="14" fill="#2b4552" stroke="#c2d4ca" stroke-width="3"/>"##),
        ("sound",r##"<path d="M6 25 L19 25 L35 10 L35 55 L19 41 L6 41Z" fill="#c9ba8e" stroke="#484134" stroke-width="3"/><path d="M43 21 Q57 32 43 45 M49 12 Q70 32 49 54" fill="none" stroke="#d6c99c" stroke-width="4" stroke-linecap="round"/>"##),
        ("weak",r##"<path d="M49 8 L18 18 L31 31 L14 46 L28 56 L46 35 L35 23 L57 16Z" fill="#bb8bcb" stroke="#3d2949" stroke-width="3"/>"##),
        ("vulnerable",r##"<path d="M32 5 L55 15 L48 43 L32 59 L13 43 L8 15Z" fill="#e6805b" stroke="#562c2c" stroke-width="3"/><path d="M34 6 L24 26 L39 32 L26 58" fill="none" stroke="#5b2528" stroke-width="5"/>"##),
        ("power",r##"<path d="M32 2 L40 23 L62 32 L41 41 L32 63 L23 41 L2 32 L23 23Z" fill="#d6b4ee" stroke="#513268" stroke-width="3"/><path d="M32 15 L37 28 L49 32 L36 37 L32 49 L27 36 L15 32 L28 27Z" fill="#f5dfbc"/>"##),
        ("fire",r##"<path d="M33 2 C41 23 54 20 52 40 C50 62 12 62 10 40 Q8 29 21 15 L23 31 Q38 22 33 2Z" fill="#c67a40" stroke="#532d26" stroke-width="3"/><path d="M31 29 Q51 52 31 57 Q16 52 31 29Z" fill="#ffe6a0"/>"##),
    ];
    for (name, body) in icons {
        write(dir, name, 64, 64, body);
    }
    for (name, c1, c2) in [
        ("draw-pile", "#e7d6a1", "#a44532"),
        ("discard-pile", "#85c4d7", "#2e6391"),
        ("deck", "#dccda6", "#85683f"),
    ] {
        write(
            dir,
            name,
            100,
            120,
            &format!(
                r##"<path d="M23 12 L80 17 L92 102 L34 113 L10 32Z" fill="#121e25" stroke="#131a20" stroke-width="5"/><path d="M16 23 L71 13 L87 98 L32 109Z" fill="{c1}" stroke="#765b3d" stroke-width="2"/><path d="M23 19 L78 9 L94 94 L39 105Z" fill="{c1}" stroke="#f6e8c4" stroke-width="2"/><path d="M32 25 L71 18 L84 87 L45 94Z" fill="{c2}"/><path d="M51 36 Q79 48 59 62 Q42 53 50 46 Q65 40 68 52 Q82 79 56 81" fill="none" stroke="{c1}" stroke-width="6"/><path d="M29 22 L33 31 M75 88 L80 96" stroke="{c2}" stroke-width="2"/>"##
            ),
        );
    }
    println!(
        "Original interface SVG assets generated in {}",
        dir.display()
    );
}
