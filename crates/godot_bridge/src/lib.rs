use godot::prelude::*;
use tribune_rules::{Card, Game, Kind};
type Data = Dictionary<Variant, Variant>;

struct TribuneExtension;
#[gdextension]
unsafe impl ExtensionLibrary for TribuneExtension {}

#[derive(GodotClass)]
#[class(base=RefCounted)]
struct TribuneCore {
    game: Game,
    base: Base<RefCounted>,
}

#[godot_api]
impl IRefCounted for TribuneCore {
    fn init(base: Base<RefCounted>) -> Self {
        Self {
            game: Game::new(2026),
            base,
        }
    }
}

fn dict(items: Vec<(&str, Variant)>) -> Data {
    let mut d = Data::new();
    for (k, v) in items {
        d.set(k, &v);
    }
    d
}
fn card(c: &Card) -> Data {
    let def = c.def();
    dict(vec![
        ("id", (c.id as i32).to_variant()),
        ("uid", (c.uid as i64).to_variant()),
        ("name", c.title().to_variant()),
        ("description", c.description().to_variant()),
        ("cost", c.cost().to_variant()),
        (
            "kind",
            match def.kind {
                Kind::Attack => "Attaque",
                Kind::Skill => "Compétence",
                Kind::Power => "Pouvoir",
                Kind::Status => "Statut",
            }
            .to_variant(),
        ),
        ("rarity", def.rarity.to_variant()),
        ("art", def.art.to_variant()),
        ("plus", c.plus.to_variant()),
    ])
}
fn cards(list: &[Card]) -> Array<Data> {
    list.iter().map(card).collect()
}
fn answer(result: Result<(), String>) -> GString {
    result.err().unwrap_or_default().as_str().into()
}

#[godot_api]
impl TribuneCore {
    #[func]
    fn new_run(&mut self, seed: i64) {
        self.game = Game::new(seed as u64);
    }
    #[func]
    fn enter_room(&mut self, route: i32) -> GString {
        answer(self.game.enter(route))
    }
    #[func]
    fn play_card(&mut self, index: i32, target: i32) -> GString {
        answer(self.game.play(index as usize, target as usize))
    }
    #[func]
    fn end_turn(&mut self) -> GString {
        answer(self.game.end_turn())
    }
    #[func]
    fn choose_card(&mut self, index: i32) -> GString {
        answer(self.game.choose(index as usize))
    }
    #[func]
    fn take_reward(&mut self, index: i32) -> GString {
        answer(self.game.reward(index))
    }
    #[func]
    fn rest(&mut self, index: i32) -> GString {
        answer(self.game.rest(index))
    }
    #[func]
    fn save_code(&self) -> GString {
        self.game.save().as_str().into()
    }
    #[func]
    fn load_code(&mut self, code: GString) -> GString {
        match Game::load(&code.to_string()) {
            Ok(g) => {
                self.game = g;
                GString::new()
            }
            Err(e) => e.as_str().into(),
        }
    }
    #[func]
    fn catalog(&self) -> Array<Data> {
        (2..22)
            .map(|id| {
                card(&Card {
                    id,
                    plus: false,
                    uid: 0,
                })
            })
            .collect()
    }
    #[func]
    fn snapshot(&self) -> Data {
        let g = &self.game;
        let enemies: Array<Data> = g
            .enemies
            .iter()
            .map(|e| {
                let i = e.intent();
                dict(vec![
                    ("name", e.name.to_variant()),
                    ("hp", e.hp.to_variant()),
                    ("max_hp", e.max_hp.to_variant()),
                    ("block", e.block.to_variant()),
                    ("weak", e.weak.to_variant()),
                    ("vulnerable", e.vulnerable.to_variant()),
                    ("strength", e.strength.to_variant()),
                    ("sprite", e.sprite.to_variant()),
                    ("intent", i.name.to_variant()),
                    ("damage", i.damage.to_variant()),
                    ("hits", i.hits.to_variant()),
                    ("intent_block", i.block.to_variant()),
                    ("noise", i.noise.to_variant()),
                    ("intent_strength", i.strength.to_variant()),
                ])
            })
            .collect();
        let powers: Array<Data> = g
            .powers
            .iter()
            .map(|p| {
                card(&Card {
                    id: p.id,
                    plus: p.plus,
                    uid: 0,
                })
            })
            .collect();
        let events: Array<Data> = g
            .events
            .iter()
            .map(|e| {
                dict(vec![
                    ("kind", e.kind.to_variant()),
                    ("target", e.target.to_variant()),
                    ("amount", e.amount.to_variant()),
                    ("text", e.text.to_variant()),
                ])
            })
            .collect();
        dict(vec![
            ("phase", g.phase.to_variant()),
            ("floor", g.floor.to_variant()),
            ("hp", g.hp.to_variant()),
            ("max_hp", g.max_hp.to_variant()),
            ("gold", g.gold.to_variant()),
            ("energy", g.energy.to_variant()),
            ("block", g.block.to_variant()),
            ("turn", g.turn.to_variant()),
            ("played", g.played.to_variant()),
            ("amendments", g.amendments.to_variant()),
            ("hand", cards(&g.hand).to_variant()),
            ("deck", cards(&g.deck).to_variant()),
            ("draw", cards(&g.draw).to_variant()),
            ("discard", cards(&g.discard).to_variant()),
            ("exhaust", cards(&g.exhaust).to_variant()),
            ("enemies", enemies.to_variant()),
            ("powers", powers.to_variant()),
            ("events", events.to_variant()),
            ("offers", cards(&g.offers).to_variant()),
            ("pending", g.pending.to_variant()),
            ("choices", cards(&g.choices).to_variant()),
            ("relic", g.relic.to_variant()),
            ("total_damage", g.total_damage.to_variant()),
            ("total_cards", g.total_cards.to_variant()),
            ("seed", (g.seed as i64).to_variant()),
        ])
    }
}
