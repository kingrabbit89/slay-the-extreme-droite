//! A small deterministic test player, used only by regression and balance tooling.
use crate::{Game, Kind};

pub fn resolve_choice(g: &mut Game) {
    if g.pending.is_empty() {
        return;
    }
    let index = g
        .choices
        .iter()
        .enumerate()
        .max_by_key(|(_, c)| match g.pending {
            "scry" => match c.id {
                19 => 12,
                8 => 10,
                6 | 9 | 18 => 9,
                3 => 8,
                0 => 5,
                _ => 3,
            },
            _ => match c.id {
                23 => 100,
                0 | 1 => 10,
                _ => 0,
            },
        })
        .map(|(i, _)| i)
        .unwrap_or(0);
    g.choose(index).unwrap();
}

fn score(before: &Game, after: &Game) -> f64 {
    if after.phase == "reward" || after.phase == "won" {
        return 1000.;
    }
    let incoming: i32 = after
        .enemies
        .iter()
        .filter(|e| e.hp > 0)
        .map(|e| {
            let i = e.intent();
            i.damage * i.hits
        })
        .sum();
    let old_incoming: i32 = before
        .enemies
        .iter()
        .filter(|e| e.hp > 0)
        .map(|e| {
            let i = e.intent();
            i.damage * i.hits
        })
        .sum();
    let prevented = (old_incoming - before.block).max(0) - (incoming - after.block).max(0);
    let attack = (after.total_damage - before.total_damage) as f64;
    attack
        + prevented as f64 * 1.25
        + (after.hand.len() as f64 - before.hand.len() as f64) * 0.55
        + (after.powers.len() - before.powers.len()) as f64 * 4.0
}

pub fn next_action(g: &Game) -> Option<(usize, usize)> {
    let mut best: Option<(f64, usize, usize)> = None;
    for (i, c) in g.hand.iter().enumerate() {
        if c.cost() < 0 || c.cost() > g.energy {
            continue;
        }
        for (j, e) in g.enemies.iter().enumerate() {
            if e.hp <= 0 {
                continue;
            }
            let mut trial = g.clone();
            if trial.play(i, j).is_err() {
                continue;
            }
            resolve_choice(&mut trial);
            let mut value = score(g, &trial);
            // Evaluate one further action to see free Amendments before finishers.
            let mut future: f64 = 0.;
            if trial.phase == "combat" {
                for k in 0..trial.hand.len() {
                    let mut next = trial.clone();
                    if next.play(k, j).is_ok() {
                        resolve_choice(&mut next);
                        future = future.max(score(&trial, &next));
                    }
                }
            }
            value += future * 0.9;
            if c.id == 4 && g.played == 0 {
                value += 4.;
            }
            if c.id == 22 {
                value += 0.8;
            }
            if c.def().kind == Kind::Attack && e.hp <= 6 {
                value += 1.;
            }
            if best.is_none_or(|b| value > b.0) {
                best = Some((value, i, j));
            }
        }
    }
    best.filter(|b| b.0 > 0.01).map(|(_, i, j)| (i, j))
}

pub fn run(seed: u64, route: i32) -> Game {
    let mut g = Game::new(seed);
    for _ in 0..1600 {
        match g.phase {
            "map" => g.enter(route).unwrap(),
            "combat" => {
                if !g.pending.is_empty() {
                    resolve_choice(&mut g);
                } else if let Some((i, j)) = next_action(&g) {
                    g.play(i, j).unwrap();
                } else {
                    g.end_turn().unwrap();
                }
            }
            "reward" => {
                let idx = g
                    .offers
                    .iter()
                    .position(|c| c.id == 8 || c.id == 19)
                    .unwrap_or(0);
                g.reward(idx as i32).unwrap();
            }
            "rest" => g.rest(-1).unwrap(),
            "won" | "lost" => return g,
            _ => panic!("Unknown phase"),
        }
    }
    panic!("Run exceeded action budget, seed {seed}");
}

#[cfg(test)]
mod tests {
    #[test]
    fn complete_runs_cover_both_routes_without_deadlock() {
        let mut wins = 0;
        for route in 0..2 {
            for seed in 1..21 {
                let g = super::run(seed, route);
                assert!(matches!(g.phase, "won" | "lost"));
                assert!(g.hp >= 0 && g.hp <= 70);
                if g.phase == "won" {
                    wins += 1;
                }
            }
        }
        assert!(
            wins > 0,
            "At least one complete winning route must be possible"
        );
    }
}
