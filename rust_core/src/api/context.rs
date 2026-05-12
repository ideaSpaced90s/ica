use shakmaty::{fen::Fen, CastlingMode, Chess, Position};

pub struct PositionMetrics {
    pub piece_count: u32,
    pub game_phase: String,
}

#[flutter_rust_bridge::frb(sync)]
pub fn evaluate_position_metrics(fen: String, history_length: u32) -> PositionMetrics {
    let setup = match fen.parse::<Fen>() {
        Ok(f) => f,
        Err(_) => {
            return PositionMetrics {
                piece_count: 32,
                game_phase: "Middlegame".to_string(),
            }
        }
    };

    let pos: Chess = match setup.into_position(CastlingMode::Standard) {
        Ok(p) => p,
        Err(_) => {
            return PositionMetrics {
                piece_count: 32,
                game_phase: "Middlegame".to_string(),
            }
        }
    };

    // Execute blazing fast CPU population count over 64-bit hardware masks
    let piece_count = pos.board().occupied().count() as u32;

    let game_phase = if history_length <= 20 {
        "Opening".to_string()
    } else if piece_count <= 10 {
        "Endgame".to_string()
    } else {
        "Middlegame".to_string()
    };

    PositionMetrics {
        piece_count,
        game_phase,
    }
}
