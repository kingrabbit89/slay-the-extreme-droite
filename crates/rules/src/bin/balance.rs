use tribune_rules::bot;
fn main() {
    for route in 0..2 {
        let mut wins = 0;
        let mut hp = 0;
        let mut cards = 0;
        for seed in 1..=100 {
            let g = bot::run(seed, route);
            if g.phase == "won" {
                wins += 1;
                hp += g.hp;
            }
            cards += g.total_cards;
        }
        println!(
            "route={route} seeds=1..100 wins={wins} mean_winner_hp={:.1} mean_cards={:.1}",
            hp as f64 / wins.max(1) as f64,
            cards as f64 / 100.
        );
    }
}
