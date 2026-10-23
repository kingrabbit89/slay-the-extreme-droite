pub mod bot;
pub mod cards;
pub use cards::{CATALOG, Card, Kind};

#[derive(Clone, Debug)]
pub struct Event {
    pub kind: &'static str,
    pub target: i32,
    pub amount: i32,
    pub text: String,
}
#[derive(Clone, Debug)]
pub struct Enemy {
    pub name: String,
    pub hp: i32,
    pub max_hp: i32,
    pub block: i32,
    pub weak: i32,
    pub vulnerable: i32,
    pub strength: i32,
    pub sprite: i32,
    pub step: usize,
}
#[derive(Clone, Debug)]
pub struct Intent {
    pub name: &'static str,
    pub damage: i32,
    pub hits: i32,
    pub block: i32,
    pub noise: i32,
    pub strength: i32,
}
impl Enemy {
    pub fn intent(&self) -> Intent {
        let (name, damage, hits, block, noise, strength) = match self.sprite {
            3 => match self.step % 3 {
                0 => ("Rumeur", 6, 1, 0, 0, 0),
                1 => ("Faux-semblant", 0, 0, 7, 0, 0),
                _ => ("Matraquage", 4, 2, 0, 0, 0),
            },
            4 => match self.step % 3 {
                0 => ("Interruption", 8, 1, 0, 0, 0),
                1 => ("Brouillage", 0, 0, 5, 1, 0),
                _ => ("Procès d'intention", 11, 1, 0, 0, 0),
            },
            _ => match self.step % 4 {
                0 => ("Onde de choc", 10, 1, 0, 0, 0),
                1 => ("Propagande", 0, 0, 9, 1, 2),
                2 => ("En boucle", 5, 3, 0, 0, 0),
                _ => ("Écran de fumée", 15, 1, 0, 0, 0),
            },
        };
        let raw = damage + if damage > 0 { self.strength } else { 0 };
        Intent {
            name,
            damage: if self.weak > 0 { raw * 3 / 4 } else { raw },
            hits,
            block,
            noise,
            strength,
        }
    }
}

#[derive(Clone, Debug)]
pub struct Power {
    pub id: u8,
    pub plus: bool,
}

#[derive(Clone, Debug)]
pub struct Game {
    pub phase: &'static str,
    pub floor: i32,
    pub hp: i32,
    pub max_hp: i32,
    pub gold: i32,
    pub deck: Vec<Card>,
    pub hand: Vec<Card>,
    pub draw: Vec<Card>,
    pub discard: Vec<Card>,
    pub exhaust: Vec<Card>,
    pub enemies: Vec<Enemy>,
    pub energy: i32,
    pub block: i32,
    pub turn: i32,
    pub played: i32,
    pub skills: i32,
    pub normal_skills: i32,
    pub amendments: i32,
    pub powers: Vec<Power>,
    pub offers: Vec<Card>,
    pub pending: &'static str,
    pub choices: Vec<Card>,
    pub events: Vec<Event>,
    pub relic: bool,
    pub total_damage: i32,
    pub total_cards: i32,
    pub seed: u64,
    rng: u64,
    next_uid: u32,
    eco_used: bool,
    commission_used: bool,
    president_used: bool,
    pub route: i32,
}

impl Game {
    pub fn new(seed: u64) -> Self {
        let mut g = Self {
            phase: "map",
            floor: 0,
            hp: 70,
            max_hp: 70,
            gold: 0,
            deck: vec![],
            hand: vec![],
            draw: vec![],
            discard: vec![],
            exhaust: vec![],
            enemies: vec![],
            energy: 0,
            block: 0,
            turn: 0,
            played: 0,
            skills: 0,
            normal_skills: 0,
            amendments: 0,
            powers: vec![],
            offers: vec![],
            pending: "",
            choices: vec![],
            events: vec![],
            relic: false,
            total_damage: 0,
            total_cards: 0,
            seed,
            rng: seed.max(1),
            next_uid: 1,
            eco_used: false,
            commission_used: false,
            president_used: false,
            route: 0,
        };
        for id in [0, 0, 0, 0, 1, 1, 1, 1, 3, 4] {
            let c = g.make(id);
            g.deck.push(c);
        }
        g
    }
    fn random(&mut self, n: usize) -> usize {
        self.rng ^= self.rng << 13;
        self.rng ^= self.rng >> 7;
        self.rng ^= self.rng << 17;
        (self.rng as usize) % n.max(1)
    }
    fn make(&mut self, id: u8) -> Card {
        let c = Card {
            id,
            plus: false,
            uid: self.next_uid,
        };
        self.next_uid += 1;
        c
    }
    fn emit(&mut self, kind: &'static str, target: i32, amount: i32, text: impl Into<String>) {
        self.events.push(Event {
            kind,
            target,
            amount,
            text: text.into(),
        });
    }
    fn shuffle(&mut self) {
        for i in (1..self.draw.len()).rev() {
            let j = self.random(i + 1);
            self.draw.swap(i, j);
        }
    }
    fn refill(&mut self) {
        if self.draw.is_empty() && !self.discard.is_empty() {
            self.draw.append(&mut self.discard);
            self.shuffle();
            self.emit("shuffle", -1, 0, "Défausse mélangée");
        }
    }
    fn draw_cards(&mut self, n: i32) {
        for _ in 0..n {
            self.refill();
            if self.hand.len() >= 10 {
                break;
            }
            if let Some(c) = self.draw.pop() {
                self.hand.push(c);
            }
        }
    }
    fn add_hand(&mut self, id: u8) {
        let c = self.make(id);
        if self.hand.len() < 10 {
            self.hand.push(c)
        } else {
            self.discard.push(c);
            self.emit("info", -1, 0, "Main pleine : carte défaussée");
        }
    }
    fn gain_block(&mut self, n: i32) {
        if n > 0 {
            self.block += n;
            self.emit("block", -1, n, format!("+{n} Bloc"));
        }
    }
    fn power(&self, id: u8) -> Option<bool> {
        self.powers.iter().find(|p| p.id == id).map(|p| p.plus)
    }
    fn exhaust_card(&mut self, c: Card) {
        self.exhaust.push(c);
        if !self.eco_used {
            if let Some(plus) = self.power(15) {
                self.eco_used = true;
                self.gain_block(if plus { 6 } else { 4 });
                self.emit("power", -1, 0, "Écologie populaire");
            }
        }
    }
    fn hit(&mut self, target: usize, n: i32) {
        if target >= self.enemies.len() || self.enemies[target].hp <= 0 {
            return;
        }
        let e = &mut self.enemies[target];
        let damage = if e.vulnerable > 0 { n * 3 / 2 } else { n };
        let absorbed = damage.min(e.block);
        e.block -= absorbed;
        let loss = (damage - absorbed).min(e.hp);
        e.hp -= loss;
        self.total_damage += loss;
        self.emit("hit", target as i32, damage, format!("{damage}"));
        if self.enemies[target].hp == 0 {
            self.emit("death", target as i32, 0, "Argument réfuté");
        }
    }
    fn win_check(&mut self) -> bool {
        if self.enemies.iter().all(|e| e.hp <= 0) {
            self.pending = "";
            self.choices.clear();
            if self.floor == 3 {
                self.phase = "won";
                self.emit("victory", -1, 0, "Le dernier mot vous appartient.");
            } else {
                self.phase = "reward";
                self.gold += 25;
                if self.floor == 1 && self.route == 1 {
                    self.relic = true;
                    self.gold += 15;
                }
                self.offers.clear();
                // Guarantee an early route into the character's signature engine.
                let ids = if self.floor == 0 {
                    vec![8, 6, 19]
                } else {
                    let pool = [2, 5, 7, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 20, 21];
                    let a = self.random(pool.len());
                    vec![
                        pool[a],
                        pool[(a + 5) % pool.len()],
                        pool[(a + 9) % pool.len()],
                    ]
                };
                for id in ids {
                    let c = self.make(id);
                    self.offers.push(c);
                }
                self.emit("victory", -1, 25, "Débat remporté");
            }
            true
        } else {
            false
        }
    }
    pub fn enter(&mut self, route: i32) -> Result<(), String> {
        if self.phase != "map" {
            return Err("Choisissez une étape sur la carte.".into());
        }
        self.events.clear();
        self.route = route.clamp(0, 1);
        if self.floor == 2 {
            self.phase = "rest";
            return Ok(());
        }
        self.phase = "combat";
        self.hand.clear();
        self.draw = self.deck.clone();
        self.discard.clear();
        self.exhaust.clear();
        self.powers.clear();
        self.pending = "";
        self.choices.clear();
        self.turn = 0;
        self.enemies.clear();
        let specs = match self.floor {
            0 => vec![("Le Colporteur", 36, 3)],
            1 => {
                if self.route == 1 {
                    vec![("L'Éditorialiste", 42, 4), ("La Rumeur", 23, 3)]
                } else {
                    vec![("L'Éditorialiste", 49, 4)]
                }
            }
            _ => vec![("La Machine à peur", 98, 5)],
        };
        for (name, hp, sprite) in specs {
            self.enemies.push(Enemy {
                name: name.into(),
                hp,
                max_hp: hp,
                block: 0,
                weak: 0,
                vulnerable: 0,
                strength: 0,
                sprite,
                step: 0,
            });
        }
        self.shuffle();
        self.start_turn();
        Ok(())
    }
    fn start_turn(&mut self) {
        self.turn += 1;
        self.energy = 3;
        self.block = 0;
        self.played = 0;
        self.skills = 0;
        self.normal_skills = 0;
        self.amendments = 0;
        self.eco_used = false;
        self.commission_used = false;
        self.president_used = false;
        self.draw_cards(5);
        if self.power(20).is_some() {
            self.add_hand(22);
        }
        if self.relic && self.turn == 1 {
            self.gain_block(5);
        }
        self.emit(
            "turn",
            -1,
            self.turn,
            format!("Tour {} · À vous de jouer", self.turn),
        );
    }
    pub fn play(&mut self, index: usize, target: usize) -> Result<(), String> {
        if self.phase != "combat" || !self.pending.is_empty() {
            return Err("Terminez le choix en cours.".into());
        }
        let c = self.hand.get(index).ok_or("Carte introuvable.")?.clone();
        if c.def().kind == Kind::Status {
            return Err("Brouhaha est injouable.".into());
        }
        if self.energy < c.cost() {
            return Err("Énergie insuffisante.".into());
        }
        if target >= self.enemies.len() || self.enemies[target].hp <= 0 {
            return Err("Choisissez un adversaire encore actif.".into());
        }
        if c.id == 12 && self.hand.len() < 2 {
            return Err("Il faut une autre carte à épuiser.".into());
        }
        self.events.clear();
        self.energy -= c.cost();
        self.hand.remove(index);
        let v = |a, b| c.value(a, b);
        let is_attack = c.def().kind == Kind::Attack;
        let alt = self.enemies[target].weak > 0 || self.enemies[target].vulnerable > 0;
        self.emit(
            if is_attack { "attack" } else { "skill" },
            target as i32,
            0,
            c.title(),
        );
        match c.id {
            0 => self.hit(target, v(6, 9)),
            1 => self.gain_block(v(5, 8)),
            2 => self.hit(target, v(7, 9) + if self.amendments > 0 { 3 } else { 0 }),
            3 => {
                self.gain_block(v(5, 8));
                self.add_hand(22);
            }
            4 => {
                self.draw_cards(1);
                if self.played == 0 {
                    self.add_hand(22);
                }
                if c.plus {
                    self.gain_block(3);
                }
            }
            5 => {
                self.draw_cards(2);
                self.gain_block(v(4, 7));
                if !self.hand.is_empty() {
                    self.pending = "discard";
                    self.choices = self.hand.clone();
                }
            }
            6 => {
                self.hit(target, v(8, 11));
                if self.enemies[target].intent().damage > 0 {
                    self.enemies[target].weak += 1;
                    self.emit("debuff", target as i32, 1, "Faiblesse");
                }
            }
            7 => {
                self.gain_block(v(6, 9));
                if self.skills > 0 {
                    self.enemies[target].weak += 1;
                    self.emit("debuff", target as i32, 1, "Faiblesse");
                }
            }
            8 => {
                self.add_hand(22);
                self.add_hand(22);
                self.gain_block(v(2, 5));
            }
            9 => {
                self.hit(target, v(13, 16));
                let noise = self.make(23);
                self.discard.push(noise);
            }
            10 | 11 | 15 | 20 | 21 => {
                if let Some(p) = self.powers.iter_mut().find(|p| p.id == c.id) {
                    p.plus |= c.plus;
                } else {
                    self.powers.push(Power {
                        id: c.id,
                        plus: c.plus,
                    });
                }
                self.emit("power", -1, 0, c.title());
            }
            12 => {
                if c.plus {
                    self.gain_block(3);
                }
                self.pending = "exhaust";
                self.choices = self.hand.clone();
            }
            13 => {
                self.hit(target, v(7, 10));
                if self.skills >= 2 {
                    self.enemies[target].vulnerable += 1;
                    self.emit("debuff", target as i32, 1, "Vulnérable");
                }
            }
            14 => self.gain_block(v(7, 10) + if self.amendments > 0 { 4 } else { 0 }),
            16 => {
                self.choices.clear();
                for _ in 0..v(3, 4) {
                    self.refill();
                    if let Some(card) = self.draw.pop() {
                        self.choices.push(card);
                    }
                }
                if self.choices.is_empty() {
                    self.add_hand(22);
                } else {
                    self.pending = "scry";
                }
            }
            17 => self.gain_block(v(4, 6) + (self.skills * 3).min(9)),
            18 => {
                let weak = self.enemies[target].weak > 0;
                self.hit(target, v(8, 10));
                self.hit(target, v(8, 10));
                if weak {
                    self.hit(target, 5);
                }
            }
            19 => self.hit(target, v(12, 15) + (self.amendments * 4).min(16)),
            22 => {
                self.gain_block(2);
                if self.amendments == 0 && self.power(20).is_some() {
                    self.gain_block(3);
                }
                self.amendments += 1;
            }
            _ => {}
        }
        self.played += 1;
        self.total_cards += 1;
        if c.def().kind == Kind::Skill {
            self.skills += 1;
            if c.id != 22 {
                self.normal_skills += 1;
            }
        }
        if self.played == 3 {
            self.gain_block(3);
            self.emit("relic", -1, 3, "Le perchoir");
        }
        if c.def().kind == Kind::Skill
            && c.id != 22
            && self.normal_skills == 2
            && !self.president_used
        {
            if let Some(plus) = self.power(10) {
                self.president_used = true;
                self.add_hand(22);
                if plus {
                    self.gain_block(2);
                }
            }
        }
        if is_attack && alt && !self.commission_used {
            if let Some(plus) = self.power(11) {
                self.commission_used = true;
                self.draw_cards(1);
                if plus {
                    self.gain_block(2);
                }
            }
        }
        if self.played == 4 {
            if let Some(plus) = self.power(21) {
                for i in 0..self.enemies.len() {
                    self.hit(i, if plus { 11 } else { 8 });
                }
                self.emit("power", -1, 0, "La tribune ne se tait pas");
            }
        }
        if c.exhausts() {
            self.exhaust_card(c);
        } else if c.def().kind != Kind::Power {
            self.discard.push(c);
        }
        self.win_check();
        Ok(())
    }
    pub fn choose(&mut self, index: usize) -> Result<(), String> {
        if self.phase != "combat" || self.pending.is_empty() {
            return Err("Aucun choix en cours.".into());
        }
        let c = self.choices.get(index).ok_or("Choix invalide.")?.clone();
        self.events.clear();
        match self.pending {
            "discard" | "exhaust" => {
                let pos = self
                    .hand
                    .iter()
                    .position(|h| h.uid == c.uid)
                    .ok_or("Carte absente de la main.")?;
                self.hand.remove(pos);
                if self.pending == "exhaust" {
                    let status = c.def().kind == Kind::Status;
                    self.exhaust_card(c);
                    self.add_hand(22);
                    if status {
                        self.draw_cards(1);
                    }
                } else {
                    self.discard.push(c);
                }
            }
            "scry" => {
                self.choices.remove(index);
                if self.hand.len() < 10 {
                    self.hand.push(c);
                } else {
                    self.discard.push(c);
                }
                let others = std::mem::take(&mut self.choices);
                for c in others {
                    self.draw.insert(0, c);
                }
                self.add_hand(22);
            }
            _ => return Err("Choix inconnu.".into()),
        }
        self.pending = "";
        self.choices.clear();
        Ok(())
    }
    pub fn end_turn(&mut self) -> Result<(), String> {
        if self.phase != "combat" || !self.pending.is_empty() {
            return Err("Terminez le choix avant de finir le tour.".into());
        }
        self.events.clear();
        for c in std::mem::take(&mut self.hand) {
            if c.id == 23 {
                self.exhaust_card(c);
            } else {
                self.discard.push(c);
            }
        }
        for i in 0..self.enemies.len() {
            if self.enemies[i].hp <= 0 {
                continue;
            }
            self.enemies[i].block = 0;
            let intent = self.enemies[i].intent();
            self.emit("enemy", i as i32, 0, intent.name);
            for _ in 0..intent.hits {
                let absorbed = self.block.min(intent.damage);
                self.block -= absorbed;
                let loss = (intent.damage - absorbed).min(self.hp);
                self.hp -= loss;
                self.emit(
                    "hurt",
                    -1,
                    loss,
                    if loss == 0 {
                        "Bloqué".into()
                    } else {
                        format!("−{loss}")
                    },
                );
            }
            if self.hp <= 0 {
                self.phase = "lost";
                self.emit("defeat", -1, 0, "La tribune s'éteint…");
                return Ok(());
            }
            self.enemies[i].block += intent.block;
            self.enemies[i].strength += intent.strength;
            for _ in 0..intent.noise {
                let c = self.make(23);
                self.discard.push(c);
                self.emit("noise", -1, 1, "Brouhaha ajouté à la défausse");
            }
            self.enemies[i].weak = (self.enemies[i].weak - 1).max(0);
            self.enemies[i].vulnerable = (self.enemies[i].vulnerable - 1).max(0);
            self.enemies[i].step += 1;
        }
        self.start_turn();
        Ok(())
    }
    pub fn reward(&mut self, index: i32) -> Result<(), String> {
        if self.phase != "reward" {
            return Err("Aucune récompense disponible.".into());
        }
        if index >= 0 {
            let c = self
                .offers
                .get(index as usize)
                .ok_or("Récompense invalide.")?
                .clone();
            self.deck.push(c);
        }
        self.offers.clear();
        self.floor += 1;
        self.phase = "map";
        self.events.clear();
        Ok(())
    }
    pub fn rest(&mut self, index: i32) -> Result<(), String> {
        if self.phase != "rest" {
            return Err("Vous n'êtes pas à la halte.".into());
        }
        if index < 0 {
            self.hp = (self.hp + 24).min(self.max_hp);
        } else {
            let c = self.deck.get_mut(index as usize).ok_or("Carte inconnue.")?;
            if c.plus {
                return Err("Déjà améliorée.".into());
            }
            c.plus = true;
        }
        self.floor += 1;
        self.phase = "map";
        Ok(())
    }
    /// Checkpoints are deliberately between encounters: no partial action can be saved.
    pub fn save(&self) -> String {
        if self.phase != "map" {
            return String::new();
        }
        let cards = self
            .deck
            .iter()
            .map(|c| format!("{}:{}", c.id, u8::from(c.plus)))
            .collect::<Vec<_>>()
            .join(",");
        format!(
            "TRIBUNE1|{}|{}|{}|{}|{}|{}|{}|{}|{}",
            self.seed,
            self.rng,
            self.floor,
            self.hp,
            self.gold,
            u8::from(self.relic),
            self.total_damage,
            self.total_cards,
            cards
        )
    }
    pub fn load(code: &str) -> Result<Self, String> {
        let bad = || "Sauvegarde illisible ou incompatible.".to_string();
        let p: Vec<_> = code.split('|').collect();
        if p.len() != 10 || p[0] != "TRIBUNE1" {
            return Err(bad());
        }
        let mut g = Self::new(p[1].parse().map_err(|_| bad())?);
        g.rng = p[2].parse().map_err(|_| bad())?;
        g.floor = p[3].parse().map_err(|_| bad())?;
        g.hp = p[4].parse().map_err(|_| bad())?;
        g.gold = p[5].parse().map_err(|_| bad())?;
        g.relic = p[6] == "1";
        g.total_damage = p[7].parse().map_err(|_| bad())?;
        g.total_cards = p[8].parse().map_err(|_| bad())?;
        if !(0..=3).contains(&g.floor) || !(1..=70).contains(&g.hp) || g.rng == 0 || g.gold < 0 {
            return Err(bad());
        }
        g.deck.clear();
        for text in p[9].split(',') {
            let bits: Vec<_> = text.split(':').collect();
            if bits.len() != 2 {
                return Err(bad());
            }
            let id: u8 = bits[0].parse().map_err(|_| bad())?;
            if id >= 22 || !matches!(bits[1], "0" | "1") {
                return Err(bad());
            }
            let mut c = g.make(id);
            c.plus = bits[1] == "1";
            g.deck.push(c);
        }
        if !(10..=12).contains(&g.deck.len()) {
            return Err(bad());
        }
        Ok(g)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    fn battle() -> Game {
        let mut g = Game::new(1234);
        g.enter(0).unwrap();
        g.enemies[0].hp = 500;
        g.enemies[0].max_hp = 500;
        g.hand.clear();
        g.draw.clear();
        g.discard.clear();
        g
    }
    fn hand(g: &mut Game, ids: &[u8]) {
        g.hand.clear();
        for id in ids {
            let c = g.make(*id);
            g.hand.push(c);
        }
    }
    #[test]
    fn opening_deck_and_seed_are_reproducible() {
        let mut a = Game::new(42);
        let mut b = Game::new(42);
        a.enter(0).unwrap();
        b.enter(0).unwrap();
        assert_eq!(a.hand, b.hand);
        assert_eq!(a.hand.len(), 5);
        assert_eq!(a.draw.len(), 5);
    }
    #[test]
    fn obstruction_combo_matches_design() {
        let mut g = battle();
        hand(&mut g, &[4, 8, 19]);
        g.play(0, 0).unwrap();
        g.play(2, 0).unwrap();
        g.play(0, 0).unwrap();
        g.play(1, 0).unwrap();
        g.play(1, 0).unwrap();
        g.play(0, 0).unwrap();
        assert_eq!(
            (g.energy, g.block, g.total_damage, g.played),
            (0, 11, 24, 6)
        );
    }
    #[test]
    fn illegal_actions_are_atomic() {
        let mut g = battle();
        hand(&mut g, &[19]);
        g.energy = 1;
        let before = g.hand.clone();
        assert!(g.play(0, 0).is_err());
        assert_eq!(before, g.hand);
        assert_eq!(g.energy, 1);
        assert!(g.play(99, 0).is_err());
    }
    #[test]
    fn weak_changes_telegraph_and_expires_after_enemy_action() {
        let mut g = battle();
        hand(&mut g, &[6]);
        g.play(0, 0).unwrap();
        assert_eq!(g.enemies[0].intent().damage, 4);
        g.end_turn().unwrap();
        assert_eq!(g.hp, 66);
        assert_eq!(g.enemies[0].weak, 0);
    }
    #[test]
    fn block_prevents_damage_and_resets() {
        let mut g = battle();
        hand(&mut g, &[1, 1]);
        g.play(0, 0).unwrap();
        g.play(0, 0).unwrap();
        g.end_turn().unwrap();
        assert_eq!(g.hp, 70);
        assert_eq!(g.block, 0);
    }
    #[test]
    fn ecology_only_triggers_once_per_turn() {
        let mut g = battle();
        hand(&mut g, &[15, 22, 22]);
        g.play(0, 0).unwrap();
        g.play(0, 0).unwrap();
        g.play(0, 0).unwrap();
        assert_eq!(g.block, 11);
        assert_eq!(g.exhaust.len(), 2);
    }
    #[test]
    fn motion_bonus_is_capped() {
        let mut g = battle();
        hand(&mut g, &[19]);
        g.amendments = 10;
        g.play(0, 0).unwrap();
        assert_eq!(g.total_damage, 28);
    }
    #[test]
    fn fourth_card_power_only_once() {
        let mut g = battle();
        hand(&mut g, &[21, 22, 22, 22, 22]);
        for _ in 0..5 {
            g.play(0, 0).unwrap();
        }
        assert_eq!(g.total_damage, 8);
    }
    #[test]
    fn hand_limit_and_reshuffle_preserve_cards() {
        let mut g = battle();
        for _ in 0..12 {
            g.add_hand(22);
        }
        assert_eq!(g.hand.len(), 10);
        assert_eq!(g.discard.len(), 2);
        g.end_turn().unwrap();
        assert_eq!(g.hand.len() + g.draw.len() + g.discard.len(), 12);
    }
    #[test]
    fn scry_requires_choice_then_returns_unselected_to_bottom() {
        let mut g = battle();
        hand(&mut g, &[16]);
        for id in [0, 1, 2, 3] {
            let c = g.make(id);
            g.draw.push(c);
        }
        g.play(0, 0).unwrap();
        assert_eq!(g.choices.len(), 3);
        assert!(g.end_turn().is_err());
        let id = g.choices[1].uid;
        g.choose(1).unwrap();
        assert!(g.hand.iter().any(|c| c.uid == id));
        assert_eq!(g.draw.len(), 3);
        assert_eq!(g.pending, "");
    }
    #[test]
    fn foulard_exhausts_status_and_draws() {
        let mut g = battle();
        hand(&mut g, &[12, 23]);
        let c = g.make(0);
        g.draw.push(c);
        g.play(0, 0).unwrap();
        g.choose(0).unwrap();
        assert_eq!(g.exhaust.len(), 2);
        assert_eq!(g.hand.len(), 2);
        assert_eq!(g.hand[0].id, 22);
    }
    #[test]
    fn noise_is_ethereal_but_unplayed_amendment_is_not() {
        let mut g = battle();
        hand(&mut g, &[23, 22]);
        assert!(g.play(0, 0).is_err());
        g.end_turn().unwrap();
        assert_eq!(g.exhaust.len(), 1);
        assert_eq!(g.exhaust[0].id, 23);
        assert!(g.hand.iter().any(|c| c.id == 22));
    }
    #[test]
    fn rewards_and_rest_are_single_use() {
        let mut g = battle();
        g.enemies[0].hp = 1;
        hand(&mut g, &[0]);
        g.play(0, 0).unwrap();
        assert_eq!(g.phase, "reward");
        g.reward(0).unwrap();
        assert_eq!(g.deck.len(), 11);
        assert!(g.reward(0).is_err());
        g.floor = 2;
        g.hp = 30;
        g.enter(0).unwrap();
        g.rest(-1).unwrap();
        assert_eq!(g.hp, 54);
        assert_eq!(g.floor, 3);
        assert!(g.rest(-1).is_err());
    }
    #[test]
    fn save_round_trip_and_corruption() {
        let g = Game::new(183);
        let code = g.save();
        let restored = Game::load(&code).unwrap();
        assert_eq!(restored.save(), code);
        assert!(Game::load("bad").is_err());
        assert!(Game::load(&code.replace("0:0", "99:0")).is_err());
    }
    #[test]
    fn lethal_damage_stops_enemy_sequence() {
        let mut g = battle();
        g.hp = 1;
        g.end_turn().unwrap();
        assert_eq!(g.phase, "lost");
        assert_eq!(g.hp, 0);
        assert_eq!(g.turn, 1);
    }
    #[test]
    fn duplicate_power_is_unique_and_can_be_upgraded() {
        let mut g = battle();
        hand(&mut g, &[15, 15]);
        g.hand[1].plus = true;
        g.play(0, 0).unwrap();
        g.play(0, 0).unwrap();
        assert_eq!(g.powers.len(), 1);
        assert!(g.powers[0].plus);
    }
    #[test]
    fn president_does_not_retroactively_trigger() {
        let mut g = battle();
        hand(&mut g, &[1, 1, 10]);
        g.play(0, 0).unwrap();
        g.play(0, 0).unwrap();
        g.play(0, 0).unwrap();
        assert!(g.hand.is_empty());
    }
    #[test]
    fn all_catalog_cards_resolve_without_panics() {
        for id in 0..23 {
            let mut g = battle();
            hand(&mut g, &[id, 0, 1, 23]);
            g.energy = 9;
            g.play(0, 0).unwrap();
            if !g.pending.is_empty() {
                g.choose(0).unwrap();
            }
            g.end_turn().unwrap();
            assert!(g.hp >= 0);
        }
    }
}
