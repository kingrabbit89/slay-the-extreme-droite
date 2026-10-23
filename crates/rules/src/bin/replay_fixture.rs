use tribune_rules::{Game, bot};
fn main() {
    let mut g = Game::new(42);
    let mut rows = vec!["new_run,42".to_string()];
    for _ in 0..1600 {
        match g.phase {
            "map" => {
                rows.push("enter_room,1".into());
                g.enter(1).unwrap();
            }
            "combat" => {
                if !g.pending.is_empty() {
                    rows.push("choose_card,0".into());
                    g.choose(0).unwrap();
                } else if let Some((i, j)) = bot::next_action(&g) {
                    rows.push(format!("play_card,{i},{j}"));
                    g.play(i, j).unwrap();
                } else {
                    rows.push("end_turn".into());
                    g.end_turn().unwrap();
                }
            }
            "reward" => {
                let i = g
                    .offers
                    .iter()
                    .position(|c| c.id == 8 || c.id == 19)
                    .unwrap_or(0);
                rows.push(format!("take_reward,{i}"));
                g.reward(i as i32).unwrap();
            }
            "rest" => {
                rows.push("rest,-1".into());
                g.rest(-1).unwrap();
            }
            "won" | "lost" => break,
            _ => panic!("unknown phase"),
        }
    }
    assert_eq!(g.phase, "won", "Fixture seed must produce a win");
    std::fs::write("demo/tests/winning_run.txt", rows.join("\n")).unwrap();
    println!("Recorded {} actions, victory with {} HP", rows.len(), g.hp);
}
