use shakmaty::{
    fen::Fen, san::San, Board, CastlingMode, Chess, Color, EnPassantMode, Move, Position, Role,
    Square,
};
use std::collections::{HashMap, HashSet};
use std::sync::{Mutex, OnceLock};

const STANDARD_INITIAL_FEN: &str =
    "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

#[derive(Clone, Debug)]
pub struct SavedGameUci {
    pub recent_moves: Vec<String>,
    pub uci_moves: Vec<String>,
    pub initial_fen: Option<String>,
    pub final_fen: String,
    pub is_chess960: bool,
    pub is_player_white: bool,
    pub result: String,
    pub white_time_left_ms: i32,
    pub black_time_left_ms: i32,
    pub rating_category: String,
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
    pub total_rated_games: i32,
    pub analyzed_games: i32,
    pub skipped_games: i32,
}

struct ReplayedGame {
    moves: Vec<Move>,
    positions: Vec<Chess>,
    turn_colors: Vec<Color>,
}

#[derive(Default)]
struct GameIncidents {
    diagonal_retreats: bool,
    horizontal_swings: bool,
    knight_forks: bool,
    time_panic: bool,
    material_greed: bool,
    tunnel_vision: bool,
    pinned_pieces: bool,
    king_safety: bool,
}

static CHESS960_RECOVERY_CACHE: OnceLock<Mutex<HashMap<String, Option<String>>>> = OnceLock::new();

#[flutter_rust_bridge::frb(sync)]
pub fn analyze_scotoma(games: Vec<SavedGameUci>) -> ScotomaResult {
    let total_rated_games = games.len() as i32;
    let mut analyzed_games = 0_i32;
    let mut totals = [0_i32; 8];

    for game in &games {
        let replayed = match replay_game(game) {
            Some(replayed) if !replayed.moves.is_empty() => replayed,
            _ => continue,
        };

        analyzed_games += 1;
        let incidents = analyze_game(game, &replayed);
        let flags = [
            incidents.diagonal_retreats,
            incidents.horizontal_swings,
            incidents.knight_forks,
            incidents.time_panic,
            incidents.material_greed,
            incidents.tunnel_vision,
            incidents.pinned_pieces,
            incidents.king_safety,
        ];
        for (index, occurred) in flags.iter().enumerate() {
            if *occurred {
                totals[index] += 1;
            }
        }
    }

    let rate = |count: i32| -> f64 {
        if analyzed_games == 0 {
            0.0
        } else {
            count as f64 / analyzed_games as f64
        }
    };

    ScotomaResult {
        diagonal_retreats: rate(totals[0]),
        horizontal_swings: rate(totals[1]),
        knight_forks: rate(totals[2]),
        time_panic: rate(totals[3]),
        material_greed: rate(totals[4]),
        tunnel_vision: rate(totals[5]),
        pinned_pieces: rate(totals[6]),
        king_safety: rate(totals[7]),
        total_rated_games,
        analyzed_games,
        skipped_games: total_rated_games - analyzed_games,
    }
}

fn analyze_game(game: &SavedGameUci, replayed: &ReplayedGame) -> GameIncidents {
    let mut incidents = GameIncidents::default();
    if game.result != "L" {
        return incidents;
    }

    let player_time_left = if game.is_player_white {
        game.white_time_left_ms
    } else {
        game.black_time_left_ms
    };
    incidents.time_panic = player_time_left >= 0 && player_time_left < 45_000;

    let num_moves = replayed.moves.len();
    let start_ply = num_moves.saturating_sub(8);

    for ply in start_ply..num_moves {
        let chess_move = &replayed.moves[ply];
        let active_color = replayed.turn_colors[ply];
        let is_player_move = (active_color == Color::White) == game.is_player_white;
        let from_sq = match chess_move.from() {
            Some(square) => square,
            None => continue,
        };
        let to_sq = chess_move.to();
        let role = chess_move.role();
        let board_before = replayed.positions[ply].board();

        let is_diagonal_retreat = (role == Role::Bishop || role == Role::Queen) && {
            let dx = (to_sq.file() as i32 - from_sq.file() as i32).abs();
            let dy = (to_sq.rank() as i32 - from_sq.rank() as i32).abs();
            let is_retreat = if active_color == Color::White {
                to_sq.rank() < from_sq.rank()
            } else {
                to_sq.rank() > from_sq.rank()
            };
            dx == dy && dx >= 3 && is_retreat
        };

        let is_horizontal_swing = (role == Role::Rook || role == Role::Queen) && {
            let dx = (to_sq.file() as i32 - from_sq.file() as i32).abs();
            to_sq.rank() == from_sq.rank() && dx >= 3
        };

        let is_flank_knight = role == Role::Knight
            && (from_sq.file() == shakmaty::File::A
                || from_sq.file() == shakmaty::File::H
                || to_sq.file() == shakmaty::File::A
                || to_sq.file() == shakmaty::File::H);

        let is_pin_move = is_pinned(board_before, from_sq, active_color);

        if !is_player_move {
            incidents.diagonal_retreats |= is_diagonal_retreat;
            incidents.horizontal_swings |= is_horizontal_swing;
            incidents.knight_forks |= is_flank_knight;
            incidents.pinned_pieces |= is_pin_move;
            incidents.king_safety |= replayed.positions[ply + 1].is_check();
            continue;
        }

        if chess_move.is_capture() && ply + 1 < num_moves {
            let opponent_reply = &replayed.moves[ply + 1];
            incidents.material_greed |= opponent_reply.is_capture()
                || replayed
                    .positions
                    .get(ply + 2)
                    .is_some_and(|position| position.is_check());
        }

        if ply + 1 < num_moves {
            let opponent_reply = &replayed.moves[ply + 1];
            let player_file = to_sq.file() as i32;
            let opponent_file = opponent_reply.to().file() as i32;
            incidents.tunnel_vision |= (player_file - opponent_file).abs() >= 4;
        }
    }

    incidents.king_safety |= replayed
        .positions
        .last()
        .is_some_and(|position| position.is_check());
    incidents
}

fn replay_game(game: &SavedGameUci) -> Option<ReplayedGame> {
    if !game.uci_moves.is_empty() {
        let initial_fen = match game.initial_fen.as_deref() {
            Some(fen) => fen,
            None if !game.is_chess960 => STANDARD_INITIAL_FEN,
            None => return None,
        };
        return replay_uci(initial_fen, &game.uci_moves, game.is_chess960);
    }

    if game.recent_moves.is_empty() {
        return None;
    }

    if !game.is_chess960 {
        return replay_san(STANDARD_INITIAL_FEN, &game.recent_moves, false);
    }

    let recovered_fen = recover_chess960_initial_fen(&game.recent_moves, &game.final_fen)?;
    replay_san(&recovered_fen, &game.recent_moves, true)
}

fn replay_uci(initial_fen: &str, moves: &[String], is_chess960: bool) -> Option<ReplayedGame> {
    let mut position = parse_position(initial_fen, is_chess960)?;
    let mut replayed = ReplayedGame {
        moves: Vec::with_capacity(moves.len()),
        positions: vec![position.clone()],
        turn_colors: Vec::with_capacity(moves.len()),
    };

    for uci in moves {
        let chess_move = find_uci_move(&position, uci, is_chess960)?;
        replayed.turn_colors.push(position.turn());
        position.play_unchecked(&chess_move);
        replayed.positions.push(position.clone());
        replayed.moves.push(chess_move);
    }
    Some(replayed)
}

fn replay_san(initial_fen: &str, moves: &[String], is_chess960: bool) -> Option<ReplayedGame> {
    let mut position = parse_position(initial_fen, is_chess960)?;
    let mut replayed = ReplayedGame {
        moves: Vec::with_capacity(moves.len()),
        positions: vec![position.clone()],
        turn_colors: Vec::with_capacity(moves.len()),
    };

    for san_text in moves {
        let san = San::from_ascii(san_text.trim().as_bytes()).ok()?;
        let chess_move = san.to_move(&position).ok()?;
        replayed.turn_colors.push(position.turn());
        position.play_unchecked(&chess_move);
        replayed.positions.push(position.clone());
        replayed.moves.push(chess_move);
    }
    Some(replayed)
}

fn parse_position(fen: &str, is_chess960: bool) -> Option<Chess> {
    let normalized_fen = if is_chess960 {
        normalize_chess960_castling_rights(fen)?
    } else {
        fen.to_string()
    };
    let setup = normalized_fen.parse::<Fen>().ok()?;
    let mode = if is_chess960 {
        CastlingMode::Chess960
    } else {
        CastlingMode::Standard
    };
    setup.into_position(mode).ok()
}

fn normalize_chess960_castling_rights(fen: &str) -> Option<String> {
    let mut parts: Vec<String> = fen.split_whitespace().map(str::to_string).collect();
    if parts.len() < 6 || parts[2] == "-" {
        return Some(fen.to_string());
    }
    if !parts[2].chars().any(|right| matches!(right, 'K' | 'Q' | 'k' | 'q')) {
        return Some(fen.to_string());
    }

    let board_ranks: Vec<&str> = parts[0].split('/').collect();
    if board_ranks.len() != 8 {
        return None;
    }
    let white_back_rank = expand_fen_rank(board_ranks[7])?;
    let black_back_rank = expand_fen_rank(board_ranks[0])?;
    let rights = parts[2].clone();
    let mut normalized = String::new();

    for right in rights.chars() {
        let replacement = match right {
            'K' => rook_file_for_castling(&white_back_rank, 'K', 'R', true)?
                .to_ascii_uppercase(),
            'Q' => rook_file_for_castling(&white_back_rank, 'K', 'R', false)?
                .to_ascii_uppercase(),
            'k' => rook_file_for_castling(&black_back_rank, 'k', 'r', true)?,
            'q' => rook_file_for_castling(&black_back_rank, 'k', 'r', false)?,
            other => other,
        };
        if !normalized.contains(replacement) {
            normalized.push(replacement);
        }
    }
    parts[2] = if normalized.is_empty() {
        "-".to_string()
    } else {
        normalized
    };
    Some(parts.join(" "))
}

fn expand_fen_rank(rank: &str) -> Option<Vec<char>> {
    let mut expanded = Vec::with_capacity(8);
    for character in rank.chars() {
        if let Some(empty_count) = character.to_digit(10) {
            expanded.extend(std::iter::repeat_n('.', empty_count as usize));
        } else {
            expanded.push(character);
        }
    }
    (expanded.len() == 8).then_some(expanded)
}

fn rook_file_for_castling(
    rank: &[char],
    king: char,
    rook: char,
    kingside: bool,
) -> Option<char> {
    let king_file = rank.iter().position(|piece| *piece == king)?;
    let rook_file = if kingside {
        rank.iter()
            .enumerate()
            .filter_map(|(file, piece)| (*piece == rook && file > king_file).then_some(file))
            .min()?
    } else {
        rank.iter()
            .enumerate()
            .filter_map(|(file, piece)| (*piece == rook && file < king_file).then_some(file))
            .max()?
    };
    Some((b'a' + rook_file as u8) as char)
}

fn find_uci_move(position: &Chess, uci: &str, is_chess960: bool) -> Option<Move> {
    if uci.len() < 4 {
        return None;
    }
    let from_sq: Square = uci[0..2].parse().ok()?;
    let to_sq: Square = uci[2..4].parse().ok()?;
    let promotion = match uci.as_bytes().get(4).copied() {
        Some(b'q') => Some(Role::Queen),
        Some(b'r') => Some(Role::Rook),
        Some(b'b') => Some(Role::Bishop),
        Some(b'n') => Some(Role::Knight),
        Some(_) => return None,
        None => None,
    };

    position.legal_moves().into_iter().find(|chess_move| {
        if chess_move.from() != Some(from_sq) {
            return false;
        }
        let destination_matches = chess_move.to() == to_sq
            || matches!(
                chess_move,
                Move::Castle { rook, .. } if *rook == to_sq
            )
            || (!is_chess960
                && matches!(
                    chess_move,
                    Move::Castle { king, rook }
                        if (*king == Square::E1 && to_sq == Square::G1 && *rook == Square::H1)
                            || (*king == Square::E1 && to_sq == Square::C1 && *rook == Square::A1)
                            || (*king == Square::E8 && to_sq == Square::G8 && *rook == Square::H8)
                            || (*king == Square::E8 && to_sq == Square::C8 && *rook == Square::A8)
                ));
        let promotion_matches = match chess_move {
            Move::Normal {
                promotion: move_promotion,
                ..
            } => *move_promotion == promotion,
            _ => promotion.is_none(),
        };
        destination_matches && promotion_matches
    })
}

fn recover_chess960_initial_fen(san_moves: &[String], final_fen: &str) -> Option<String> {
    let cache_key = format!("{}|{}", final_fen, san_moves.join(" "));
    let cache = CHESS960_RECOVERY_CACHE.get_or_init(|| Mutex::new(HashMap::new()));
    if let Some(cached) = cache.lock().ok()?.get(&cache_key).cloned() {
        return cached;
    }

    let target_signature = fen_position_signature(final_fen)?;
    let mut matching_fen: Option<String> = None;

    for initial_fen in chess960_initial_fens() {
        let replayed = match replay_san(&initial_fen, san_moves, true) {
            Some(replayed) => replayed,
            None => continue,
        };
        let final_position = match replayed.positions.last() {
            Some(position) => position,
            None => continue,
        };
        if position_signature(final_position) != target_signature {
            continue;
        }
        if matching_fen.is_some() {
            matching_fen = None;
            break;
        }
        matching_fen = Some(initial_fen);
    }

    if let Ok(mut guard) = cache.lock() {
        guard.insert(cache_key, matching_fen.clone());
    }
    matching_fen
}

fn fen_position_signature(fen: &str) -> Option<String> {
    let position = parse_position(fen, true)?;
    Some(position_signature(&position))
}

fn position_signature(position: &Chess) -> String {
    let fen = Fen::from_position(position.clone(), EnPassantMode::Legal).to_string();
    fen.split_whitespace().take(2).collect::<Vec<_>>().join(" ")
}

fn chess960_initial_fens() -> Vec<String> {
    fn permute(pieces: &mut [char], index: usize, ranks: &mut HashSet<String>) {
        if index == pieces.len() {
            let bishop_files: Vec<usize> = pieces
                .iter()
                .enumerate()
                .filter_map(|(file, piece)| (*piece == 'B').then_some(file))
                .collect();
            if bishop_files.len() != 2 || bishop_files[0] % 2 == bishop_files[1] % 2 {
                return;
            }
            let king_file = match pieces.iter().position(|piece| *piece == 'K') {
                Some(file) => file,
                None => return,
            };
            let rook_files: Vec<usize> = pieces
                .iter()
                .enumerate()
                .filter_map(|(file, piece)| (*piece == 'R').then_some(file))
                .collect();
            if rook_files.len() == 2 && rook_files[0] < king_file && king_file < rook_files[1] {
                ranks.insert(pieces.iter().collect());
            }
            return;
        }

        let mut used = HashSet::new();
        for candidate in index..pieces.len() {
            if used.insert(pieces[candidate]) {
                pieces.swap(index, candidate);
                permute(pieces, index + 1, ranks);
                pieces.swap(index, candidate);
            }
        }
    }

    let mut pieces = ['R', 'R', 'N', 'N', 'B', 'B', 'Q', 'K'];
    let mut ranks = HashSet::new();
    permute(&mut pieces, 0, &mut ranks);

    let mut ranks: Vec<String> = ranks.into_iter().collect();
    ranks.sort();
    ranks
        .into_iter()
        .map(|white_rank| {
            let black_rank = white_rank.to_ascii_lowercase();
            format!(
                "{black_rank}/pppppppp/8/8/8/8/PPPPPPPP/{white_rank} w KQkq - 0 1"
            )
        })
        .collect()
}

fn is_pinned(board: &Board, square: Square, color: Color) -> bool {
    let opponent = !color;
    if let Some(king_square) = board.king_of(color) {
        if square == king_square {
            return false;
        }

        let mut board_without_piece = board.clone();
        let _ = board_without_piece.remove_piece_at(square);
        let occupied = board_without_piece.occupied();

        for opponent_square in board_without_piece.by_color(opponent) {
            if let Some(opponent_piece) = board_without_piece.piece_at(opponent_square) {
                let attacks =
                    shakmaty::attacks::attacks(opponent_square, opponent_piece, occupied);
                if attacks.contains(king_square) {
                    let original_attacks = shakmaty::attacks::attacks(
                        opponent_square,
                        opponent_piece,
                        board.occupied(),
                    );
                    if !original_attacks.contains(king_square) {
                        return true;
                    }
                }
            }
        }
    }
    false
}

#[cfg(test)]
mod tests {
    use super::*;

    fn game(moves: &[&str], result: &str) -> SavedGameUci {
        SavedGameUci {
            recent_moves: vec![],
            uci_moves: moves.iter().map(|move_text| move_text.to_string()).collect(),
            initial_fen: Some(STANDARD_INITIAL_FEN.to_string()),
            final_fen: String::new(),
            is_chess960: false,
            is_player_white: true,
            result: result.to_string(),
            white_time_left_ms: 60_000,
            black_time_left_ms: 60_000,
            rating_category: "blitz".to_string(),
        }
    }

    #[test]
    fn skips_malformed_games() {
        let result = analyze_scotoma(vec![game(&["e2e4", "bad"], "L")]);
        assert_eq!(result.total_rated_games, 1);
        assert_eq!(result.analyzed_games, 0);
        assert_eq!(result.skipped_games, 1);
    }

    #[test]
    fn migrates_legacy_standard_san() {
        let mut legacy = game(&[], "W");
        legacy.uci_moves.clear();
        legacy.initial_fen = None;
        legacy.recent_moves = vec!["e4", "e5", "Nf3", "Nc6"]
            .into_iter()
            .map(str::to_string)
            .collect();
        let result = analyze_scotoma(vec![legacy]);
        assert_eq!(result.analyzed_games, 1);
        assert_eq!(result.skipped_games, 0);
    }

    #[test]
    fn scoring_is_independent_of_game_order() {
        let first = game(&["e2e4", "e7e5", "g1f3", "b8c6"], "W");
        let mut second = first.clone();
        second.result = "L".to_string();
        second.white_time_left_ms = 30_000;

        let forward = analyze_scotoma(vec![first.clone(), second.clone()]);
        let reverse = analyze_scotoma(vec![second, first]);
        assert_eq!(forward.time_panic, reverse.time_panic);
        assert_eq!(forward.analyzed_games, reverse.analyzed_games);
    }

    #[test]
    fn replays_standard_castling_and_promotion() {
        let castling = game(
            &[
                "e2e4", "e7e5", "g1f3", "b8c6", "f1c4", "g8f6", "e1g1",
            ],
            "W",
        );
        let promotion = SavedGameUci {
            recent_moves: vec![],
            uci_moves: vec!["a7a8q".to_string()],
            initial_fen: Some("4k3/P7/8/8/8/8/8/4K3 w - - 0 1".to_string()),
            final_fen: String::new(),
            is_chess960: false,
            is_player_white: true,
            result: "W".to_string(),
            white_time_left_ms: 60_000,
            black_time_left_ms: 60_000,
            rating_category: "blitz".to_string(),
        };
        let result = analyze_scotoma(vec![castling, promotion]);
        assert_eq!(result.analyzed_games, 2);
        assert_eq!(result.skipped_games, 0);
    }

    #[test]
    fn generates_all_chess960_starting_positions() {
        let positions = chess960_initial_fens();
        assert_eq!(positions.len(), 960);
        assert!(positions.iter().all(|fen| parse_position(fen, true).is_some()));
    }

    #[test]
    fn replays_chess960_with_persisted_fen_and_uci() {
        let initial_fen = "bbrqknnr/pppppppp/8/8/8/8/PPPPPPPP/BBRQKNNR w KQkq - 0 1";
        let normalized = normalize_chess960_castling_rights(initial_fen).unwrap();
        assert!(normalized.contains("HChc"), "{normalized}");
        let position = parse_position(initial_fen, true).expect("Chess960 FEN should parse");
        assert!(
            find_uci_move(&position, "e2e4", true).is_some(),
            "e2e4 should be legal"
        );
        assert!(
            replay_uci(
                initial_fen,
                &["e2e4".to_string(), "e7e5".to_string()],
                true
            )
            .is_some(),
            "Chess960 UCI sequence should replay"
        );
        let chess960 = SavedGameUci {
            recent_moves: vec![],
            uci_moves: vec!["e2e4".to_string(), "e7e5".to_string()],
            initial_fen: Some(initial_fen.to_string()),
            final_fen: String::new(),
            is_chess960: true,
            is_player_white: true,
            result: "W".to_string(),
            white_time_left_ms: 60_000,
            black_time_left_ms: 60_000,
            rating_category: "blitz".to_string(),
        };
        let result = analyze_scotoma(vec![chess960]);
        assert_eq!(result.analyzed_games, 1);
    }

    #[test]
    fn replays_chess960_castling_to_rook_square() {
        let chess960 = SavedGameUci {
            recent_moves: vec![],
            uci_moves: vec!["b1h1".to_string()],
            initial_fen: Some("4k3/8/8/8/8/8/8/RK5R w KQ - 0 1".to_string()),
            final_fen: String::new(),
            is_chess960: true,
            is_player_white: true,
            result: "W".to_string(),
            white_time_left_ms: 60_000,
            black_time_left_ms: 60_000,
            rating_category: "blitz".to_string(),
        };
        let result = analyze_scotoma(vec![chess960]);
        assert_eq!(result.analyzed_games, 1);
    }

    #[test]
    fn recovers_legacy_chess960_from_san_and_final_fen() {
        let initial_fen = STANDARD_INITIAL_FEN;
        let uci_moves = vec![
            "e2e4".to_string(),
            "e7e5".to_string(),
            "g1f3".to_string(),
            "b8c6".to_string(),
        ];
        let replayed = replay_uci(initial_fen, &uci_moves, true).unwrap();
        let mut position = parse_position(initial_fen, true).unwrap();
        let mut san_moves = Vec::new();
        for chess_move in &replayed.moves {
            san_moves.push(San::from_move(&position, chess_move).to_string());
            position.play_unchecked(chess_move);
        }
        let final_fen = Fen::from_position(position, EnPassantMode::Legal).to_string();
        let legacy = SavedGameUci {
            recent_moves: san_moves,
            uci_moves: vec![],
            initial_fen: None,
            final_fen,
            is_chess960: true,
            is_player_white: true,
            result: "W".to_string(),
            white_time_left_ms: 60_000,
            black_time_left_ms: 60_000,
            rating_category: "blitz".to_string(),
        };
        let result = analyze_scotoma(vec![legacy]);
        assert_eq!(result.analyzed_games, 1);
        assert_eq!(result.skipped_games, 0);
    }
}
