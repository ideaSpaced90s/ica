use shakmaty::{fen::Fen, CastlingMode, Chess, Position, Square};

#[flutter_rust_bridge::frb(sync)]
pub fn get_threatened_squares(fen: String) -> Vec<String> {
    // Parse the FEN string safely
    let setup = match fen.parse::<Fen>() {
        Ok(f) => f,
        Err(_) => return vec![],
    };

    let pos: Chess = match setup.into_position(CastlingMode::Standard) {
        Ok(p) => p,
        Err(_) => return vec![],
    };

    let turn = pos.turn();
    let opponent = !turn;
    let board = pos.board();
    let occupied = board.occupied();

    let mut threatened = Vec::new();

    // Iterate over all squares occupied by the current turn's pieces
    for sq in Square::ALL {
        if let Some(piece) = board.piece_at(sq) {
            if piece.color == turn {
                // Check if any opponent piece attacks this square
                let mut is_attacked = false;
                for attacker_sq in board.by_color(opponent) {
                    if let Some(attacker_piece) = board.piece_at(attacker_sq) {
                        let attacks = shakmaty::attacks::attacks(attacker_sq, attacker_piece, occupied);
                        if attacks.contains(sq) {
                            is_attacked = true;
                            break;
                        }
                    }
                }

                if is_attacked {
                    threatened.push(sq.to_string());
                }
            }
        }
    }

    threatened
}

#[flutter_rust_bridge::frb(sync)]
pub fn analyze_tactical_threats(fen: String) -> Vec<String> {
    let setup = match fen.parse::<Fen>() {
        Ok(f) => f,
        Err(_) => return vec![],
    };

    let pos: Chess = match setup.into_position(CastlingMode::Standard) {
        Ok(p) => p,
        Err(_) => return vec![],
    };

    let turn = pos.turn();
    let opponent = !turn;
    let board = pos.board();
    let occupied = board.occupied();

    let mut observations = Vec::new();

    // 1. Detect Pinned Pieces (to the King)
    if let Some(king_sq) = board.king_of(turn) {
        for sq in Square::ALL {
            if let Some(piece) = board.piece_at(sq) {
                if piece.color == turn && sq != king_sq {
                    // Temporarily remove piece at `sq`
                    let mut temp_board = board.clone();
                    let _ = temp_board.remove_piece_at(sq);
                    let temp_occupied = temp_board.occupied();

                    // Check if any opponent piece attacks the king now
                    for opp_sq in temp_board.by_color(opponent) {
                        if let Some(opp_piece) = temp_board.piece_at(opp_sq) {
                            let attacks = shakmaty::attacks::attacks(opp_sq, opp_piece, temp_occupied);
                            if attacks.contains(king_sq) {
                                // Double check if this opponent piece actually attacks the king *because* of the removal
                                // i.e., it wasn't already checking the king (otherwise it's not a pin, it's just check).
                                let original_attacks = shakmaty::attacks::attacks(opp_sq, opp_piece, occupied);
                                if !original_attacks.contains(king_sq) {
                                    observations.push(format!(
                                        "Your {} on {} is pinned to your King by the opponent's {} on {}.",
                                        format_role_name(piece.role),
                                        sq.to_string(),
                                        format_role_name(opp_piece.role),
                                        opp_sq.to_string()
                                    ));
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // 2. Detect Forks by the opponent
    for opp_sq in board.by_color(opponent) {
        if let Some(opp_piece) = board.piece_at(opp_sq) {
            let attacks = shakmaty::attacks::attacks(opp_sq, opp_piece, occupied);
            let mut attacked_friendly_pieces = Vec::new();

            for attacked_sq in attacks {
                if let Some(friendly_piece) = board.piece_at(attacked_sq) {
                    if friendly_piece.color == turn {
                        attacked_friendly_pieces.push((attacked_sq, friendly_piece));
                    }
                }
            }

            if attacked_friendly_pieces.len() >= 2 {
                let mut significant_fork = false;
                let mut target_descriptions = Vec::new();
                for (f_sq, f_piece) in &attacked_friendly_pieces {
                    let is_king = f_piece.role == shakmaty::Role::King;
                    let is_high_value = f_piece.role != shakmaty::Role::Pawn;
                    let is_undefended = board.attacks_to(*f_sq, turn, occupied).is_empty();

                    if is_king || is_high_value || is_undefended {
                        significant_fork = true;
                    }
                    target_descriptions.push(format!("{} on {}", format_role_name(f_piece.role), f_sq.to_string()));
                }

                if significant_fork {
                    observations.push(format!(
                        "The opponent's {} on {} has created a fork, attacking: {}.",
                        format_role_name(opp_piece.role),
                        opp_sq.to_string(),
                        target_descriptions.join(" and ")
                    ));
                }
            }
        }
    }

    // 3. Detect Hanging Friendly Pieces
    for sq in board.by_color(turn) {
        if let Some(piece) = board.piece_at(sq) {
            if piece.role != shakmaty::Role::King {
                let attackers = board.attacks_to(sq, opponent, occupied);
                if !attackers.is_empty() {
                    let defenders = board.attacks_to(sq, turn, occupied);
                    if defenders.is_empty() {
                        observations.push(format!(
                            "Your {} on {} is undefended and hanging under attack by the opponent.",
                            format_role_name(piece.role),
                            sq.to_string()
                        ));
                    }
                }
            }
        }
    }

    observations
}

fn format_role_name(role: shakmaty::Role) -> &'static str {
    match role {
        shakmaty::Role::Pawn => "Pawn",
        shakmaty::Role::Knight => "Knight",
        shakmaty::Role::Bishop => "Bishop",
        shakmaty::Role::Rook => "Rook",
        shakmaty::Role::Queen => "Queen",
        shakmaty::Role::King => "King",
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_hanging_piece_detection() {
        // A position with a hanging black pawn on e5 under attack by white knight on f3
        let fen = "rnbqkbnr/pppp1ppp/8/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2".to_string();
        let threats = analyze_tactical_threats(fen);
        assert!(threats.iter().any(|t| t.contains("hanging")));
    }
}


