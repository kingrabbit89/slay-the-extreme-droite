//! Immutable card catalogue. The rules crate has no Godot or platform dependency.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Kind {
    Attack,
    Skill,
    Power,
    Status,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Card {
    pub id: u8,
    pub plus: bool,
    pub uid: u32,
}

#[derive(Clone, Copy)]
pub struct Definition {
    pub name: &'static str,
    pub kind: Kind,
    pub cost: i32,
    pub rarity: &'static str,
    pub art: i32,
}

use Kind::*;
pub const CATALOG: [Definition; 24] = [
    Definition {
        name: "Intervention",
        kind: Attack,
        cost: 1,
        rarity: "Départ",
        art: 0,
    },
    Definition {
        name: "Tenir le rang",
        kind: Skill,
        cost: 1,
        rarity: "Départ",
        art: 5,
    },
    Definition {
        name: "Prendre la parole",
        kind: Attack,
        cost: 1,
        rarity: "Commune",
        art: 0,
    },
    Definition {
        name: "Amendement surprise",
        kind: Skill,
        cost: 1,
        rarity: "Commune",
        art: 1,
    },
    Definition {
        name: "Je demande la parole !",
        kind: Skill,
        cost: 0,
        rarity: "Commune",
        art: 2,
    },
    Definition {
        name: "Porte-à-porte",
        kind: Skill,
        cost: 1,
        rarity: "Commune",
        art: 3,
    },
    Definition {
        name: "Interpellation",
        kind: Attack,
        cost: 1,
        rarity: "Commune",
        art: 4,
    },
    Definition {
        name: "Rappel au règlement !",
        kind: Skill,
        cost: 1,
        rarity: "Commune",
        art: 5,
    },
    Definition {
        name: "Amendements en cascade",
        kind: Skill,
        cost: 1,
        rarity: "Commune",
        art: 6,
    },
    Definition {
        name: "Sortie tonitruante",
        kind: Attack,
        cost: 1,
        rarity: "Commune",
        art: 7,
    },
    Definition {
        name: "Présidente de groupe",
        kind: Power,
        cost: 1,
        rarity: "Peu commune",
        art: 8,
    },
    Definition {
        name: "Commission d'enquête",
        kind: Power,
        cost: 1,
        rarity: "Peu commune",
        art: 9,
    },
    Definition {
        name: "Le foulard à la tribune",
        kind: Skill,
        cost: 0,
        rarity: "Peu commune",
        art: 10,
    },
    Definition {
        name: "Question au gouvernement",
        kind: Attack,
        cost: 1,
        rarity: "Peu commune",
        art: 11,
    },
    Definition {
        name: "Le droit à l'eau",
        kind: Skill,
        cost: 1,
        rarity: "Peu commune",
        art: 12,
    },
    Definition {
        name: "Écologie populaire",
        kind: Power,
        cost: 1,
        rarity: "Peu commune",
        art: 13,
    },
    Definition {
        name: "Votation citoyenne",
        kind: Skill,
        cost: 1,
        rarity: "Peu commune",
        art: 14,
    },
    Definition {
        name: "Solidarité parlementaire",
        kind: Skill,
        cost: 1,
        rarity: "Peu commune",
        art: 15,
    },
    Definition {
        name: "Du tac au tac",
        kind: Attack,
        cost: 2,
        rarity: "Peu commune",
        art: 16,
    },
    Definition {
        name: "Motion de censure",
        kind: Attack,
        cost: 2,
        rarity: "Rare",
        art: 17,
    },
    Definition {
        name: "Article 34",
        kind: Power,
        cost: 2,
        rarity: "Rare",
        art: 18,
    },
    Definition {
        name: "La tribune ne se tait pas",
        kind: Power,
        cost: 2,
        rarity: "Rare",
        art: 19,
    },
    Definition {
        name: "Amendement",
        kind: Skill,
        cost: 0,
        rarity: "Temporaire",
        art: 6,
    },
    Definition {
        name: "Brouhaha",
        kind: Status,
        cost: -1,
        rarity: "Statut",
        art: 7,
    },
];

impl Card {
    pub fn def(&self) -> Definition {
        CATALOG[self.id as usize]
    }
    pub fn value(&self, base: i32, upgrade: i32) -> i32 {
        if self.plus { upgrade } else { base }
    }
    pub fn cost(&self) -> i32 {
        if self.id == 20 && self.plus {
            1
        } else {
            self.def().cost
        }
    }
    pub fn exhausts(&self) -> bool {
        matches!(self.id, 4 | 12 | 22 | 23)
    }
    pub fn title(&self) -> String {
        format!("{}{}", self.def().name, if self.plus { " +" } else { "" })
    }
    pub fn description(&self) -> String {
        let v = |a, b| self.value(a, b);
        match self.id {
            0 => format!("Inflige {} dégâts.", v(6, 9)),
            1 => format!("Gagne {} Bloc.", v(5, 8)),
            2 => format!(
                "Inflige {} dégâts.\n+3 si un Amendement a été joué ce tour.",
                v(7, 9)
            ),
            3 => format!("Gagne {} Bloc.\nAjoute 1 Amendement à la main.", v(5, 8)),
            4 => format!(
                "Pioche 1. Jouée en premier : ajoute 1 Amendement.{}\nÉpuisement.",
                if self.plus { " Gagne 3 Bloc." } else { "" }
            ),
            5 => format!(
                "Pioche 2, puis choisis 1 carte à défausser. Gagne {} Bloc.",
                v(4, 7)
            ),
            6 => format!(
                "Inflige {} dégâts. Si la cible attaque : 1 Faiblesse.",
                v(8, 11)
            ),
            7 => format!(
                "Gagne {} Bloc. Si une Compétence a déjà été jouée : 1 Faiblesse.",
                v(6, 9)
            ),
            8 => format!("Ajoute 2 Amendements à la main. Gagne {} Bloc.", v(2, 5)),
            9 => format!(
                "Inflige {} dégâts. Ajoute 1 Brouhaha à la défausse.",
                v(13, 16)
            ),
            10 => format!(
                "Chaque tour, à la 2e Compétence hors Amendement : ajoute 1 Amendement.{}",
                if self.plus { " +2 Bloc." } else { "" }
            ),
            11 => format!(
                "1 fois / tour : attaquer une cible altérée fait piocher 1 carte.{}",
                if self.plus { " +2 Bloc." } else { "" }
            ),
            12 => format!(
                "Épuise une autre carte. Ajoute 1 Amendement. Si Statut : pioche 1.{} Épuisement.",
                if self.plus { " +3 Bloc." } else { "" }
            ),
            13 => format!(
                "Inflige {} dégâts. Après 2 Compétences : 1 Vulnérable.",
                v(7, 10)
            ),
            14 => format!(
                "Gagne {} Bloc.\n+4 si un Amendement a été joué ce tour.",
                v(7, 10)
            ),
            15 => format!(
                "Le premier Épuisement de chaque tour fait gagner {} Bloc.",
                v(4, 6)
            ),
            16 => format!(
                "Choisis 1 des {} prochaines cartes. Replace les autres en bas. Ajoute 1 Amendement.",
                v(3, 4)
            ),
            17 => format!(
                "Gagne {} Bloc +3 par Compétence déjà jouée (bonus max. +9).",
                v(4, 6)
            ),
            18 => format!(
                "Inflige {} dégâts deux fois. Puis +5 si la cible est Affaiblie.",
                v(8, 10)
            ),
            19 => format!(
                "Inflige {} dégâts +4 par Amendement joué ce tour (bonus max. +16).",
                v(12, 15)
            ),
            20 => {
                "Début du tour : +1 Amendement. Le premier joué chaque tour donne +3 Bloc.".into()
            }
            21 => format!(
                "Chaque tour, jouer la 4e carte inflige {} dégâts à tous les ennemis.",
                v(8, 11)
            ),
            22 => "Gagne 2 Bloc.\nÉpuisement.\nCompte comme une carte jouée.".into(),
            _ => "Injouable.\nS'épuise si en main à la fin du tour.".into(),
        }
    }
}
