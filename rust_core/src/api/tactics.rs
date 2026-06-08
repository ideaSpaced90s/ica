use shakmaty::{fen::Fen, san::San, CastlingMode, Chess, Move, Position, Role, Square};

#[derive(Clone, Debug)]
pub struct TacticData {
    pub name: String,
    pub moves: Vec<String>,      // e.g., ["e2e4", "d7d5", "e4d5"]
    pub san_moves: Vec<String>,  // e.g., ["e4", "d5", "exd5"]
    pub explanation: String,
}

#[derive(Debug)]
pub struct TacticsResult {
    pub text_response: String, // Clean prose with embedded [YOUR_TACTIC: ...] tags
    pub your_tactic: TacticData,
    pub alternatives: Vec<TacticData>,
}

fn evaluate_move(pos: &Chess, m: &Move) -> i32 {
    let mut score = 0;
    
    // Simulate move
    let mut next_pos = pos.clone();
    next_pos.play_unchecked(m);
    
    if next_pos.is_checkmate() {
        score += 10000;
    }
    if next_pos.is_check() {
        score += 500;
    }
    
    if let Some(capture) = m.capture() {
        score += match capture {
            Role::Pawn => 100,
            Role::Knight => 320,
            Role::Bishop => 330,
            Role::Rook => 500,
            Role::Queen => 900,
            Role::King => 0,
        };
    }
    
    if m.is_castle() {
        score += 80;
    }
    
    // Center control (d4, d5, e4, e5 squares and surrounds)
    let to_sq = m.to();
    let file = to_sq.file();
    let rank = to_sq.rank();
    if (file == shakmaty::File::C || file == shakmaty::File::D || file == shakmaty::File::E || file == shakmaty::File::F)
        && (rank == shakmaty::Rank::Third || rank == shakmaty::Rank::Fourth || rank == shakmaty::Rank::Fifth || rank == shakmaty::Rank::Sixth)
    {
        score += 30;
    }
    
    // Slight penalty for moving king unless castling
    if m.role() == Role::King && !m.is_castle() {
        score -= 50;
    }

    score
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

fn to_uci(m: &Move) -> String {
    let from_str = m.from().map_or("".to_string(), |s| s.to_string());
    let to_str = m.to().to_string();
    let promo_str = match m {
        Move::Normal { promotion: Some(role), .. } => match role {
            Role::Queen => "q",
            Role::Rook => "r",
            Role::Bishop => "b",
            Role::Knight => "n",
            _ => "",
        },
        _ => "",
    };
    format!("{}{}{}", from_str, to_str, promo_str)
}

#[flutter_rust_bridge::frb(sync)]
pub fn generate_tactics_analysis(fen: String, user_uci_moves: Vec<String>) -> TacticsResult {
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

    let pos: Chess = match setup.into_position(CastlingMode::Standard) {
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
                            if let Ok(aligned_pos) = aligned_setup.into_position(CastlingMode::Standard) {
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
        format!("The sequence contains illegal moves after: {}.", user_san_moves.join(" "))
    } else {
        format!("Your proposed line leads to a position where pieces are active and tension is established.")
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
    let mut legal_starts: Vec<Move> = pos.legal_moves().into_iter().collect();
    
    // Sort legal starts by evaluate_move
    legal_starts.sort_by_key(|m| -evaluate_move(&pos, m));

    let names = vec!["Tactic Alpha", "Tactic Beta", "Tactic Gamma", "Tactic Delta", "Tactic Epsilon"];

    let user_first_move_uci = user_uci_moves.first();

    for m1 in legal_starts {
        if alternatives.len() >= limit {
            break;
        }

        let m1_uci = to_uci(&m1);
        
        // Let's make sure the first move is different from the user's first move if possible,
        // so that we show fresh tactical options.
        if let Some(user_first) = user_first_move_uci {
            if &m1_uci == user_first && pos.legal_moves().len() > 1 && alternatives.len() == 0 {
                // If it's the only move, we must generate it. But if there are alternatives,
                // skip user's first move for the first alternative card.
                continue;
            }
        }

        // Build sequence of length up to 4
        let mut sim_pos = pos.clone();
        let mut seq_moves = vec![m1_uci.clone()];
        let mut seq_san = vec![San::from_move(&sim_pos, &m1).to_string()];
        
        sim_pos.play_unchecked(&m1);

        // Turn 2 (Opponent response)
        if !sim_pos.is_game_over() {
            let mut opp_moves: Vec<Move> = sim_pos.legal_moves().into_iter().collect();
            if !opp_moves.is_empty() {
                opp_moves.sort_by_key(|m| -evaluate_move(&sim_pos, m));
                let m2 = opp_moves[0].clone();
                seq_moves.push(to_uci(&m2));
                seq_san.push(San::from_move(&sim_pos, &m2).to_string());
                sim_pos.play_unchecked(&m2);
            }
        }

        // Turn 3 (Player second move)
        if !sim_pos.is_game_over() {
            let mut play_moves: Vec<Move> = sim_pos.legal_moves().into_iter().collect();
            if !play_moves.is_empty() {
                play_moves.sort_by_key(|m| -evaluate_move(&sim_pos, m));
                let m3 = play_moves[0].clone();
                seq_moves.push(to_uci(&m3));
                seq_san.push(San::from_move(&sim_pos, &m3).to_string());
                sim_pos.play_unchecked(&m3);
            }
        }

        // Turn 4 (Opponent second response)
        if !sim_pos.is_game_over() {
            let mut opp_moves: Vec<Move> = sim_pos.legal_moves().into_iter().collect();
            if !opp_moves.is_empty() {
                opp_moves.sort_by_key(|m| -evaluate_move(&sim_pos, m));
                let m4 = opp_moves[0].clone();
                seq_moves.push(to_uci(&m4));
                seq_san.push(San::from_move(&sim_pos, &m4).to_string());
                sim_pos.play_unchecked(&m4);
            }
        }

        let name = names[alternatives.len()].to_string();
        let explanation = format!(
            "Initiating with {} creates distinct imbalances. A solid continuation path involves {}.",
            seq_san.first().unwrap_or(&"".to_string()),
            if seq_san.len() > 2 { seq_san[2].clone() } else { "rapid piece development".to_string() }
        );

        alternatives.push(TacticData {
            name,
            moves: seq_moves,
            san_moves: seq_san,
            explanation,
        });
    }

    // 3. Build Chanakya text response containing the hidden tags
    let mut prose = String::new();
    prose.push_str("I have analyzed your candidate lines, Apprentice. Here is my tactical report:\n\n");
    
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
    
    if piece_count <= 10 {
        prose.push_str("In this simplified endgame position, alternative paths are highly constrained, hence fewer lines are suggested.");
    } else {
        prose.push_str("Evaluate the pressure and structural changes of these choices before executing your move.");
    }

    TacticsResult {
        text_response: prose,
        your_tactic,
        alternatives,
    }
}
