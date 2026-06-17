use shakmaty::{fen::Fen, CastlingMode, Chess, Color, Move, Position, Square, Role};

pub struct PersonaCandidate {
    pub uci_move: String,
    pub evaluation: f64,
}

fn simple_hash(s: &str) -> u64 {
    let mut hash: u64 = 5381;
    for c in s.chars() {
        hash = ((hash << 5).wrapping_add(hash)).wrapping_add(c as u64);
    }
    hash
}

fn get_jitter_amount(hash: u64, range: u64, offset: f64) -> f64 {
    if cfg!(test) {
        0.0
    } else {
        ((hash % range) as f64 / 100.0) - offset
    }
}

fn is_endgame(pos: &Chess) -> bool {
    let mut piece_count = 0;
    for sq in Square::ALL {
        if let Some(p) = pos.board().piece_at(sq) {
            if p.role != Role::Pawn && p.role != Role::King {
                piece_count += 1;
            }
        }
    }
    piece_count <= 6
}

fn is_closed_file(file: shakmaty::File, pos: &Chess) -> bool {
    let mut white_pawn = false;
    let mut black_pawn = false;
    for rank in shakmaty::Rank::ALL {
        let sq = Square::from_coords(file, rank);
        if let Some(p) = pos.board().piece_at(sq) {
            if p.role == Role::Pawn {
                if p.color == Color::White {
                    white_pawn = true;
                } else {
                    black_pawn = true;
                }
            }
        }
    }
    white_pawn && black_pawn
}

fn is_open_file(file: shakmaty::File, pos: &Chess) -> bool {
    for rank in shakmaty::Rank::ALL {
        let sq = Square::from_coords(file, rank);
        if let Some(p) = pos.board().piece_at(sq) {
            if p.role == Role::Pawn {
                return false;
            }
        }
    }
    true
}

fn attacks_high_value_piece(pos: &Chess, m: &Option<Move>, opponent_color: Color) -> bool {
    let m = match m {
        Some(mv) => mv,
        None => return false,
    };
    let mut sandbox = pos.clone();
    sandbox.play_unchecked(m);

    let turn_color = pos.turn();

    for sq in Square::ALL {
        if sq == m.to() {
            continue;
        }
        if let Some(p) = pos.board().piece_at(sq) {
            if p.color == opponent_color && (p.role == Role::Rook || p.role == Role::Queen) {
                let attacked_before = !pos.board().attacks_to(sq, turn_color, pos.board().occupied()).is_empty();
                let attacked_after = !sandbox.board().attacks_to(sq, turn_color, sandbox.board().occupied()).is_empty();
                if !attacked_before && attacked_after {
                    return true;
                }
            }
        }
    }
    false
}

fn restricts_opponent_mobility(pos: &Chess, m: &Option<Move>) -> bool {
    let m = match m {
        Some(mv) => mv,
        None => return false,
    };
    let mut sandbox = pos.clone();
    sandbox.play_unchecked(m);
    
    let opponent_moves_count = sandbox.legal_moves().len();
    opponent_moves_count < 20
}

fn shakmaty_move_to_uci(m: &Move, is_chess960: bool) -> String {
    match m {
        Move::Normal { from, to, promotion, .. } => {
            let promo_str = match promotion {
                Some(Role::Queen) => "q",
                Some(Role::Rook) => "r",
                Some(Role::Bishop) => "b",
                Some(Role::Knight) => "n",
                _ => "",
            };
            format!("{}{}{}", from.to_string(), to.to_string(), promo_str)
        }
        Move::EnPassant { from, to } => {
            format!("{}{}", from.to_string(), to.to_string())
        }
        Move::Castle { king, rook } => {
            if is_chess960 {
                format!("{}{}", king.to_string(), rook.to_string())
            } else {
                let is_white = king.rank() == shakmaty::Rank::First;
                let is_kingside = rook.file() > king.file();
                let dest_file = if is_kingside { shakmaty::File::G } else { shakmaty::File::C };
                let dest_rank = if is_white { shakmaty::Rank::First } else { shakmaty::Rank::Eighth };
                let dest_sq = Square::from_coords(dest_file, dest_rank);
                format!("{}{}", king.to_string(), dest_sq.to_string())
            }
        }
        Move::Put { to, role } => {
            let role_char = match role {
                Role::Queen => 'q',
                Role::Rook => 'r',
                Role::Bishop => 'b',
                Role::Knight => 'n',
                Role::Pawn => 'p',
                Role::King => 'k',
            };
            format!("{}@{}", role_char, to.to_string())
        }
    }
}

pub struct PersonaConfig {
    pub multi_pv: i32,
    pub skill_level: i32,
    pub depth: i32,
}

#[flutter_rust_bridge::frb(sync)]
pub fn get_persona_config(avatar_name: String) -> PersonaConfig {
    match avatar_name.as_str() {
        "Sparky" => PersonaConfig { multi_pv: 45, skill_level: 0, depth: 1 },
        "Pawzy" | "Pawnzy" => PersonaConfig { multi_pv: 30, skill_level: 1, depth: 2 },
        "Coward" => PersonaConfig { multi_pv: 20, skill_level: 2, depth: 3 },
        "Rookie" | "Rook-ie" => PersonaConfig { multi_pv: 15, skill_level: 3, depth: 5 },
        "Scholar" => PersonaConfig { multi_pv: 12, skill_level: 4, depth: 6 },
        "Molly" => PersonaConfig { multi_pv: 10, skill_level: 5, depth: 7 },
        "Berserker" | "Berkserker" => PersonaConfig { multi_pv: 10, skill_level: 6, depth: 8 },
        "Blaire" => PersonaConfig { multi_pv: 8, skill_level: 7, depth: 9 },
        "Python" => PersonaConfig { multi_pv: 4, skill_level: 8, depth: 10 },
        "Gambit" => PersonaConfig { multi_pv: 4, skill_level: 9, depth: 11 },
        "Trapper" => PersonaConfig { multi_pv: 4, skill_level: 10, depth: 12 },
        "Assassin" => PersonaConfig { multi_pv: 4, skill_level: 11, depth: 13 },
        "Vala" => PersonaConfig { multi_pv: 4, skill_level: 12, depth: 14 },
        "Magician" => PersonaConfig { multi_pv: 3, skill_level: 13, depth: 15 },
        "Sentinel" => PersonaConfig { multi_pv: 2, skill_level: 14, depth: 16 },
        "Murphy" => PersonaConfig { multi_pv: 2, skill_level: 16, depth: 17 },
        "Titan" => PersonaConfig { multi_pv: 1, skill_level: 18, depth: 18 },
        "Alien" => PersonaConfig { multi_pv: 12, skill_level: 18, depth: 19 },
        "Champ" => PersonaConfig { multi_pv: 1, skill_level: 18, depth: 20 },
        "King" | "Kingslayer" => PersonaConfig { multi_pv: 1, skill_level: 20, depth: 22 },
        _ => PersonaConfig { multi_pv: 4, skill_level: 10, depth: 8 }, // Default fallback
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn select_persona_move_rust(
    fen: String,
    candidates: Vec<PersonaCandidate>,
    avatar_name: String,
    is_chess960: bool,
    move_count: i32,
) -> String {
    if candidates.is_empty() {
        return "".to_string();
    }
    if avatar_name == "Kingslayer" || avatar_name == "King" {
        return candidates[0].uci_move.clone();
    }

    let mode = if is_chess960 {
        CastlingMode::Chess960
    } else {
        CastlingMode::Standard
    };

    let setup = match fen.parse::<Fen>() {
        Ok(f) => f,
        Err(_) => return candidates[0].uci_move.clone(),
    };

    let initial_pos: Chess = match setup.into_position(mode) {
        Ok(p) => p,
        Err(_) => return candidates[0].uci_move.clone(),
    };

    #[cfg(not(test))]
    let random_prob = match avatar_name.as_str() {
        "Sparky" => 75.0,
        "Pawzy" | "Pawnzy" => 35.0,
        "Coward" => 15.0,
        "Rookie" | "Rook-ie" => 5.0,
        _ => 0.0,
    };
    #[cfg(test)]
    let random_prob = 0.0;

    if random_prob > 0.0 {
        let turn_hash = simple_hash(&(fen.clone() + &move_count.to_string()));
        let roll = (turn_hash % 1000000) as f64 / 10000.0;
        if roll < random_prob {
            let legal_moves = initial_pos.legal_moves();
            if !legal_moves.is_empty() {
                let move_seed = simple_hash(&(fen.clone() + "move" + &move_count.to_string()));
                let index = (move_seed as usize) % legal_moves.len();
                let chosen_move = &legal_moves[index];
                let uci = shakmaty_move_to_uci(chosen_move, is_chess960);
                #[cfg(debug_assertions)]
                println!("🎲 [Rust Randomizer] {} triggered random move: {} (roll: {}, prob: {})", avatar_name, uci, roll, random_prob);
                return uci;
            }
        }
    }

    let turn_color = initial_pos.turn();
    let opponent_color = !turn_color;

    let gate_threshold = match avatar_name.as_str() {
        "Sparky" => 9999.0, // practically no gate
        "Pawzy" | "Pawnzy" => 5.0,
        "Coward" => 3.0,
        "Rookie" | "Rook-ie" => 2.0,
        "Scholar" => 1.2,
        "Molly" => 1.0,
        "Berserker" | "Berkserker" => 0.9,
        "Blaire" => 0.6,
        "Python" => 0.4,
        "Gambit" => 0.5,
        "Trapper" => 0.4,
        "Assassin" => 0.35,
        "Vala" => 0.3,
        "Magician" => 0.25,
        "Sentinel" => 0.2,
        "Murphy" => 0.15,
        "Titan" => 0.1,
        "Alien" => 0.3,
        "Champ" => 0.05,
        _ => 9999.0,
    };

    let mut best_move = candidates[0].uci_move.clone();
    let mut max_adjusted_score = -99999.0;

    for candidate in &candidates {
        if candidate.uci_move.len() < 4 {
            continue;
        }
        let from_str = &candidate.uci_move[0..2];
        let to_str = &candidate.uci_move[2..4];
        let promo_str = if candidate.uci_move.len() >= 5 { &candidate.uci_move[4..5] } else { "" };

        let from_sq: Square = match from_str.parse() {
            Ok(sq) => sq,
            Err(_) => continue,
        };
        let to_sq: Square = match to_str.parse() {
            Ok(sq) => sq,
            Err(_) => continue,
        };

        let promo_role = match promo_str.chars().next() {
            Some('q') => Some(Role::Queen),
            Some('r') => Some(Role::Rook),
            Some('b') => Some(Role::Bishop),
            Some('n') => Some(Role::Knight),
            _ => None,
        };

        let mut found_move = None;
        for m in initial_pos.legal_moves() {
            if m.from() == Some(from_sq) {
                let m_to = m.to();
                let matches_dest = m_to == to_sq;
                let matches_castle = match &m {
                    Move::Castle { king: _, rook } => *rook == to_sq || m_to == to_sq,
                    _ => false,
                };
                let matches_promo = match &m {
                    Move::Normal { promotion, .. } => *promotion == promo_role,
                    _ => promo_role.is_none(),
                };
                if (matches_dest || matches_castle) && matches_promo {
                    found_move = Some(m);
                    break;
                }
            }
        }

        let mut weight = 0.0;
        let piece = initial_pos.board().piece_at(from_sq);
        let target_piece = initial_pos.board().piece_at(to_sq);

        let best_eval = candidates[0].evaluation;
        let eval_drop = best_eval - candidate.evaluation;
        if eval_drop > gate_threshold {
            weight -= 9999.0;
        }

        if avatar_name == "Sparky" {
            let hash = simple_hash(&(candidate.uci_move.clone() + &fen));
            let jitter = get_jitter_amount(hash, 16000, 80.0);
            weight += jitter;
        } else if avatar_name == "Pawzy" || avatar_name == "Pawnzy" {
            if let Some(p) = piece {
                if p.role == Role::Pawn {
                    weight += 2.0;
                } else if p.role != Role::King {
                    weight -= 1.5;
                }
            }
            let hash = simple_hash(&(candidate.uci_move.clone() + &fen));
            let jitter = get_jitter_amount(hash, 6000, 30.0);
            weight += jitter;
        } else if avatar_name == "Rook-ie" || avatar_name == "Rookie" {
            if target_piece.is_some() {
                if initial_pos.board().attacks_to(to_sq, opponent_color, initial_pos.board().occupied()).is_empty() {
                    weight += 2.0;
                } else {
                    weight += 0.5;
                }
            }
            let hash = simple_hash(&(candidate.uci_move.clone() + &fen));
            let jitter = get_jitter_amount(hash, 1200, 6.0);
            weight += jitter;
        } else if avatar_name == "Molly" {
            if let Some(p) = piece {
                if p.role == Role::Pawn {
                    let from_rank = from_sq.rank() as i32;
                    let to_rank = to_sq.rank() as i32;
                    if (to_rank - from_rank).abs() <= 1 {
                        weight += 0.6;
                    }
                }
            }
            if target_piece.is_some() {
                let is_end = is_endgame(&initial_pos);
                let bypass = candidate.evaluation > 5.0 || candidate.evaluation >= 90.0 || (candidate.evaluation > -10.0 && candidates.iter().any(|c| c.evaluation <= -90.0));
                if !bypass {
                    weight -= if is_end { 0.3 } else { 1.5 };
                }
            }
            if is_closed_file(to_sq.file(), &initial_pos) {
                weight += 0.4;
            }
            let to_rank_val = to_sq.rank() as i32 + 1;
            if turn_color == Color::White {
                if to_rank_val > 4 {
                    weight -= 0.3;
                }
            } else {
                if to_rank_val < 5 {
                    weight -= 0.3;
                }
            }
            let hash = simple_hash(&(candidate.uci_move.clone() + &fen));
            let jitter = get_jitter_amount(hash, 250, 1.25);
            weight += jitter;
        } else if avatar_name == "Blaire" {
            if let Some(p) = piece {
                if p.role == Role::Knight || p.role == Role::Bishop {
                    weight += 0.8;
                }
            }
            if let Some(m) = &found_move {
                let mut sandbox = initial_pos.clone();
                sandbox.play_unchecked(m);
                if sandbox.is_check() {
                    weight += 0.6;
                }
            }
            if attacks_high_value_piece(&initial_pos, &found_move, opponent_color) {
                weight += 0.5;
            }
            let from_rank = from_sq.rank() as i32;
            let to_rank = to_sq.rank() as i32;
            if turn_color == Color::White {
                if to_rank < from_rank {
                    weight -= 0.4;
                }
            } else {
                if to_rank > from_rank {
                    weight -= 0.4;
                }
            }
            if let Some(king_sq) = initial_pos.board().king_of(opponent_color) {
                let from_file_idx = to_sq.file() as i32;
                let from_rank_idx = to_sq.rank() as i32;
                let king_file_idx = king_sq.file() as i32;
                let king_rank_idx = king_sq.rank() as i32;
                let distance = (((from_file_idx - king_file_idx).pow(2) + (from_rank_idx - king_rank_idx).pow(2)) as f64).sqrt();
                weight += (10.0 - distance).max(0.0) * 0.15;
            }
            let hash = simple_hash(&(candidate.uci_move.clone() + &fen));
            let jitter = get_jitter_amount(hash, 100, 0.5);
            weight += jitter;
        } else if avatar_name == "Gambit" {
            let best_eval = candidates[0].evaluation;
            let eval_drop = best_eval - candidate.evaluation;
            if eval_drop > 0.5 && eval_drop < 4.0 && (target_piece.is_some() || piece.map_or(false, |p| p.role == Role::Pawn)) {
                weight += 2.5;
            }
            let hash = simple_hash(&(candidate.uci_move.clone() + &fen));
            let jitter = get_jitter_amount(hash, 30, 0.15);
            weight += jitter;
        } else if avatar_name == "Vala" {
            if let Some(m) = &found_move {
                let mut sandbox = initial_pos.clone();
                sandbox.play_unchecked(m);
                if sandbox.is_check() {
                    weight += 0.7;
                }

                // Check for fork (attacking >=2 non-pawn opponent pieces)
                let mut attack_count = 0;
                for sq in Square::ALL {
                    if let Some(target) = sandbox.board().piece_at(sq) {
                        if target.color == opponent_color && target.role != Role::Pawn {
                            let is_atk = !sandbox.board().attacks_to(sq, turn_color, sandbox.board().occupied()).is_empty();
                            if is_atk {
                                attack_count += 1;
                            }
                        }
                    }
                }
                if attack_count >= 2 {
                    weight += 1.0;
                }
            }
            if target_piece.is_some() && candidate.evaluation > 0.0 {
                weight += 0.5;
            }
            let hash = simple_hash(&(candidate.uci_move.clone() + &fen));
            let jitter = get_jitter_amount(hash, 12, 0.06);
            weight += jitter;
        } else if avatar_name == "Sentinel" {
            let file = to_sq.file();
            let rank = to_sq.rank();
            let is_center_file = file == shakmaty::File::C || file == shakmaty::File::D || file == shakmaty::File::E || file == shakmaty::File::F;
            let is_center_rank = rank == shakmaty::Rank::Fourth || rank == shakmaty::Rank::Fifth;
            if is_center_file && is_center_rank {
                weight += 0.8;
            }
            if initial_pos.board().attacks_to(to_sq, opponent_color, initial_pos.board().occupied()).is_empty() {
                weight += 0.5;
            }
            if let Some(p) = piece {
                if p.role == Role::Knight {
                    let is_central = (file == shakmaty::File::C || file == shakmaty::File::D || file == shakmaty::File::E || file == shakmaty::File::F) &&
                                     (rank == shakmaty::Rank::Fourth || rank == shakmaty::Rank::Fifth || rank == shakmaty::Rank::Sixth);
                    if is_central {
                        if let Some(m) = &found_move {
                            let mut sandbox = initial_pos.clone();
                            sandbox.play_unchecked(m);
                            let is_defended_by_pawn = !((sandbox.board().by_color(turn_color) & sandbox.board().by_role(Role::Pawn)) & sandbox.board().attacks_to(to_sq, turn_color, sandbox.board().occupied())).is_empty();
                            if is_defended_by_pawn {
                                weight += 1.5;
                            }
                        }
                    }
                }
            }
            if restricts_opponent_mobility(&initial_pos, &found_move) {
                weight += 0.8;
            }
            let hash = simple_hash(&(candidate.uci_move.clone() + &fen));
            let jitter = get_jitter_amount(hash, 6, 0.03);
            weight += jitter;
        } else if avatar_name == "Murphy" {
            let file = to_sq.file();
            if let Some(p) = piece {
                if (p.role == Role::Rook || p.role == Role::Queen) && is_open_file(file, &initial_pos) {
                    weight += 1.0;
                }
                if move_count < 20 && (p.role == Role::Knight || p.role == Role::Bishop) {
                    weight += 1.0;
                }
                if p.role == Role::Rook {
                    let mut has_other = false;
                    for rank in shakmaty::Rank::ALL {
                        let sq = Square::from_coords(file, rank);
                        if sq != from_sq {
                            if let Some(other_p) = initial_pos.board().piece_at(sq) {
                                if other_p.color == turn_color && (other_p.role == Role::Rook || other_p.role == Role::Queen) {
                                    has_other = true;
                                    break;
                                }
                            }
                        }
                    }
                    if has_other {
                        weight += 1.5;
                    }
                }
            }
            let hash = simple_hash(&(candidate.uci_move.clone() + &fen));
            let jitter = get_jitter_amount(hash, 4, 0.02);
            weight += jitter;
        } else if avatar_name == "Coward" {
            let is_retreat = if turn_color == Color::White {
                to_sq.rank() < from_sq.rank()
            } else {
                to_sq.rank() > from_sq.rank()
            };
            if is_retreat {
                weight += 1.2;
            }
            if let Some(Move::Castle { .. }) = found_move {
                weight += 1.5;
            }
            let mut is_defended = false;
            if let Some(m) = &found_move {
                let mut sandbox = initial_pos.clone();
                sandbox.play_unchecked(m);
                if sandbox.is_check() {
                    weight -= 0.8;
                }
                is_defended = !sandbox.board().attacks_to(to_sq, turn_color, sandbox.board().occupied()).is_empty();
            }
            if is_defended {
                weight += 1.0;
            }
            if let Some(p) = piece {
                if p.role == Role::Pawn {
                    let to_rank = to_sq.rank() as i32 + 1;
                    let is_advanced = if turn_color == Color::White { to_rank > 4 } else { to_rank < 5 };
                    if !is_advanced {
                        weight += 0.8;
                    }
                }
            }
            if target_piece.is_some() {
                weight -= 0.5;
            }
            let to_rank = to_sq.rank() as i32 + 1;
            let is_deep = if turn_color == Color::White { to_rank >= 5 } else { to_rank <= 4 };
            if is_deep {
                weight -= 1.0;
            }
            let hash = simple_hash(&(candidate.uci_move.clone() + &fen));
            let jitter = get_jitter_amount(hash, 2000, 10.0);
            weight += jitter;
        } else if avatar_name == "Scholar" {
            if move_count < 15 {
                if let Some(p) = piece {
                    if p.role == Role::Queen || p.role == Role::Bishop {
                        let is_target = matches!(
                            to_sq,
                            Square::F3 | Square::H5 | Square::C4 | Square::F6 | Square::H4 | Square::C5
                        );
                        if is_target {
                            weight += 1.5;
                        }
                    }
                }
            }
            let target_f_square = if turn_color == Color::White { Square::F7 } else { Square::F2 };
            if to_sq == target_f_square {
                if let Some(p) = piece {
                    if p.role == Role::Queen || p.role == Role::Bishop {
                        weight += 2.0;
                    }
                }
            }
            if let Some(m) = &found_move {
                let mut sandbox = initial_pos.clone();
                sandbox.play_unchecked(m);
                if sandbox.is_check() {
                    weight += 1.0;
                }
            }
            if attacks_high_value_piece(&initial_pos, &found_move, opponent_color) {
                weight += 0.8;
            }
            let hash = simple_hash(&(candidate.uci_move.clone() + &fen));
            let jitter = get_jitter_amount(hash, 400, 2.0);
            weight += jitter;
        } else if avatar_name == "Berserker" || avatar_name == "Berkserker" {
            if let Some(king_sq) = initial_pos.board().king_of(opponent_color) {
                let df = (to_sq.file() as i32 - king_sq.file() as i32).abs();
                let dr = (to_sq.rank() as i32 - king_sq.rank() as i32).abs();
                let proximity = (14.0 - (df + dr) as f64) / 14.0;
                weight += proximity * 1.5;
            }
            if let Some(m) = &found_move {
                let mut sandbox = initial_pos.clone();
                sandbox.play_unchecked(m);
                if sandbox.is_check() {
                    weight += 1.2;
                }
            }
            let best_eval = candidates[0].evaluation;
            let eval_drop = best_eval - candidate.evaluation;
            if eval_drop > 0.5 && eval_drop < 3.0 && target_piece.is_some() {
                weight += 1.8;
            }
            let hash = simple_hash(&(candidate.uci_move.clone() + &fen));
            let jitter = get_jitter_amount(hash, 160, 0.8);
            weight += jitter;
        } else if avatar_name == "Python" {
            if restricts_opponent_mobility(&initial_pos, &found_move) {
                weight += 1.0;
            }
            if let Some(p) = piece {
                if p.role == Role::Knight || p.role == Role::Bishop {
                    let file = to_sq.file();
                    let rank = to_sq.rank();
                    let is_center_file = file == shakmaty::File::D || file == shakmaty::File::E;
                    let is_center_rank = rank == shakmaty::Rank::Fourth || rank == shakmaty::Rank::Fifth;
                    if is_center_file && is_center_rank {
                        weight += 0.8;
                    }
                }
            }
            if let Some(p) = piece {
                if p.role == Role::Pawn {
                    if let Some(m) = &found_move {
                        let mut sandbox = initial_pos.clone();
                        sandbox.play_unchecked(m);
                        let is_defended = !sandbox.board().attacks_to(to_sq, turn_color, sandbox.board().occupied()).is_empty();
                        if is_defended {
                            weight += 0.5;
                        }
                    }

                    let rank_val = to_sq.rank() as i32 + 1;
                    let is_wedge = if turn_color == Color::White {
                        rank_val == 5 || rank_val == 6
                    } else {
                        rank_val == 4 || rank_val == 3
                    };
                    if is_wedge {
                        if let Some(m) = &found_move {
                            let mut sandbox = initial_pos.clone();
                            sandbox.play_unchecked(m);
                            let is_defended_by_pawn = !((sandbox.board().by_color(turn_color) & sandbox.board().by_role(Role::Pawn)) & sandbox.board().attacks_to(to_sq, turn_color, sandbox.board().occupied())).is_empty();
                            if is_defended_by_pawn {
                                weight += 1.0;
                            }
                        }
                    }
                }
            }
            let file = to_sq.file();
            if is_open_file(file, &initial_pos) {
                weight -= 0.5;
            }
            let best_eval = candidates[0].evaluation;
            if best_eval - candidate.evaluation > 0.8 {
                weight -= 2.0;
            }
            let hash = simple_hash(&(candidate.uci_move.clone() + &fen));
            let jitter = get_jitter_amount(hash, 40, 0.2);
            weight += jitter;
        } else if avatar_name == "Trapper" {
            let best_eval = candidates[0].evaluation;
            let eval_drop = best_eval - candidate.evaluation;
            if eval_drop > 0.3 && eval_drop < 1.5 && target_piece.is_some() {
                weight += 1.5;
            }
            if let Some(p) = piece {
                if p.role == Role::Knight || p.role == Role::Bishop || p.role == Role::Rook || p.role == Role::Queen {
                    if let Some(m) = &found_move {
                        let mut sandbox = initial_pos.clone();
                        sandbox.play_unchecked(m);
                        let mut attack_count = 0;
                        for sq in Square::ALL {
                            if let Some(target) = sandbox.board().piece_at(sq) {
                                if target.color == opponent_color && target.role != Role::Pawn {
                                    let is_atk = !sandbox.board().attacks_to(sq, turn_color, sandbox.board().occupied()).is_empty();
                                    if is_atk {
                                        attack_count += 1;
                                    }
                                }
                            }
                        }
                        if attack_count >= 2 {
                            weight += if p.role == Role::Queen { 1.2 } else { 0.8 };
                        }
                    }
                }
            }
            let hash = simple_hash(&(candidate.uci_move.clone() + &fen));
            let jitter = get_jitter_amount(hash, 20, 0.1);
            weight += jitter;
        } else if avatar_name == "Assassin" {
            if let Some(king_sq) = initial_pos.board().king_of(opponent_color) {
                let is_adjacent = (to_sq.file() as i32 - king_sq.file() as i32).abs() <= 1
                    && (to_sq.rank() as i32 - king_sq.rank() as i32).abs() <= 1;
                if is_adjacent {
                    weight += 1.0;
                }
            }
            if let Some(p) = piece {
                if p.role == Role::Pawn {
                    let file = to_sq.file();
                    if file == shakmaty::File::D || file == shakmaty::File::E {
                        weight += 0.8;
                    }

                    if let Some(king_sq) = initial_pos.board().king_of(opponent_color) {
                        let file_dist = (to_sq.file() as i32 - king_sq.file() as i32).abs();
                        let rank_dist = (to_sq.rank() as i32 - king_sq.rank() as i32).abs();
                        if file_dist <= 2 && rank_dist <= 2 {
                            if let Some(m) = &found_move {
                                let mut sandbox = initial_pos.clone();
                                sandbox.play_unchecked(m);
                                let attacked_pawns = !((sandbox.board().by_color(opponent_color) & sandbox.board().by_role(Role::Pawn)) & sandbox.board().attacks_to(to_sq, turn_color, sandbox.board().occupied())).is_empty();
                                if attacked_pawns {
                                    weight += 1.2;
                                }
                            }
                        }
                    }
                }
            }
            let best_eval = candidates[0].evaluation;
            let eval_drop = best_eval - candidate.evaluation;
            if eval_drop > 0.5 && eval_drop < 2.5 {
                if let Some(king_sq) = initial_pos.board().king_of(opponent_color) {
                    let file_dist = (to_sq.file() as i32 - king_sq.file() as i32).abs();
                    let rank_dist = (to_sq.rank() as i32 - king_sq.rank() as i32).abs();
                    if file_dist <= 2 && rank_dist <= 2 {
                        weight += 1.5;
                    }
                }
            }
            let hash = simple_hash(&(candidate.uci_move.clone() + &fen));
            let jitter = get_jitter_amount(hash, 16, 0.08);
            weight += jitter;
        } else if avatar_name == "Magician" {
            let best_eval = candidates[0].evaluation;
            let eval_drop = best_eval - candidate.evaluation;
            if eval_drop > 0.5 && eval_drop < 3.5 {
                if let Some(m) = &found_move {
                    let mut sandbox = initial_pos.clone();
                    sandbox.play_unchecked(m);

                    let mut attack_count = 0;
                    for sq in Square::ALL {
                        if let Some(target) = sandbox.board().piece_at(sq) {
                            if target.color == opponent_color {
                                let is_atk = !sandbox.board().attacks_to(sq, turn_color, sandbox.board().occupied()).is_empty();
                                if is_atk {
                                    attack_count += 1;
                                }
                            }
                        }
                    }
                    if attack_count >= 2 || sandbox.is_check() {
                        weight += 2.5;
                    }
                }
            }
            if let Some(m) = &found_move {
                let mut sandbox = initial_pos.clone();
                sandbox.play_unchecked(m);
                if sandbox.is_check() {
                    weight += 1.0;
                }
            }
            let hash = simple_hash(&(candidate.uci_move.clone() + &fen));
            let jitter = get_jitter_amount(hash, 10, 0.05);
            weight += jitter;
        } else if avatar_name == "Titan" {
            let file = to_sq.file();
            let rank = to_sq.rank();
            let is_center_file = file == shakmaty::File::D || file == shakmaty::File::E;
            let is_center_rank = rank == shakmaty::Rank::Fourth || rank == shakmaty::Rank::Fifth;
            if is_center_file && is_center_rank {
                weight += 0.3;
            }
        } else if avatar_name == "Alien" {
            let best_eval = candidates[0].evaluation;
            let eval_drop = best_eval - candidate.evaluation;
            if eval_drop < 0.3 {
                let hash = simple_hash(&(candidate.uci_move.clone() + &fen));
                let jitter = get_jitter_amount(hash, 100, 0.5);
                weight += jitter;

                if move_count >= 10 && move_count <= 30 {
                    if let Some(p) = piece {
                        if p.role == Role::Pawn {
                            let file = to_sq.file();
                            if file == shakmaty::File::A || file == shakmaty::File::H {
                                weight += 1.5;
                            }
                        }
                    }
                }
                if move_count >= 10 && move_count <= 35 {
                    if let Some(p) = piece {
                        if p.role == Role::King {
                            weight += 1.2;
                        }
                        if p.role == Role::Bishop && to_sq.rank() == if turn_color == Color::White { shakmaty::Rank::First } else { shakmaty::Rank::Eighth } {
                            weight += 1.0;
                        }
                    }
                }
            } else {
                weight -= 9999.0;
            }
        } else if avatar_name == "Champ" {
            let best_eval = candidates[0].evaluation;
            let eval_drop = best_eval - candidate.evaluation;
            if eval_drop <= 0.05 {
                weight += 0.1;
            }
        }

        let score = candidate.evaluation + weight;
        if score > max_adjusted_score {
            max_adjusted_score = score;
            best_move = candidate.uci_move.clone();
        }
    }

    best_move
}


#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_coward_prefers_retreat() {
        // Position where a white knight is at e4
        // Legal moves could include moving knight forward (e.g. to f6, d6) or backward (e.g. to c3, d2, f2)
        // Candidates have similar evaluations
        let fen = "rnbqkbnr/pppp1ppp/8/8/4N3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 1".to_string();
        let candidates = vec![
            PersonaCandidate { uci_move: "e4c3".to_string(), evaluation: 0.2 }, // retreat
            PersonaCandidate { uci_move: "e4d6".to_string(), evaluation: 0.2 }, // forward
        ];
        let chosen = select_persona_move_rust(fen, candidates, "Coward".to_string(), false, 2);
        assert_eq!(chosen, "e4c3");
    }

    #[test]
    fn test_berserker_proximity_to_king() {
        // White knight at d4. Opponent king is at e8.
        // Moves: Nf5 (closer to e8), Nb3 (further from e8)
        let fen = "rnbqkbnr/pppp1ppp/8/8/3N4/8/PPPP1PPP/RNBQKBNR w KQkq - 0 1".to_string();
        let candidates = vec![
            PersonaCandidate { uci_move: "d4b3".to_string(), evaluation: 0.5 }, // further
            PersonaCandidate { uci_move: "d4f5".to_string(), evaluation: 0.5 }, // closer
        ];
        let chosen = select_persona_move_rust(fen, candidates, "Berserker".to_string(), false, 2);
        assert_eq!(chosen, "d4f5");
    }
}
