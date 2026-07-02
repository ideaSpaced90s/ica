use shakmaty::{Chess, Position, CastlingMode};
use shakmaty::fen::Fen;

fn main() {
    let fen_str = "nnrkrqbb/pppppppp/8/8/8/8/PPPPPPPP/NNRKRQBB w KQkq - 0 1";
    let fen: Fen = fen_str.parse().unwrap();
    let pos: Chess = fen.into_position(CastlingMode::Chess960).unwrap();
    
    // We want to test this logic in our Arasan engine.
    // I will write a C++ test program to execute doMove and undoMove for all moves and print if there is a FEN mismatch!
}
