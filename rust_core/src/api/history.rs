use shakmaty::{fen::Fen, san::San, CastlingMode, Chess, Move, Position, Square};

#[flutter_rust_bridge::frb(sync)]
pub fn get_san_history(
    initial_fen: String,
    uci_moves: Vec<String>,
    is_chess960: bool,
) -> Vec<String> {
    let setup = match initial_fen.parse::<Fen>() {
        Ok(f) => f,
        Err(_) => return vec![],
    };

    let mode = if is_chess960 {
        CastlingMode::Chess960
    } else {
        CastlingMode::Standard
    };

    let mut pos: Chess = match setup.into_position(mode) {
        Ok(p) => p,
        Err(_) => return vec![],
    };

    let mut san_list = Vec::new();

    for uci in uci_moves {
        if uci.len() < 4 {
            continue;
        }

        let from_str = &uci[0..2];
        let to_str = &uci[2..4];
        let promo_char = if uci.len() > 4 {
            uci.chars().nth(4)
        } else {
            None
        };

        let from_sq: Square = match from_str.parse() {
            Ok(sq) => sq,
            Err(_) => continue,
        };

        let to_sq: Square = match to_str.parse() {
            Ok(sq) => sq,
            Err(_) => continue,
        };

        let promo_role = match promo_char {
            Some('q') => Some(shakmaty::Role::Queen),
            Some('r') => Some(shakmaty::Role::Rook),
            Some('b') => Some(shakmaty::Role::Bishop),
            Some('n') => Some(shakmaty::Role::Knight),
            _ => None,
        };

        // Scan bitboard-validated MoveList to locate absolute mapping
        let mut found_move = None;
        for m in pos.legal_moves() {
            if m.from() == Some(from_sq) {
                let m_to = m.to();
                let matches_dest = m_to == to_sq;

                let matches_castle = match &m {
                    Move::Castle { king, rook } => {
                        if *rook == to_sq || m_to == to_sq {
                            true
                        } else if !is_chess960 {
                            (*king == Square::E1 && to_sq == Square::G1 && *rook == Square::H1) ||
                            (*king == Square::E1 && to_sq == Square::C1 && *rook == Square::A1) ||
                            (*king == Square::E8 && to_sq == Square::G8 && *rook == Square::H8) ||
                            (*king == Square::E8 && to_sq == Square::C8 && *rook == Square::A8)
                        } else {
                            false
                        }
                    }
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

        if let Some(m) = found_move {
            let san = San::from_move(&pos, &m);
            san_list.push(san.to_string());
            pos.play_unchecked(&m);
        } else {
            // Divergence safeguard
            break;
        }
    }

    san_list
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_standard_castling_san_history() {
        let moves = vec![
            "e2e4".to_string(),
            "e7e5".to_string(),
            "g1f3".to_string(),
            "b8c6".to_string(),
            "f1c4".to_string(),
            "f8c5".to_string(),
            "e1g1".to_string(), // White castling
            "g8f6".to_string(),
        ];
        let history = get_san_history(
            "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1".to_string(),
            moves,
            false,
        );
        assert_eq!(history.len(), 8);
        assert_eq!(history[6], "O-O");
    }
}
