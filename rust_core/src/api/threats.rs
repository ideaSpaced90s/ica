use shakmaty::{fen::Fen, CastlingMode, Chess, Position, Square};

#[flutter_rust_bridge::frb(sync)]
pub fn get_threatened_squares(fen: String, is_chess960: bool) -> Vec<String> {
    // Parse the FEN string safely
    let setup = match fen.parse::<Fen>() {
        Ok(f) => f,
        Err(_) => return vec![],
    };

    let mode = if is_chess960 {
        CastlingMode::Chess960
    } else {
        CastlingMode::Standard
    };

    let pos: Chess = match setup.into_position(mode) {
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

fn get_piece_value(role: shakmaty::Role) -> i32 {
    match role {
        shakmaty::Role::Pawn => 1,
        shakmaty::Role::Knight => 3,
        shakmaty::Role::Bishop => 3,
        shakmaty::Role::Rook => 5,
        shakmaty::Role::Queen => 9,
        shakmaty::Role::King => 1000,
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn get_dominating_squares(fen: String, is_chess960: bool) -> Vec<String> {
    // Parse the Fen and use the board directly, without checking legality.
    // This avoids rejecting mid-game positions where the side not to move
    // might appear to be in check (e.g. advanced pawns near the opponent king).
    let setup = match fen.parse::<Fen>() {
        Ok(f) => f,
        Err(_) => return vec![],
    };

    // We still try a full legal parse first; if it fails we fall back to
    // reading the raw board from the Fen setup.
    let mode = if is_chess960 {
        CastlingMode::Chess960
    } else {
        CastlingMode::Standard
    };

    let board = match setup.clone().into_position::<Chess>(mode) {
        Ok(pos) => pos.board().clone(),
        Err(_) => setup.0.board,
    };
    let occupied = board.occupied();

    let mut dominating = Vec::new();

    // Iterate over all squares on the board
    for sq in Square::ALL {
        if let Some(piece) = board.piece_at(sq) {
            let color = piece.color;
            let opponent = !color;

            // 1. Check if it's a pinning piece (relative or absolute)
            let mut is_pinning = false;
            if piece.role == shakmaty::Role::Bishop || piece.role == shakmaty::Role::Rook || piece.role == shakmaty::Role::Queen {
                let original_attacks = shakmaty::attacks::attacks(sq, piece, occupied);
                // For every opponent piece that this piece attacks:
                for opp_sq in board.by_color(opponent) {
                    if original_attacks.contains(opp_sq) {
                        // Temporarily remove the opponent piece to see if we now attack a more valuable piece or the king
                        let mut temp_board = board.clone();
                        let _ = temp_board.remove_piece_at(opp_sq);
                        let temp_occupied = temp_board.occupied();
                        let new_attacks = shakmaty::attacks::attacks(sq, piece, temp_occupied);

                        // The new attacks along the ray (excluding the original attacks and the removed piece's square itself)
                        let ray_targets = new_attacks & !original_attacks;
                        for target_sq in ray_targets {
                            if let Some(target_piece) = board.piece_at(target_sq) {
                                if target_piece.color == opponent {
                                    let val_opp = get_piece_value(board.piece_at(opp_sq).unwrap().role);
                                    let val_target = get_piece_value(target_piece.role);
                                    if val_target > val_opp || target_piece.role == shakmaty::Role::King {
                                        is_pinning = true;
                                        break;
                                    }
                                }
                            }
                        }
                    }
                    if is_pinning {
                        break;
                    }
                }
            }

            // 2. Check if it is forking (attacks 2 or more opponent pieces under significant conditions)
            let mut is_forking = false;
            if !is_pinning {
                let attacks = shakmaty::attacks::attacks(sq, piece, occupied);
                let mut attacked_opponents = 0;
                for attacked_sq in attacks {
                    if let Some(attacked_piece) = board.piece_at(attacked_sq) {
                        if attacked_piece.color == opponent {
                            let is_king = attacked_piece.role == shakmaty::Role::King;
                            let is_high_val = get_piece_value(attacked_piece.role) > get_piece_value(piece.role);
                            let is_undefended = board.attacks_to(attacked_sq, color, occupied).is_empty();
                            if is_king || is_high_val || is_undefended || get_piece_value(attacked_piece.role) >= 3 {
                                attacked_opponents += 1;
                            }
                        }
                    }
                }
                if attacked_opponents >= 2 {
                    is_forking = true;
                }
            }

            // 3. Check if it is a strong pawn
            let mut is_strong_pawn = false;
            if !is_pinning && !is_forking && piece.role == shakmaty::Role::Pawn {
                let file = sq.file();
                let rank = sq.rank();
                let mut is_passed = true;
                for other_sq in Square::ALL {
                    if let Some(other_piece) = board.piece_at(other_sq) {
                        if other_piece.role == shakmaty::Role::Pawn && other_piece.color == opponent {
                            let other_file = other_sq.file();
                            let other_rank = other_sq.rank();
                            let file_diff = (file as i8 - other_file as i8).abs();
                            if file_diff <= 1 {
                                match color {
                                    shakmaty::Color::White => {
                                        if other_rank > rank {
                                            is_passed = false;
                                        }
                                    }
                                    shakmaty::Color::Black => {
                                        if other_rank < rank {
                                            is_passed = false;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                let is_advanced = match color {
                    shakmaty::Color::White => rank as u8 >= 4,
                    shakmaty::Color::Black => rank as u8 <= 3,
                };
                let is_very_advanced = match color {
                    shakmaty::Color::White => rank as u8 >= 5,
                    shakmaty::Color::Black => rank as u8 <= 2,
                };
                let protects_advanced_minor = {
                    let mut protects = false;
                    let pawn_attacks = shakmaty::attacks::pawn_attacks(color, sq);
                    for attacked_sq in pawn_attacks {
                        if let Some(target_piece) = board.piece_at(attacked_sq) {
                            if target_piece.color == color && (target_piece.role == shakmaty::Role::Knight || target_piece.role == shakmaty::Role::Bishop) {
                                let target_rank = attacked_sq.rank() as u8;
                                let is_target_advanced = match color {
                                    shakmaty::Color::White => target_rank >= 4,
                                    shakmaty::Color::Black => target_rank <= 3,
                                };
                                if is_target_advanced {
                                    protects = true;
                                    break;
                                }
                            }
                        }
                    }
                    protects
                };

                if (is_passed && is_advanced) || is_very_advanced || protects_advanced_minor {
                    is_strong_pawn = true;
                }
            }

            if is_pinning || is_forking || is_strong_pawn {
                dominating.push(sq.to_string());
            }
        }
    }

    dominating
}

#[flutter_rust_bridge::frb(sync)]
pub fn analyze_tactical_threats(fen: String, is_chess960: bool) -> Vec<String> {
    let setup = match fen.parse::<Fen>() {
        Ok(f) => f,
        Err(_) => return vec![],
    };


    let mode = if is_chess960 {
        CastlingMode::Chess960
    } else {
        CastlingMode::Standard
    };

    let pos: Chess = match setup.into_position(mode) {
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
    let mut hanging_pieces = Vec::new();
    for sq in board.by_color(turn) {
        if let Some(piece) = board.piece_at(sq) {
            if piece.role != shakmaty::Role::King {
                let attackers = board.attacks_to(sq, opponent, occupied);
                if !attackers.is_empty() {
                    let defenders = board.attacks_to(sq, turn, occupied);
                    if defenders.is_empty() {
                        hanging_pieces.push(format!("{} on {}", format_role_name(piece.role), sq.to_string()));
                    }
                }
            }
        }
    }
    if !hanging_pieces.is_empty() {
        if hanging_pieces.len() == 1 {
            observations.push(format!(
                "Your {} is undefended and hanging under attack.",
                hanging_pieces[0]
            ));
        } else {
            observations.push(format!(
                "Your {} are undefended and hanging under attack.",
                hanging_pieces.join(" and ")
            ));
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
        let threats = analyze_tactical_threats(fen, false);
        assert!(threats.iter().any(|t| t.contains("hanging")));
    }

    #[test]
    fn test_dominating_squares_pin() {
        // White Queen on d2 pinning Black Bishop on d4 to Black King on d8
        let fen = "3k4/8/8/8/3b4/8/3Q4/3K4 w - - 0 1".to_string();
        let dominating = get_dominating_squares(fen, false);
        assert!(dominating.contains(&"d2".to_string()));
    }

    #[test]
    fn test_dominating_squares_fork() {
        // White Knight on d5 attacking Black Queen on b6 and Black Rook on f6
        let fen = "3k4/8/1q3r2/3N4/8/8/8/3K4 w - - 0 1".to_string();
        let dominating = get_dominating_squares(fen, false);
        assert!(dominating.contains(&"d5".to_string()));
    }

    #[test]
    fn test_dominating_squares_strong_pawn() {
        // White pawn on e6 (rank 6 - very advanced, rank index 5), White to move, no illegal check.
        let fen = "3k4/8/4P3/8/8/8/8/3K4 w - - 0 1".to_string();
        let dominating = get_dominating_squares(fen, false);
        assert!(dominating.contains(&"e6".to_string()));
    }
}


