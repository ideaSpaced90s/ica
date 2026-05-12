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
