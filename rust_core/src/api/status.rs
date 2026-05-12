use shakmaty::{fen::Fen, CastlingMode, Chess, Position};

pub struct GameTerminationStatus {
    pub is_game_over: bool,
    pub is_check: bool,
    pub is_checkmate: bool,
    pub is_stalemate: bool,
    pub is_insufficient_material: bool,
}

#[flutter_rust_bridge::frb(sync)]
pub fn evaluate_game_status(fen: String, is_chess960: bool) -> GameTerminationStatus {
    let setup = match fen.parse::<Fen>() {
        Ok(f) => f,
        Err(_) => {
            return GameTerminationStatus {
                is_game_over: false,
                is_check: false,
                is_checkmate: false,
                is_stalemate: false,
                is_insufficient_material: false,
            }
        }
    };

    let mode = if is_chess960 {
        CastlingMode::Chess960
    } else {
        CastlingMode::Standard
    };

    let pos: Chess = match setup.into_position(mode) {
        Ok(p) => p,
        Err(_) => {
            return GameTerminationStatus {
                is_game_over: false,
                is_check: false,
                is_checkmate: false,
                is_stalemate: false,
                is_insufficient_material: false,
            }
        }
    };

    GameTerminationStatus {
        is_game_over: pos.is_game_over(),
        is_check: pos.is_check(),
        is_checkmate: pos.is_checkmate(),
        is_stalemate: pos.is_stalemate(),
        is_insufficient_material: pos.is_insufficient_material(),
    }
}
