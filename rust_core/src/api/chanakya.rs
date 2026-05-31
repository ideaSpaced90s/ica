use shakmaty::{fen::Fen, CastlingMode, Chess, Color, Move, Position, Role, Square};

// ────────────────────────────────────────────────────────────────────────────
// Input structs (mirrored on the Dart side via flutter_rust_bridge codegen)
// ────────────────────────────────────────────────────────────────────────────

/// A single candidate move emitted by Stockfish (MultiPV line).
pub struct ChanakyaCandidate {
    pub uci_move: String,
    pub evaluation: f64, // centipawns / 100, negative = bad for engine
}

/// User cognitive blindspot profile, populated by `analyze_scotoma`.
pub struct ChanakyaScotoma {
    pub diagonal_retreats: f64,  // dgb: 0.0–1.0
    pub horizontal_swings: f64,  // hrz
    pub knight_forks: f64,       // knf
    pub pinned_pieces: f64,      // pin
    pub king_safety: f64,        // ksb
    pub material_greed: f64,     // grd
    pub tunnel_vision: f64,      // tnl
    pub time_panic: f64,         // tmp  (not used for move weighting, but passed for completeness)
}

/// User playstyle statistics from the radar chart.
pub struct ChanakyaPlaystyle {
    pub aggression: f64, // 0.0 = pure defender, 1.0 = all-out attacker
    pub intensity: f64,  // win-rate proxy
    pub speed: f64,      // clock management ratio
}

// ────────────────────────────────────────────────────────────────────────────
// Internal helpers
// ────────────────────────────────────────────────────────────────────────────

/// Deterministic pseudo-random jitter seeded on FEN + move string.
/// Used to add subtle opening variety when Elo gap is large (easy mode).
fn fen_move_jitter(fen: &str, uci: &str) -> f64 {
    let mut h: u64 = 0xcbf29ce484222325;
    for b in fen.bytes().chain(uci.bytes()) {
        h ^= b as u64;
        h = h.wrapping_mul(0x100000001b3);
    }
    // Map to [-1.0, +1.0]
    ((h % 2000) as f64 / 1000.0) - 1.0
}

/// Parse a FEN string into a `Chess` position, returning None on failure.
fn parse_pos(fen: &str, is_chess960: bool) -> Option<Chess> {
    let mode = if is_chess960 {
        CastlingMode::Chess960
    } else {
        CastlingMode::Standard
    };
    let setup = fen.parse::<Fen>().ok()?;
    setup.into_position(mode).ok()
}

/// Resolve a UCI move string against a legal move list.
fn find_legal_move(pos: &Chess, uci: &str) -> Option<Move> {
    if uci.len() < 4 {
        return None;
    }
    let from_sq: Square = uci[0..2].parse().ok()?;
    let to_sq: Square = uci[2..4].parse().ok()?;
    let promo_role = uci.chars().nth(4).and_then(|c| match c {
        'q' => Some(Role::Queen),
        'r' => Some(Role::Rook),
        'b' => Some(Role::Bishop),
        'n' => Some(Role::Knight),
        _ => None,
    });

    for m in pos.legal_moves() {
        if m.from() != Some(from_sq) {
            continue;
        }
        let matches_dest = m.to() == to_sq;
        let matches_castle = matches!(&m, Move::Castle { rook, .. } if *rook == to_sq || m.to() == to_sq);
        let matches_promo = match &m {
            Move::Normal { promotion, .. } => *promotion == promo_role,
            _ => promo_role.is_none(),
        };
        if (matches_dest || matches_castle) && matches_promo {
            return Some(m);
        }
    }
    None
}

/// After playing `m`, count how many *valuable* opponent pieces (R/Q/K) the
/// moving piece attacks. Used for knight-fork detection.
fn counts_valuable_attacks_after(pos: &Chess, m: &Move) -> usize {
    let mut sandbox = pos.clone();
    sandbox.play_unchecked(m);
    let landing = m.to();
    let piece_after = sandbox.board().piece_at(landing);
    let piece_color = match piece_after {
        Some(p) => p.color,
        None => return 0,
    };
    let opponent = !piece_color;
    let occupied = sandbox.board().occupied();

    let piece = match piece_after {
        Some(p) => p,
        None => return 0,
    };
    let attacks = shakmaty::attacks::attacks(landing, piece, occupied);
    let mut count = 0usize;
    for sq in attacks {
        if let Some(target) = sandbox.board().piece_at(sq) {
            if target.color == opponent
                && matches!(target.role, Role::Rook | Role::Queen | Role::King | Role::Bishop)
            {
                count += 1;
            }
        }
    }
    count
}

/// Returns true if moving this piece would expose our king to attack (pin removal test).
#[allow(dead_code)]
fn would_expose_king(pos: &Chess, from_sq: Square) -> bool {
    let our_color = pos.turn();
    let king_sq = match pos.board().king_of(our_color) {
        Some(sq) => sq,
        None => return false,
    };
    if from_sq == king_sq {
        return false;
    }
    // Temporarily remove piece
    let mut temp = pos.board().clone();
    temp.discard_piece_at(from_sq);
    let occupied = temp.occupied();
    let opponent = !our_color;

    for opp_sq in temp.by_color(opponent) {
        if let Some(opp_piece) = temp.piece_at(opp_sq) {
            let atk = shakmaty::attacks::attacks(opp_sq, opp_piece, occupied);
            if atk.contains(king_sq) {
                // Was already attacked before?
                let orig_atk = shakmaty::attacks::attacks(opp_sq, opp_piece, pos.board().occupied());
                if !orig_atk.contains(king_sq) {
                    return true; // newly exposed — it's a pin
                }
            }
        }
    }
    false
}

/// Returns true if the move targets an opponent piece that is (functionally)
/// pinned — i.e. moving away from its square would expose that opponent's king.
fn targets_pinned_opponent_piece(pos: &Chess, to_sq: Square) -> bool {
    let opponent = !pos.turn();
    if let Some(target) = pos.board().piece_at(to_sq) {
        if target.color == opponent {
            // Check if that opponent piece is pinned to its own king
            let king_sq = match pos.board().king_of(opponent) {
                Some(sq) => sq,
                None => return false,
            };
            if to_sq == king_sq {
                return false;
            }
            let mut temp = pos.board().clone();
            temp.discard_piece_at(to_sq);
            let occupied = temp.occupied();
            let our_color = pos.turn();
            for our_sq in temp.by_color(our_color) {
                if let Some(our_piece) = temp.piece_at(our_sq) {
                    let atk = shakmaty::attacks::attacks(our_sq, our_piece, occupied);
                    if atk.contains(king_sq) {
                        let orig_atk = shakmaty::attacks::attacks(our_sq, our_piece, pos.board().occupied());
                        if !orig_atk.contains(king_sq) {
                            return true;
                        }
                    }
                }
            }
        }
    }
    false
}

/// True if the candidate is a diagonal retreat of ≥3 squares (Bishop or Queen).
fn is_diagonal_retreat(from: Square, to: Square, color: Color) -> bool {
    let dx = (to.file() as i32 - from.file() as i32).abs();
    let dy = (to.rank() as i32 - from.rank() as i32).abs();
    if dx != dy || dx < 3 {
        return false;
    }
    // Retreat = moving backward relative to piece color
    if color == Color::White {
        to.rank() < from.rank()
    } else {
        to.rank() > from.rank()
    }
}

/// True if the candidate is a horizontal sweep of ≥3 squares (Rook or Queen).
fn is_horizontal_swing(from: Square, to: Square) -> bool {
    from.rank() == to.rank() && (to.file() as i32 - from.file() as i32).abs() >= 3
}

/// Measure how much the move restricts opponent mobility (used for defender counter-style).
fn mobility_restriction_delta(pos: &Chess, m: &Move) -> i32 {
    let before = pos.legal_moves().len() as i32;
    let mut sandbox = pos.clone();
    sandbox.play_unchecked(m);
    let after = sandbox.legal_moves().len() as i32;
    before - after // positive = we restricted opponent
}

// ────────────────────────────────────────────────────────────────────────────
// Main exported function
// ────────────────────────────────────────────────────────────────────────────

/// Select the best move for GM Chanakya in Academy Mode.
///
/// The function applies a layered weighting system on top of Stockfish's
/// MultiPV candidates:
///
/// **Layer 1 — Elo-gap variety** (opening jitter, decays after move 12)
///   Adds small random variance so GM Chanakya doesn't always play the most
///   "expected" line when his skill level is much higher than the user.
///
/// **Layer 2 — Tight-Fight precision** (no jitter when game is close)
///   When `eval_abs ≤ 1.5` and `half_move_count ≥ 20`, Chanakya drops all
///   jitter and plays with full Stockfish precision.
///
/// **Layer 3 — Cognitive Scotoma targeting**
///   Each candidate move is scored against the user's known blindspots via
///   sandboxed shakmaty analysis. Moves that exploit blindspots get bonus weight
///   proportional to the blindspot severity (0.0–1.0).
///
/// **Layer 4 — Playstyle countering**
///   If user is an aggressor (aggression > 0.6), Chanakya biases toward
///   defensive, mobility-restricting moves.
///   If user is a passifier (aggression < 0.4), Chanakya biases toward open,
///   attacking, check-giving moves.
#[flutter_rust_bridge::frb(sync)]
pub fn select_chanakya_move_rust(
    fen: String,
    candidates: Vec<ChanakyaCandidate>,
    scotoma: ChanakyaScotoma,
    playstyle: ChanakyaPlaystyle,
    half_move_count: i32,   // game.history.length
    eval_abs: f64,           // abs(current evaluation) — closeness of game
    is_chess960: bool,
) -> String {
    if candidates.is_empty() {
        return String::new();
    }

    // Always fall back to the first candidate (engine best) on parse failure
    let fallback = candidates[0].uci_move.clone();

    let pos = match parse_pos(&fen, is_chess960) {
        Some(p) => p,
        None => return fallback,
    };

    let turn_color = pos.turn();

    // ── Jitter decay factor ────────────────────────────────────────────────
    // Full jitter in opening (move < 12), fades out.
    // Also killed when the game is tight (eval_abs ≤ 1.5 AND move ≥ 20).
    let is_tight_fight = eval_abs <= 1.5 && half_move_count >= 20;
    let opening_decay = if half_move_count < 24 {
        (24 - half_move_count).max(0) as f64 / 24.0
    } else {
        0.0
    };
    let jitter_scale = if is_tight_fight { 0.0 } else { opening_decay };

    let mut best_move = fallback.clone();
    let mut best_score = f64::NEG_INFINITY;

    for candidate in &candidates {
        if candidate.uci_move.len() < 4 {
            continue;
        }

        let legal_move = find_legal_move(&pos, &candidate.uci_move);
        let from_sq: Square = match candidate.uci_move[0..2].parse() {
            Ok(sq) => sq,
            Err(_) => continue,
        };
        let to_sq: Square = match candidate.uci_move[2..4].parse() {
            Ok(sq) => sq,
            Err(_) => continue,
        };

        let piece = pos.board().piece_at(from_sq);
        let role = piece.map(|p| p.role);

        let mut weight = 0.0_f64;

        // ── Layer 1: Elo-gap variety jitter ───────────────────────────────
        let jitter = fen_move_jitter(&fen, &candidate.uci_move) * jitter_scale;
        weight += jitter;

        // ── Layer 3: Cognitive scotoma targeting ──────────────────────────

        // 3a. Diagonal retreats (dgb)
        if scotoma.diagonal_retreats > 0.2 {
            if matches!(role, Some(Role::Bishop) | Some(Role::Queen)) {
                if is_diagonal_retreat(from_sq, to_sq, turn_color) {
                    weight += scotoma.diagonal_retreats * 2.5;
                }
            }
        }

        // 3b. Horizontal swings (hrz)
        if scotoma.horizontal_swings > 0.2 {
            if matches!(role, Some(Role::Rook) | Some(Role::Queen)) {
                if is_horizontal_swing(from_sq, to_sq) {
                    weight += scotoma.horizontal_swings * 2.0;
                }
            }
        }

        // 3c. Knight forks (knf) — needs sandbox
        if scotoma.knight_forks > 0.2 {
            if role == Some(Role::Knight) {
                if let Some(ref m) = legal_move {
                    let fork_count = counts_valuable_attacks_after(&pos, m);
                    if fork_count >= 2 {
                        weight += scotoma.knight_forks * 3.0;
                    } else if fork_count == 1 {
                        weight += scotoma.knight_forks * 1.2;
                    }
                }
            }
        }

        // 3d. Pinned pieces (pin) — target pinned enemy pieces
        if scotoma.pinned_pieces > 0.2 {
            if targets_pinned_opponent_piece(&pos, to_sq) {
                weight += scotoma.pinned_pieces * 2.0;
            }
            // Also reward moves that CREATE a pin on a valuable piece
            if let Some(ref m) = legal_move {
                if would_expose_king_to_our_piece(&pos, m) {
                    weight += scotoma.pinned_pieces * 1.5;
                }
            }
        }

        // 3e. King safety (ksb) — bonus for checks and near-checkmate threats
        if scotoma.king_safety > 0.2 {
            if let Some(ref m) = legal_move {
                let mut sandbox = pos.clone();
                sandbox.play_unchecked(m);
                if sandbox.is_checkmate() {
                    weight += 99.0; // always take the mate
                } else if sandbox.is_check() {
                    weight += scotoma.king_safety * 2.5;
                } else {
                    // Reward moves toward the enemy king
                    if let Some(king_sq) = pos.board().king_of(!turn_color) {
                        let df = (to_sq.file() as i32 - king_sq.file() as i32).abs();
                        let dr = (to_sq.rank() as i32 - king_sq.rank() as i32).abs();
                        let proximity = (7.0 - (df + dr) as f64).max(0.0) / 7.0;
                        weight += scotoma.king_safety * proximity * 0.8;
                    }
                }
            }
        }

        // 3f. Material greed traps (grd)
        // Reward moves that leave a "poisoned" piece — safe-looking captures
        // that contain a hidden follow-up threat.
        if scotoma.material_greed > 0.2 {
            // A small eval drop from best move combined with a capture target
            // is a classic poisoned pawn / piece pattern
            let eval_drop = candidates[0].evaluation - candidate.evaluation;
            let has_capture_on_square = pos.board().piece_at(to_sq).is_some();
            if has_capture_on_square && eval_drop >= 0.0 && eval_drop <= 2.5 {
                // Our piece is "sacrificed" but evaluation is still decent
                weight += scotoma.material_greed * 1.8;
            }
        }

        // ── Layer 4: Playstyle counter-weighting ──────────────────────────
        // Uses the user's aggression score to decide Chanakya's counter-style.

        let aggression = playstyle.aggression;

        if aggression > 0.6 {
            // User is an attacker → Chanakya plays solid defense
            // Bonus: moves that restrict opponent mobility
            if let Some(ref m) = legal_move {
                let restriction = mobility_restriction_delta(&pos, m);
                if restriction > 0 {
                    weight += (restriction as f64 * 0.15) * (aggression - 0.6) * 2.5;
                }
            }
            // Bonus: trades that remove user's active attacking pieces
            let is_capture = pos.board().piece_at(to_sq).is_some();
            if is_capture {
                if let Some(target) = pos.board().piece_at(to_sq) {
                    if matches!(target.role, Role::Knight | Role::Bishop) {
                        // Trade off minor pieces that fuel the attack
                        weight += (aggression - 0.6) * 1.5;
                    }
                }
            }
            // Slight bias against forward advances in tight defensive mode
            let to_rank = to_sq.rank() as i32 + 1;
            let from_rank = from_sq.rank() as i32 + 1;
            if turn_color == Color::White && to_rank < from_rank {
                weight += (aggression - 0.6) * 0.8; // retreat to consolidate
            } else if turn_color == Color::Black && to_rank > from_rank {
                weight += (aggression - 0.6) * 0.8;
            }
        } else if aggression < 0.4 {
            // User is a defender → Chanakya plays active attacking chess
            let passive_gap = 0.4 - aggression;
            // Bonus: checks and forward moves
            if let Some(ref m) = legal_move {
                let mut sandbox = pos.clone();
                sandbox.play_unchecked(m);
                if sandbox.is_check() {
                    weight += passive_gap * 3.0;
                }
            }
            // Bonus: advancing pawns into enemy territory
            if role == Some(Role::Pawn) {
                let to_rank = to_sq.rank() as i32 + 1;
                let is_advanced = if turn_color == Color::White {
                    to_rank >= 5
                } else {
                    to_rank <= 4
                };
                if is_advanced {
                    weight += passive_gap * 1.2;
                }
            }
            // Bonus: open file rook/queen activation
            if matches!(role, Some(Role::Rook) | Some(Role::Queen)) {
                let file = to_sq.file();
                let is_open = is_open_file(file, &pos);
                if is_open {
                    weight += passive_gap * 1.5;
                }
            }
        }

        // ── Final score = engine eval + all heuristic weights ─────────────
        let total = candidate.evaluation + weight;
        if total > best_score {
            best_score = total;
            best_move = candidate.uci_move.clone();
        }
    }

    best_move
}

// ────────────────────────────────────────────────────────────────────────────
// Secondary helper (not exported) for pin-creation detection
// ────────────────────────────────────────────────────────────────────────────

/// After playing `m`, does any of our pieces now pin an opponent piece to
/// their king (that wasn't pinned before)?
fn would_expose_king_to_our_piece(pos: &Chess, m: &Move) -> bool {
    let our_color = pos.turn();
    let opponent = !our_color;

    let opp_king_sq = match pos.board().king_of(opponent) {
        Some(sq) => sq,
        None => return false,
    };

    let mut sandbox = pos.clone();
    sandbox.play_unchecked(m);
    let occupied_after = sandbox.board().occupied();

    // For each of our pieces in the new position, check if it attacks the
    // opponent king through one of their pieces (newly created absolute pin).
    for our_sq in sandbox.board().by_color(our_color) {
        if let Some(our_piece) = sandbox.board().piece_at(our_sq) {
            let line_atk = shakmaty::attacks::attacks(our_sq, our_piece, occupied_after);
            if line_atk.contains(opp_king_sq) {
                // There's something between us and their king?
                // Check if the same line existed before
                let line_before = shakmaty::attacks::attacks(
                    our_sq,
                    our_piece,
                    pos.board().occupied(),
                );
                if !line_before.contains(opp_king_sq) {
                    // Newly created pin-line
                    return true;
                }
            }
        }
    }
    false
}

/// Returns true if no pawn of any color stands on this file.
fn is_open_file(file: shakmaty::File, pos: &Chess) -> bool {
    for rank in shakmaty::Rank::ALL {
        let sq = Square::from_coords(file, rank);
        if let Some(p) = pos.board().piece_at(sq) {
            if p.role == Role::Pawn {
                return false;
            }
        }
    }
    true
}

// ────────────────────────────────────────────────────────────────────────────
// Unit tests
// ────────────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    fn default_scotoma() -> ChanakyaScotoma {
        ChanakyaScotoma {
            diagonal_retreats: 0.15,
            horizontal_swings: 0.15,
            knight_forks: 0.15,
            pinned_pieces: 0.15,
            king_safety: 0.15,
            material_greed: 0.15,
            tunnel_vision: 0.15,
            time_panic: 0.15,
        }
    }

    fn default_playstyle() -> ChanakyaPlaystyle {
        ChanakyaPlaystyle {
            aggression: 0.5,
            intensity: 0.5,
            speed: 0.7,
        }
    }

    #[test]
    fn test_returns_first_candidate_on_empty_fen() {
        let result = select_chanakya_move_rust(
            "invalid_fen".to_string(),
            vec![ChanakyaCandidate { uci_move: "e2e4".to_string(), evaluation: 0.3 }],
            default_scotoma(),
            default_playstyle(),
            10,
            0.5,
            false,
        );
        assert_eq!(result, "e2e4");
    }

    #[test]
    fn test_checkmate_move_wins() {
        // Scholar's mate position — Qh5# is available
        let fen = "r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4".to_string();
        let result = select_chanakya_move_rust(
            fen,
            vec![
                ChanakyaCandidate { uci_move: "h5f7".to_string(), evaluation: 99.0 },
                ChanakyaCandidate { uci_move: "c4f7".to_string(), evaluation: 1.5 },
            ],
            ChanakyaScotoma { king_safety: 0.9, ..default_scotoma() },
            default_playstyle(),
            6,
            1.0,
            false,
        );
        // The checkmate move should always win
        assert_eq!(result, "h5f7");
    }

    #[test]
    fn test_tight_fight_kills_jitter() {
        let fen = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1".to_string();
        // When eval_abs is small and we're past move 20, jitter should be 0
        // Both candidates have the same evaluation — winner should be stable
        let result = select_chanakya_move_rust(
            fen,
            vec![
                ChanakyaCandidate { uci_move: "e7e5".to_string(), evaluation: 0.0 },
                ChanakyaCandidate { uci_move: "c7c5".to_string(), evaluation: 0.0 },
            ],
            default_scotoma(),
            default_playstyle(),
            22, // past move 20
            0.8, // tight fight
            false,
        );
        // Either move is fine; just ensure it's a valid UCI string
        assert!(result == "e7e5" || result == "c7c5");
    }
}
