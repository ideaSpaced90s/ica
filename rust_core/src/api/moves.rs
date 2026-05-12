use shakmaty::{fen::Fen, CastlingMode, Chess, Move, Position, Square};

#[flutter_rust_bridge::frb(sync)]
pub fn get_legal_destinations(fen: String, square: String, is_chess960: bool) -> Vec<String> {
    let from_sq: Square = match square.parse() {
        Ok(sq) => sq,
        Err(_) => return vec![],
    };

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

    let mut dests = Vec::new();

    for m in pos.legal_moves() {
        if m.from() == Some(from_sq) {
            // Push standard target square
            let to_str = m.to().to_string();
            if !dests.contains(&to_str) {
                dests.push(to_str);
            }

            // If it is a castling move, also include the rook square or standard king destination
            // to support customized Chess960 drag-and-drop targets
            match m {
                Move::Castle { king: _, rook } => {
                    let rook_str = rook.to_string();
                    if !dests.contains(&rook_str) {
                        dests.push(rook_str);
                    }
                    // Also ensure g1/c1/g8/c8 destinations are included
                    let is_white = from_sq.rank() == shakmaty::Rank::First;
                    let target_file = if rook.file() > from_sq.file() {
                        shakmaty::File::G
                    } else {
                        shakmaty::File::C
                    };
                    let standard_sq = Square::from_coords(
                        target_file,
                        if is_white {
                            shakmaty::Rank::First
                        } else {
                            shakmaty::Rank::Eighth
                        },
                    );
                    let std_str = standard_sq.to_string();
                    if !dests.contains(&std_str) {
                        dests.push(std_str);
                    }
                }
                _ => {}
            }
        }
    }

    dests
}
