use shakmaty::{Board, Chess, Color, Move, Position, Square, Role};

#[derive(Clone, Debug)]
pub struct SavedGameUci {
    pub recent_moves: Vec<String>,
    pub is_player_white: bool,
    pub result: String, // "W", "L", "D"
    pub white_time_left_ms: i32,
    pub black_time_left_ms: i32,
    pub rating_category: String, // "bullet", "blitz", "rapid"
}

#[derive(Clone, Debug)]
pub struct ScotomaResult {
    pub diagonal_retreats: f64,
    pub horizontal_swings: f64,
    pub knight_forks: f64,
    pub time_panic: f64,
    pub material_greed: f64,
    pub tunnel_vision: f64,
    pub pinned_pieces: f64,
    pub king_safety: f64,
}

#[flutter_rust_bridge::frb(sync)]
pub fn analyze_scotoma(games: Vec<SavedGameUci>) -> ScotomaResult {
    if games.is_empty() {
        return ScotomaResult {
            diagonal_retreats: 0.15,
            horizontal_swings: 0.15,
            knight_forks: 0.15,
            time_panic: 0.15,
            material_greed: 0.15,
            tunnel_vision: 0.15,
            pinned_pieces: 0.15,
            king_safety: 0.15,
        };
    }

    let mut dgb_count: f64 = 0.0;
    let mut hrz_count: f64 = 0.0;
    let mut knf_count: f64 = 0.0;
    let mut tmp_count: f64 = 0.0;
    let mut grd_count: f64 = 0.0;
    let mut tnl_count: f64 = 0.0;
    let mut pin_count: f64 = 0.0;
    let mut ksb_count: f64 = 0.0;

    let total_games = games.len() as f64;

    for game in &games {
        let is_loss = game.result == "L";
        let is_win = game.result == "W";

        // Parse moves and trace chess game states
        let mut pos = Chess::default();
        let mut pos_states: Vec<Chess> = vec![pos.clone()];
        let mut moves_played: Vec<Move> = Vec::new();
        let mut turn_colors: Vec<Color> = Vec::new();

        // Safe parsing loop
        for uci in &game.recent_moves {
            if uci.len() < 4 {
                continue;
            }
            let from_str = &uci[0..2];
            let to_str = &uci[2..4];
            let promo_char = if uci.len() > 4 { uci.chars().nth(4) } else { None };

            let from_sq: Square = match from_str.parse() {
                Ok(sq) => sq,
                Err(_) => continue,
            };
            let to_sq: Square = match to_str.parse() {
                Ok(sq) => sq,
                Err(_) => continue,
            };

            let promo_role = match promo_char {
                Some('q') => Some(Role::Queen),
                Some('r') => Some(Role::Rook),
                Some('b') => Some(Role::Bishop),
                Some('n') => Some(Role::Knight),
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
                turn_colors.push(pos.turn());
                pos.play_unchecked(&m);
                pos_states.push(pos.clone());
                moves_played.push(m);
            } else {
                break;
            }
        }

        let num_moves = moves_played.len();
        if num_moves == 0 {
            continue;
        }

        // Time Panic Check:
        // Remaining time below 45 seconds during a loss
        let player_time_left = if game.is_player_white {
            game.white_time_left_ms
        } else {
            game.black_time_left_ms
        };
        if is_loss && player_time_left > 0 && player_time_left < 45_000 {
            tmp_count += 1.0;
        }

        // Heuristically focus on the final 8 plies (last 4 full moves) where tactical mistakes cluster
        let start_ply = if num_moves > 8 { num_moves - 8 } else { 0 };

        for ply in start_ply..num_moves {
            let m = &moves_played[ply];
            let active_color = turn_colors[ply];
            let is_player_move = (active_color == Color::White) == game.is_player_white;
            let from_sq = match m.from() {
                Some(sq) => sq,
                None => continue,
            };
            let to_sq = m.to();
            let role = m.role();
            let board_before = pos_states[ply].board();

            // 1. Diagonal Retreats (DGB)
            // Bishop or Queen retreating diagonally by >= 3 squares
            let is_dgb = (role == Role::Bishop || role == Role::Queen) && {
                let dx = (to_sq.file() as i32 - from_sq.file() as i32).abs();
                let dy = (to_sq.rank() as i32 - from_sq.rank() as i32).abs();
                let is_diagonal = dx == dy && dx >= 3;
                let is_retreat = if active_color == Color::White {
                    to_sq.rank() < from_sq.rank()
                } else {
                    to_sq.rank() > from_sq.rank()
                };
                is_diagonal && is_retreat
            };

            // 2. Horizontal Swings (HRZ)
            // Rook or Queen sweeping horizontally by >= 3 squares
            let is_hrz = (role == Role::Rook || role == Role::Queen) && {
                let dx = (to_sq.file() as i32 - from_sq.file() as i32).abs();
                let is_horizontal = to_sq.rank() == from_sq.rank() && dx >= 3;
                is_horizontal
            };

            // 3. Knight Flanks (KNF)
            // Knight jump originating from or landing on A/H files
            let is_knf = role == Role::Knight && {
                from_sq.file() == shakmaty::File::A || from_sq.file() == shakmaty::File::H ||
                to_sq.file() == shakmaty::File::A || to_sq.file() == shakmaty::File::H
            };

            // 4. Pinned Pieces (PIN)
            // Was the piece pinned to King/Queen before it was moved or attacked?
            let is_pin_move = is_pinned(board_before, from_sq, active_color);

            // Increment scotoma metrics if the player missed/allowed these threats (Loss)
            // Or reduce them if the player successfully executed/defended them (Win)
            if is_loss {
                if !is_player_move {
                    // Opponent hit us with these visual patterns
                    if is_dgb { dgb_count += 1.0; }
                    if is_hrz { hrz_count += 1.0; }
                    if is_knf { knf_count += 1.0; }
                    if is_pin_move { pin_count += 1.0; }

                    // King Safety (KSB): opponent check or mate threat
                    if pos_states[ply + 1].is_check() {
                        ksb_count += 0.8;
                    }
                } else {
                    // Player's own move in critical phase was a blunder
                    // Greed (GRD): Player captured immediately before losing
                    if m.is_capture() && ply + 1 < num_moves {
                        let opp_reply = &moves_played[ply + 1];
                        if opp_reply.is_capture() || pos_states[ply + 2].is_check() {
                            grd_count += 1.0;
                        }
                    }

                    // Tunnel Vision (TNL): Player playing on one side while opponent strikes on other
                    if ply + 1 < num_moves {
                        let opp_reply = &moves_played[ply + 1];
                        let player_file = to_sq.file() as i32;
                        let opp_file = opp_reply.to().file() as i32;
                        if (player_file - opp_file).abs() >= 4 {
                            tnl_count += 1.0;
                        }
                    }
                }
            } else if is_win {
                // Wins act as stabilizer damping down scotoma risk
                if is_player_move {
                    if is_dgb { dgb_count = (dgb_count - 0.2).max(0.0); }
                    if is_hrz { hrz_count = (hrz_count - 0.2).max(0.0); }
                    if is_knf { knf_count = (knf_count - 0.2).max(0.0); }
                    if is_pin_move { pin_count = (pin_count - 0.2).max(0.0); }
                }
            }
        }

        // Final move checkmate check for King Safety (KSB)
        if is_loss && pos_states.last().map_or(false, |pos| pos.is_check()) {
            ksb_count += 1.0;
        }
    }

    // Mathematical Normalization (Map to a scholarly 0.05 to 0.95 scale)
    let normalize = |val: f64| -> f64 {
        let raw = val / total_games;
        // Apply organic scaling curve: baseline 0.15 + raw, clamped to [0.05, 0.95]
        (0.15 + raw * 0.7).clamp(0.05, 0.95)
    };

    ScotomaResult {
        diagonal_retreats: normalize(dgb_count),
        horizontal_swings: normalize(hrz_count),
        knight_forks: normalize(knf_count),
        time_panic: normalize(tmp_count),
        material_greed: normalize(grd_count),
        tunnel_vision: normalize(tnl_count),
        pinned_pieces: normalize(pin_count),
        king_safety: normalize(ksb_count),
    }
}

// Internal Pin Detector: Recreates threats.rs pin scanning logic
fn is_pinned(board: &Board, sq: Square, color: Color) -> bool {
    let opponent = !color;
    if let Some(king_sq) = board.king_of(color) {
        if sq == king_sq {
            return false;
        }

        // Temporarily remove piece at `sq`
        let mut temp_board = board.clone();
        let _ = temp_board.remove_piece_at(sq);
        let temp_occupied = temp_board.occupied();

        // Check if any opponent piece attacks the king now
        for opp_sq in temp_board.by_color(opponent) {
            if let Some(opp_piece) = temp_board.piece_at(opp_sq) {
                let attacks = shakmaty::attacks::attacks(opp_sq, opp_piece, temp_occupied);
                if attacks.contains(king_sq) {
                    // Make sure it wasn't already checking the king in original position
                    let original_attacks = shakmaty::attacks::attacks(opp_sq, opp_piece, board.occupied());
                    if !original_attacks.contains(king_sq) {
                        return true;
                    }
                }
            }
        }
    }
    false
}
