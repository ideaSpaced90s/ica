use shakmaty::{fen::Fen, CastlingMode, Chess, Move, Position, Square, Role};

#[flutter_rust_bridge::frb(sync)]
pub fn humanize_move_rust(
    fen_before: String,
    move_uci: String,
) -> String {
    let setup = match fen_before.parse::<Fen>() {
        Ok(f) => f,
        Err(_) => return format!("Move played: {}", move_uci),
    };

    let pos: Chess = match setup.into_position(CastlingMode::Standard) {
        Ok(p) => p,
        Err(_) => return format!("Move played: {}", move_uci),
    };

    let turn = pos.turn();
    let color_str = if turn.is_white() { "White" } else { "Black" };

    if move_uci.len() < 4 {
        return format!("{} played {}", color_str, move_uci);
    }

    let from_str = &move_uci[0..2];
    let to_str = &move_uci[2..4];
    let promo_char = move_uci.chars().nth(4);

    let from_sq: Square = match from_str.parse() {
        Ok(sq) => sq,
        Err(_) => return format!("{} played {}", color_str, move_uci),
    };

    let to_sq: Square = match to_str.parse() {
        Ok(sq) => sq,
        Err(_) => return format!("{} played {}", color_str, move_uci),
    };

    let promo_role = match promo_char {
        Some('q') => Some(Role::Queen),
        Some('r') => Some(Role::Rook),
        Some('b') => Some(Role::Bishop),
        Some('n') => Some(Role::Knight),
        _ => None,
    };

    let mut matching_move = None;
    for m in pos.legal_moves() {
        if m.from() == Some(from_sq) {
            let matches_dest = m.to() == to_sq;
            let matches_castle = match &m {
                Move::Castle { king, rook } => {
                    let is_white = king.rank() == shakmaty::Rank::First;
                    let is_kingside = rook.file() > king.file();
                    let standard_target = if is_white {
                        if is_kingside { Square::G1 } else { Square::C1 }
                    } else {
                        if is_kingside { Square::G8 } else { Square::C8 }
                    };
                    *king == from_sq && (to_sq == standard_target || to_sq == *rook)
                }
                _ => false,
            };
            let matches_promo = match &m {
                Move::Normal { promotion, .. } => *promotion == promo_role,
                _ => promo_role.is_none(),
            };

            if (matches_dest || matches_castle) && matches_promo {
                matching_move = Some(m);
                break;
            }
        }
    }

    let m = match matching_move {
        Some(mv) => mv,
        None => return format!("{} played {}", color_str, move_uci),
    };

    let mut description = String::new();

    let mut next_pos = pos.clone();
    next_pos.play_unchecked(&m);
    let is_check = next_pos.is_check();
    let is_checkmate = next_pos.is_checkmate();

    match &m {
        Move::Castle { king, rook } => {
            let is_kingside = rook.file() > king.file();
            let side = if is_kingside { "kingside" } else { "queenside" };
            description = format!("{} castles {}", color_str, side);
        }
        Move::Normal { role, to, capture, promotion, .. } => {
            let piece_name = format_role(*role);
            if let Some(cap_role) = capture {
                let cap_name = format_role(*cap_role);
                description = format!(
                    "{}'s {} captures the {} on {}",
                    color_str, piece_name, cap_name, to.to_string()
                );
            } else {
                description = format!(
                    "{} moves {} to {}",
                    color_str, piece_name, to.to_string()
                );
            }

            if let Some(promo) = promotion {
                let promo_name = format_role(*promo);
                description = format!("{} and promotes to a {}", description, promo_name);
            }
        }
        Move::EnPassant { to, .. } => {
            description = format!(
                "{}'s Pawn captures the opponent's Pawn on {} en passant",
                color_str, to.to_string()
            );
        }
        Move::Put { role, to } => {
            let piece_name = format_role(*role);
            description = format!("{} places a {} on {}", color_str, piece_name, to.to_string());
        }
    }

    if is_checkmate {
        description = format!("{}, delivering checkmate!", description);
    } else if is_check {
        description = format!("{}, putting the King in check.", description);
    } else {
        description = format!("{}.", description);
    }

    description
}

fn format_role(role: Role) -> &'static str {
    match role {
        Role::Pawn => "Pawn",
        Role::Knight => "Knight",
        Role::Bishop => "Bishop",
        Role::Rook => "Rook",
        Role::Queen => "Queen",
        Role::King => "King",
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_humanize_standard_moves() {
        let fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1".to_string();
        
        let desc = humanize_move_rust(fen.clone(), "e2e4".to_string());
        assert_eq!(desc, "White moves Pawn to e4.");

        let desc2 = humanize_move_rust(fen, "g1f3".to_string());
        assert_eq!(desc2, "White moves Knight to f3.");
    }

    #[test]
    fn test_humanize_castling() {
        // Position where white can castle kingside
        let fen = "r1bqk2r/pppp1ppp/2n2n2/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 5".to_string();
        let desc = humanize_move_rust(fen, "e1g1".to_string());
        assert_eq!(desc, "White castles kingside.");
    }
}
