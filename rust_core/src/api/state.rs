use shakmaty::{fen::Fen, CastlingMode, Chess, EnPassantMode, Move, Position, Square};

#[flutter_rust_bridge::frb(sync)]
pub fn validate_and_apply_move(
    current_fen: String,
    from_str: String,
    to_str: String,
    promotion_str: String,
    is_chess960: bool,
) -> Option<String> {
    let setup = match current_fen.parse::<Fen>() {
        Ok(f) => f,
        Err(_) => return None,
    };

    let mode = if is_chess960 {
        CastlingMode::Chess960
    } else {
        CastlingMode::Standard
    };

    let mut pos: Chess = match setup.into_position(mode) {
        Ok(p) => p,
        Err(_) => return None,
    };

    let from_sq: Square = match from_str.parse() {
        Ok(sq) => sq,
        Err(_) => return None,
    };

    let to_sq: Square = match to_str.parse() {
        Ok(sq) => sq,
        Err(_) => return None,
    };

    let promo_role = match promotion_str.chars().next() {
        Some('q') => Some(shakmaty::Role::Queen),
        Some('r') => Some(shakmaty::Role::Rook),
        Some('b') => Some(shakmaty::Role::Bishop),
        Some('n') => Some(shakmaty::Role::Knight),
        _ => None,
    };

    let mut found_move = None;
    for m in pos.legal_moves() {
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

    if let Some(m) = found_move {
        pos.play_unchecked(&m);
        let resulting_fen = Fen::from_position(pos, EnPassantMode::Legal);
        Some(resulting_fen.to_string())
    } else {
        None
    }
}
