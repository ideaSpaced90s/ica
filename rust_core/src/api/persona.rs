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
    if avatar_name == "Kingslayer" {
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

    let turn_color = initial_pos.turn();
    let opponent_color = !turn_color;

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

        if avatar_name == "Sparky" {
            let hash = simple_hash(&(candidate.uci_move.clone() + &fen));
            let random_val = ((hash % 300) as f64 / 100.0) - 1.5; // -1.5 to +1.5
            weight += random_val;
        } else if avatar_name == "Pawnzy" {
            if let Some(p) = piece {
                if p.role == Role::Pawn {
                    weight += 1.5;
                }
            }
        } else if avatar_name == "Rook-ie" {
            if target_piece.is_some() {
                if initial_pos.board().attacks_to(to_sq, opponent_color, initial_pos.board().occupied()).is_empty() {
                    weight += 2.0;
                } else {
                    weight += 0.5;
                }
            }
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
        } else if avatar_name == "Gambit" {
            let best_eval = candidates[0].evaluation;
            let eval_drop = best_eval - candidate.evaluation;
            if eval_drop > 0.5 && eval_drop < 4.0 && (target_piece.is_some() || piece.map_or(false, |p| p.role == Role::Pawn)) {
                weight += 2.5;
            }
        } else if avatar_name == "Vala" {
            if let Some(m) = &found_move {
                let mut sandbox = initial_pos.clone();
                sandbox.play_unchecked(m);
                if sandbox.is_check() {
                    weight += 0.7;
                }
            }
            if target_piece.is_some() && candidate.evaluation > 0.0 {
                weight += 0.5;
            }
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
            if restricts_opponent_mobility(&initial_pos, &found_move) {
                weight += 0.8;
            }
        } else if avatar_name == "Murphy" {
            let file = to_sq.file();
            if let Some(p) = piece {
                if (p.role == Role::Rook || p.role == Role::Queen) && is_open_file(file, &initial_pos) {
                    weight += 1.0;
                }
                if move_count < 24 && (p.role == Role::Knight || p.role == Role::Bishop) {
                    weight += 0.6;
                }
            }
        } else if avatar_name == "Titan" {
            let file = to_sq.file();
            let rank = to_sq.rank();
            let is_center_file = file == shakmaty::File::D || file == shakmaty::File::E;
            let is_center_rank = rank == shakmaty::Rank::Fourth || rank == shakmaty::Rank::Fifth;
            if is_center_file && is_center_rank {
                weight += 0.3;
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
