//! Reproducible original ambience/SFX. No samples from another game.
use std::{f32::consts::TAU, fs, path::Path};
fn wave(path: &Path, data: &[f32], rate: u32) {
    let len = (data.len() * 2) as u32;
    let mut out = Vec::new();
    out.extend(b"RIFF");
    out.extend((36 + len).to_le_bytes());
    out.extend(b"WAVEfmt ");
    out.extend(16u32.to_le_bytes());
    out.extend(1u16.to_le_bytes());
    out.extend(1u16.to_le_bytes());
    out.extend(rate.to_le_bytes());
    out.extend((rate * 2).to_le_bytes());
    out.extend(2u16.to_le_bytes());
    out.extend(16u16.to_le_bytes());
    out.extend(b"data");
    out.extend(len.to_le_bytes());
    for x in data {
        out.extend(((x.clamp(-1., 1.) * 32000.) as i16).to_le_bytes());
    }
    fs::write(path, out).unwrap();
}
fn main() {
    let dir = std::env::args()
        .nth(1)
        .unwrap_or("demo/assets/audio".into());
    let dir = Path::new(&dir);
    fs::create_dir_all(dir).unwrap();
    let rate = 22050u32;
    let mut seed = 42u64;
    let mut noise = || {
        seed ^= seed << 13;
        seed ^= seed >> 7;
        seed ^= seed << 17;
        (seed % 10000) as f32 / 5000. - 1.
    };
    let seconds = 32.;
    let mut music = vec![0.; (seconds * rate as f32) as usize];
    let chords = [
        [110., 130.8128, 164.8138],
        [87.3071, 110., 130.8128],
        [73.4162, 110., 146.8324],
        [82.4069, 103.8262, 123.4708],
    ];
    for (i, s) in music.iter_mut().enumerate() {
        let t = i as f32 / rate as f32;
        let section = (t / 8.) as usize;
        let local = t % 8.;
        let env = (local / 1.5).min(1.) * ((8. - local) / 1.8).min(1.);
        let chord = chords[section];
        let pad = chord
            .iter()
            .map(|f| ((TAU * f * t).sin() + 0.25 * (TAU * f * 2. * t).sin()) * 0.028)
            .sum::<f32>()
            * env;
        let beat = t % 1.;
        let pulse = (TAU * (52. * beat - 12. * beat * beat)).sin() * (-beat * 9.).exp() * 0.09;
        let note_time = t % 2.;
        let note = chord[((t / 2.) as usize) % 3] * 4.;
        let bell = ((TAU * note * t).sin() + 0.25 * (TAU * note * 2.01 * t).sin())
            * (-note_time * 2.2).exp()
            * (note_time * 45.).min(1.)
            * 0.06;
        let edge = (t / 0.1).min(1.) * ((seconds - t) / 0.1).min(1.);
        *s = (pad + pulse + bell + noise() * 0.004) * edge;
    }
    wave(&dir.join("debate.wav"), &music, rate);
    for name in [
        "click", "paper", "attack", "block", "hurt", "victory", "defeat", "power",
    ] {
        let duration = match name {
            "victory" => 1.9,
            "defeat" => 1.5,
            "power" => 1.0,
            _ => 0.38,
        };
        let data = (0..(duration * rate as f32) as usize)
            .map(|i| {
                let t = i as f32 / rate as f32;
                let env = (t * 100.).min(1.) * (1. - t / duration).max(0.).powi(2);
                let n = noise();
                let value = match name {
                    "click" => (TAU * 640. * t).sin() * (-t * 32.).exp() * 0.18,
                    "paper" => n * 0.14 * (1. + (t * 70.).sin()) * (-t * 8.).exp(),
                    "attack" => {
                        n * 0.2 * (-t * 10.).exp() + (TAU * (190. * t - 160. * t * t)).sin() * 0.22
                    }
                    "block" => (TAU * 680. * t).sin() * 0.13 + (TAU * 1020. * t).sin() * 0.08,
                    "hurt" => n * 0.1 + (TAU * 65. * t).sin() * 0.23,
                    "victory" => {
                        let f =
                            [261.6256, 329.6276, 391.9954, 523.2511][((t / 0.23) as usize).min(3)];
                        (TAU * f * t).sin() * 0.18
                    }
                    "defeat" => (TAU * (180. * t - 45. * t * t)).sin() * 0.16,
                    _ => {
                        (TAU * (220. * t + 180. * t * t)).sin() * 0.12
                            + (TAU * 440. * t).sin() * 0.08
                    }
                };
                value * env
            })
            .collect::<Vec<_>>();
        wave(&dir.join(format!("{name}.wav")), &data, rate);
    }
    println!(
        "Original ambience and 8 sound effects written to {}",
        dir.display()
    );
}
