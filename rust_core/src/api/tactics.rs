use shakmaty::{fen::Fen, san::San, CastlingMode, Chess, Move, Position, Role, Square};

#[derive(Clone, Debug)]
pub struct TacticData {
    pub name: String,
    pub moves: Vec<String>,      // e.g., ["e2e4", "d7d5", "e4d5"]
    pub san_moves: Vec<String>,  // e.g., ["e4", "d5", "exd5"]
    pub explanation: String,
}

#[derive(Clone, Debug)]
pub struct StockfishTacticLine {
    pub move_uci: String,
    pub evaluation: f64,
    pub pv: Vec<String>,
}

#[derive(Debug)]
pub struct TacticsResult {
    pub text_response: String, // Clean prose with embedded [YOUR_TACTIC: ...] tags
    pub your_tactic: TacticData,
    pub alternatives: Vec<TacticData>,
}

fn parse_uci_to_move(pos: &Chess, uci: &str) -> Option<Move> {
    if uci.len() < 4 {
        return None;
    }
    let from_str = &uci[0..2];
    let to_str = &uci[2..4];
    let promo_char = uci.chars().nth(4);

    let from_sq: Square = from_str.parse().ok()?;
    let to_sq: Square = to_str.parse().ok()?;
    
    let promo_role = match promo_char {
        Some('q') => Some(Role::Queen),
        Some('r') => Some(Role::Rook),
        Some('b') => Some(Role::Bishop),
        Some('n') => Some(Role::Knight),
        _ => None,
    };

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
                return Some(m.clone());
            }
        }
    }
    None
}

#[flutter_rust_bridge::frb(sync)]
pub fn generate_tactics_analysis(
    fen: String,
    user_uci_moves: Vec<String>,
    engine_alternatives: Vec<StockfishTacticLine>,
    is_chess960: bool,
) -> TacticsResult {
    let setup = match fen.parse::<Fen>() {
        Ok(f) => f,
        Err(_) => {
            return TacticsResult {
                text_response: "I failed to parse the initial board state. Let us return to study.".to_string(),
                your_tactic: TacticData {
                    name: "Your Tactic".to_string(),
                    moves: vec![],
                    san_moves: vec![],
                    explanation: "Invalid starting board position.".to_string(),
                },
                alternatives: vec![],
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
            return TacticsResult {
                text_response: "The board configuration appears anomalous.".to_string(),
                your_tactic: TacticData {
                    name: "Your Tactic".to_string(),
                    moves: vec![],
                    san_moves: vec![],
                    explanation: "Failed to construct board setup.".to_string(),
                },
                alternatives: vec![],
            }
        }
    };

    // 1. Process user's tactic
    let mut current_pos = pos.clone();
    let mut user_moves = Vec::new();
    let mut user_san_moves = Vec::new();
    let mut user_moves_valid = true;

    for uci in &user_uci_moves {
        if uci.len() < 4 {
            user_moves_valid = false;
            break;
        }
        let from_str = &uci[0..2];
        if let Ok(from_sq) = from_str.parse::<Square>() {
            if let Some(piece) = current_pos.board().piece_at(from_sq) {
                let piece_is_white = piece.color == shakmaty::Color::White;
                let current_turn_is_white = current_pos.turn() == shakmaty::Color::White;
                if piece_is_white != current_turn_is_white {
                    let fen_str = Fen::from_position(current_pos.clone(), shakmaty::EnPassantMode::Legal).to_string();
                    let mut parts: Vec<&str> = fen_str.split(' ').collect();
                    if parts.len() > 3 {
                        parts[1] = if piece_is_white { "w" } else { "b" };
                        parts[3] = "-"; // Clear en-passant to avoid invalid FEN for the new turn
                        let aligned_fen_str = parts.join(" ");
                        if let Ok(aligned_setup) = aligned_fen_str.parse::<Fen>() {
                            if let Ok(aligned_pos) = aligned_setup.into_position(mode) {
                                current_pos = aligned_pos;
                            }
                        }
                    }
                }
            }
        }

        if let Some(m) = parse_uci_to_move(&current_pos, uci) {
            let san_str = San::from_move(&current_pos, &m).to_string();
            user_san_moves.push(san_str);
            user_moves.push(uci.clone());
            current_pos.play_unchecked(&m);
        } else {
            user_moves_valid = false;
            break;
        }
    }

    let your_tactic_explanation = if user_moves.is_empty() {
        "No moves were provided for analysis.".to_string()
    } else if !user_moves_valid {
        format!("The sequence starts with promise, but the path becomes invalid after playing: {}.", user_san_moves.last().cloned().unwrap_or_default())
    } else {
        format!("Your sequence maintains tension and seeks piece activity. Pay close attention to how it impacts your coordination.")
    };

    let your_tactic = TacticData {
        name: "Your Tactic".to_string(),
        moves: user_moves.clone(),
        san_moves: user_san_moves.clone(),
        explanation: your_tactic_explanation,
    };

    // Determine phase / piece count to limit alternatives in endgames
    let piece_count = pos.board().occupied().count();
    let limit = if piece_count <= 10 { 2 } else { 5 };

    // 2. Generate Alternatives
    let mut alternatives = Vec::new();
    let names = vec!["Tactic Alpha", "Tactic Beta", "Tactic Gamma", "Tactic Delta", "Tactic Epsilon"];
    let user_first_move_uci = user_uci_moves.first();

    if !engine_alternatives.is_empty() {
        for alt_line in &engine_alternatives {
            if alternatives.len() >= limit {
                break;
            }
            if alt_line.pv.is_empty() {
                continue;
            }

            let m1_uci = &alt_line.pv[0]; // Opponent response
            if let Some(user_second) = user_uci_moves.get(1) {
                if m1_uci == user_second && alternatives.is_empty() {
                    continue;
                }
            }

            let mut sim_pos = pos.clone();
            let mut seq_moves = Vec::new();
            let mut seq_san = Vec::new();
            let mut valid = true;

            // Play the user's first move first on the base position
            if let Some(first_uci) = user_first_move_uci {
                if let Some(m) = parse_uci_to_move(&sim_pos, first_uci) {
                    seq_san.push(San::from_move(&sim_pos, &m).to_string());
                    seq_moves.push(first_uci.clone());
                    sim_pos.play_unchecked(&m);
                } else {
                    valid = false;
                }
            }

            if valid {
                for uci in &alt_line.pv {
                    if seq_moves.len() >= user_uci_moves.len() {
                        break;
                    }
                    if let Some(m) = parse_uci_to_move(&sim_pos, uci) {
                        seq_san.push(San::from_move(&sim_pos, &m).to_string());
                        seq_moves.push(uci.clone());
                        sim_pos.play_unchecked(&m);
                    } else {
                        valid = false;
                        break;
                    }
                }
            }

            if !valid || seq_moves.is_empty() {
                continue;
            }

            let name = names[alternatives.len()].to_string();
            let eval_desc = if alt_line.evaluation.abs() > 10.0 {
                if alt_line.evaluation > 0.0 { "decisive advantage".to_string() } else { "decisive disadvantage".to_string() }
            } else {
                format!("{:.2} pawns", alt_line.evaluation)
            };

            let continuation_move = if seq_san.len() > 2 { seq_san[2].clone() } else { "rapid piece development".to_string() };
            let explanation = match alternatives.len() {
                0 => format!(
                    "My analysis favors this path (which I evaluate at {}). A strong continuation involves playing **{}**.",
                    eval_desc, continuation_move
                ),
                1 => format!(
                    "Consider this alternative branch (valued at {}). It focuses on optimizing your piece activity, expecting **{}**.",
                    eval_desc, continuation_move
                ),
                _ => format!(
                    "This variation is highly principled (evaluated at {}). It directs pressure to key squares, expecting **{}**.",
                    eval_desc, continuation_move
                ),
            };

            alternatives.push(TacticData {
                name,
                moves: seq_moves,
                san_moves: seq_san,
                explanation,
            });
        }
    }

    // 3. Build Chanakya text response containing the hidden tags
    let mut prose = String::new();
    prose.push_str("I have mapped out the tactical currents of your sequence, Apprentice. Let us review the lines:\n\n");
    
    // Describe User's tactic
    if user_moves.is_empty() {
        prose.push_str("No tactic sequence was demonstrated on the board. Please show me a sequence to receive a comprehensive analysis.\n\n");
    } else {
        let uci_str = user_moves.join(" ");
        let san_str = user_san_moves.join(" ");
        prose.push_str(&format!(
            "Regarding your line, **Your Tactic** ({}):\n[YOUR_TACTIC: {}]\n{}\n\n",
            san_str, uci_str, your_tactic.explanation
        ));
    }

    if alternatives.is_empty() {
        prose.push_str("I do not see any alternative tactical lines at this moment, Apprentice.\n\n");
    } else {
        prose.push_str("Consider these alternative tactical variations:\n\n");
        
        // Add alternatives
        for alt in &alternatives {
            let tag_name = alt.name.to_ascii_uppercase().replace(" ", "_");
            let uci_str = alt.moves.join(" ");
            let san_str = alt.san_moves.join(" ");
            
            prose.push_str(&format!(
                "**{}** ({}):\n[{}: {}]\n{}\n\n",
                alt.name, san_str, tag_name, uci_str, alt.explanation
            ));
        }
    }
    
    if piece_count <= 10 {
        prose.push_str("In this simplified endgame position, alternative paths are highly constrained. Play with precision.");
    } else {
        prose.push_str("Weigh these variations with care, Apprentice. The board demands structural harmony on every single move.");
    }

    TacticsResult {
        text_response: prose,
        your_tactic,
        alternatives,
    }
}
