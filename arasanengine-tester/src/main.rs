use shakmaty::{Chess, Position, CastlingMode};
use shakmaty::fen::Fen;
use std::io::{Write, BufReader, BufRead};
use std::process::{Command, Stdio};
use std::sync::{Arc, Mutex};
use std::thread;

// Mathematical Chess960 deterministic FEN generator
fn generate_all_960_fens() -> Vec<String> {
    let mut fens = Vec::new();
    for lb in 0..4 {
        let light_bishop = 1 + 2 * lb;
        for db in 0..4 {
            let dark_bishop = 2 * db;
            for q in 0..6 {
                for n1 in 0..5 {
                    for n2 in 0..4 {
                        let mut rank1 = [None; 8];
                        rank1[light_bishop] = Some('B');
                        rank1[dark_bishop] = Some('B');

                        // Place Queen
                        let mut q_slot = 0;
                        for i in 0..8 {
                            if rank1[i].is_none() {
                                if q_slot == q {
                                    rank1[i] = Some('Q');
                                    break;
                                }
                                q_slot += 1;
                            }
                        }

                        // Place Knights
                        let mut n1_slot = 0;
                        for i in 0..8 {
                            if rank1[i].is_none() {
                                if n1_slot == n1 {
                                    rank1[i] = Some('N');
                                    break;
                                }
                                n1_slot += 1;
                            }
                        }
                        let mut n2_slot = 0;
                        for i in 0..8 {
                            if rank1[i].is_none() {
                                if n2_slot == n2 {
                                    rank1[i] = Some('N');
                                    break;
                                }
                                n2_slot += 1;
                            }
                        }

                        // Place Rooks and King
                        let mut empty_indices = Vec::new();
                        for i in 0..8 {
                            if rank1[i].is_none() {
                                empty_indices.push(i);
                            }
                        }
                        if empty_indices.len() == 3 {
                            rank1[empty_indices[0]] = Some('R');
                            rank1[empty_indices[1]] = Some('K');
                            rank1[empty_indices[2]] = Some('R');

                            let white_pieces: String = rank1.iter().map(|p| p.unwrap()).collect();
                            let black_pieces = white_pieces.to_lowercase();
                            let fen = format!(
                                "{}/pppppppp/8/8/8/8/PPPPPPPP/{} w KQkq - 0 1",
                                black_pieces, white_pieces
                            );
                            if !fens.contains(&fen) {
                                fens.push(fen);
                            }
                        }
                    }
                }
            }
        }
    }
    fens
}

fn perft<P: Position + Clone>(pos: P, depth: usize) -> u64 {
    if depth == 0 {
        return 1;
    }
    let moves = pos.legal_moves();
    if depth == 1 {
        return moves.len() as u64;
    }
    let mut nodes = 0;
    for m in moves {
        let mut next_pos = pos.clone();
        next_pos.play_unchecked(&m);
        nodes += perft(next_pos, depth - 1);
    }
    nodes
}

fn get_arasan_perft(fen: &str, depth: usize) -> u64 {
    let mut child = Command::new(r#"f:\CHESSACADEMY\packages\arasan_chess_engine\src\win64\release\arasanx-64-modern.exe"#)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .expect("Failed to spawn arasan");

    let mut stdin = child.stdin.take().unwrap();
    let stdout = child.stdout.take().unwrap();
    let mut reader = BufReader::new(stdout);

    // Send UCI commands to native Windows executable
    write!(stdin, "uci\n").unwrap();
    write!(stdin, "isready\n").unwrap();
    write!(stdin, "setoption name UCI_Chess960 value true\n").unwrap();
    write!(stdin, "position fen {}\n", fen).unwrap();
    write!(stdin, "perft {}\n", depth).unwrap();
    write!(stdin, "quit\n").unwrap();

    let mut nodes = 0;
    let mut line = String::new();
    while reader.read_line(&mut line).unwrap() > 0 {
        if line.starts_with("perft ") {
            if let Some(pos_eq) = line.find(" = ") {
                let count_str = line[pos_eq + 3..].trim();
                nodes = count_str.parse::<u64>().unwrap_or(0);
            }
        }
        line.clear();
    }
    let _ = child.wait();
    nodes
}

fn get_arasan_perft_with_moves(fen: &str, moves: &str, depth: usize) -> u64 {
    let mut child = Command::new(r#"f:\CHESSACADEMY\packages\arasan_chess_engine\src\win64\release\arasanx-64-modern.exe"#)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .expect("Failed to spawn arasan");

    let mut stdin = child.stdin.take().unwrap();
    let stdout = child.stdout.take().unwrap();
    let mut reader = BufReader::new(stdout);

    write!(stdin, "uci\n").unwrap();
    write!(stdin, "isready\n").unwrap();
    write!(stdin, "setoption name UCI_Chess960 value true\n").unwrap();
    write!(stdin, "position fen {} moves {}\n", fen, moves).unwrap();
    write!(stdin, "perft {}\n", depth).unwrap();
    write!(stdin, "quit\n").unwrap();

    let mut nodes = 0;
    let mut line = String::new();
    while reader.read_line(&mut line).unwrap() > 0 {
        if line.starts_with("perft ") {
            if let Some(pos_eq) = line.find(" = ") {
                let count_str = line[pos_eq + 3..].trim();
                nodes = count_str.parse::<u64>().unwrap_or(0);
            }
        }
        line.clear();
    }
    let _ = child.wait();
    nodes
}

fn get_arasan_moves(fen: &str, moves: &str) -> Vec<String> {
    let mut child = Command::new(r#"f:\CHESSACADEMY\packages\arasan_chess_engine\src\win64\release\arasanx-64-modern.exe"#)
        .arg("-t")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .expect("Failed to spawn arasan");

    let mut stdin = child.stdin.take().unwrap();
    let stdout = child.stdout.take().unwrap();
    let mut reader = BufReader::new(stdout);

    write!(stdin, "uci\n").unwrap();
    write!(stdin, "isready\n").unwrap();
    write!(stdin, "setoption name UCI_Chess960 value true\n").unwrap();
    if moves.is_empty() {
        write!(stdin, "position fen {}\n", fen).unwrap();
    } else {
        write!(stdin, "position fen {} moves {}\n", fen, moves).unwrap();
    }
    write!(stdin, "perft 1\n").unwrap();
    write!(stdin, "quit\n").unwrap();

    let mut arasan_moves = Vec::new();
    let mut line = String::new();
    while reader.read_line(&mut line).unwrap() > 0 {
        if line.starts_with("info string move ") {
            let mv = line["info string move ".len()..].trim().to_string();
            arasan_moves.push(mv);
        }
        line.clear();
    }
    let _ = child.wait();
    arasan_moves
}

// Trace the exact sequence of moves leading to the discrepancy
fn find_divergent_path(start_fen: &str, depth: usize, path: &mut Vec<String>) {
    let fen_struct: Fen = start_fen.parse().expect("Failed to parse FEN");
    let mut pos: Chess = fen_struct.into_position(CastlingMode::Chess960).expect("Failed into position");

    // Replay the moves played so far
    for mv_str in path.iter() {
        let uci: shakmaty::uci::Uci = mv_str.parse().expect("Failed parsing UCI in path");
        let m = uci.to_move(&pos).expect("Failed generating move from UCI");
        pos.play_unchecked(&m);
    }

    let moves_str = path.join(" ");
    let arasan_count = if path.is_empty() {
        get_arasan_perft(start_fen, depth)
    } else {
        get_arasan_perft_with_moves(start_fen, &moves_str, depth)
    };
    let shakmaty_count = perft(pos.clone(), depth);

    if arasan_count == shakmaty_count {
        return;
    }

    if depth == 1 {
        println!("  - Divergence located at Depth 1!");
        println!("    Arasan legal moves count: {}", arasan_count);
        println!("    Shakmaty legal moves count: {}", shakmaty_count);
        
        let mut arasan_moves = get_arasan_moves(start_fen, &moves_str);
        let mut shakmaty_moves: Vec<String> = pos.legal_moves()
            .iter()
            .map(|m| m.to_uci(CastlingMode::Chess960).to_string())
            .collect();

        for mv in &arasan_moves {
            if !shakmaty_moves.contains(mv) {
                println!("    -> Arasan-only move: {}", mv);
            }
        }
        for mv in &shakmaty_moves {
            if !arasan_moves.contains(mv) {
                println!("    -> Shakmaty-only move: {}", mv);
            }
        }

        arasan_moves.sort();
        shakmaty_moves.sort();

        println!("    Arasan legal moves: {:?}", arasan_moves);
        println!("    Shakmaty legal moves: {:?}", shakmaty_moves);
        return;
    }

    for m in pos.legal_moves() {
        let uci_move = m.to_uci(CastlingMode::Chess960).to_string();
        let mut next_pos = pos.clone();
        next_pos.play_unchecked(&m);

        path.push(uci_move.clone());
        let next_moves_str = path.join(" ");
        let next_arasan = get_arasan_perft_with_moves(start_fen, &next_moves_str, depth - 1);
        let next_shakmaty = perft(next_pos, depth - 1);

        if next_arasan != next_shakmaty {
            find_divergent_path(start_fen, depth - 1, path);
            return;
        }
        path.pop();
    }
}

fn run_phase(fens: &[String], depth: usize) -> Result<(), (String, usize, u64, u64, Vec<String>)> {
    println!("Starting Stage validation to Depth {}...", depth);
    let total = fens.len();
    
    // Shared thread pool jobs
    let mut jobs = Vec::new();
    for (i, fen) in fens.iter().enumerate() {
        jobs.push((i, fen.clone()));
    }
    
    let jobs_arc = Arc::new(Mutex::new(jobs));
    let result_mismatch = Arc::new(Mutex::new(None));
    
    let mut threads = Vec::new();
    let num_threads = 12; // Ryzen 5 5600GT logical threads
    
    for _ in 0..num_threads {
        let jobs = jobs_arc.clone();
        let mismatch = result_mismatch.clone();
        
        threads.push(thread::spawn(move || {
            loop {
                // If any thread already found a mismatch, stop immediately
                if mismatch.lock().unwrap().is_some() {
                    break;
                }
                
                let job = {
                    let mut lock = jobs.lock().unwrap();
                    lock.pop()
                };
                
                match job {
                    Some((idx, fen)) => {
                        let fen_struct: Fen = fen.parse().unwrap();
                        let pos: Chess = fen_struct.into_position(CastlingMode::Chess960).unwrap();
                        
                        let shakmaty_count = perft(pos, depth);
                        let arasan_count = get_arasan_perft(&fen, depth);
                        
                        if shakmaty_count != arasan_count {
                            let mut lock = mismatch.lock().unwrap();
                            if lock.is_none() {
                                *lock = Some((fen, shakmaty_count, arasan_count));
                            }
                            break;
                        }
                        
                        if (idx + 1) % 100 == 0 || idx == total - 1 {
                            println!("  Tested {}/{} positions successfully...", idx + 1, total);
                        }
                    }
                    None => break,
                }
            }
        }));
    }
    
    for t in threads {
        let _ = t.join();
    }
    
    let opt = result_mismatch.lock().unwrap().take();
    if let Some((fen, expected, actual)) = opt {
        let mut path = Vec::new();
        find_divergent_path(&fen, depth, &mut path);
        Err((fen, depth, expected, actual, path))
    } else {
        Ok(())
    }
}

fn main() {
    println!("=== CHESS960 PERFT DIFFERENTIAL VALIDATION FRAMEWORK ===");
    println!("Generating all 960 starting positions...");
    let fens = generate_all_960_fens();
    assert_eq!(fens.len(), 960, "Must generate exactly 960 positions");
    println!("Successfully generated exactly 960 positions.");

    // Stage 1: Depth 4
    match run_phase(&fens, 4) {
        Ok(_) => println!("Stage 1 (Depth 4) completed successfully! All 960 positions match."),
        Err((fen, d, expected, actual, path)) => {
            println!("\n[ERROR] Stage 1 Mismatch detected!");
            println!("  FEN: {}", fen);
            println!("  Depth: {}", d);
            println!("  Expected (Shakmaty): {}", expected);
            println!("  Actual (Arasan):     {}", actual);
            println!("  Divergent Move Path: {:?}", path);
            std::process::exit(1);
        }
    }

    // Stage 2: Depth 5
    match run_phase(&fens, 5) {
        Ok(_) => println!("Stage 2 (Depth 5) completed successfully! All 960 positions match."),
        Err((fen, d, expected, actual, path)) => {
            println!("\n[ERROR] Stage 2 Mismatch detected!");
            println!("  FEN: {}", fen);
            println!("  Depth: {}", d);
            println!("  Expected (Shakmaty): {}", expected);
            println!("  Actual (Arasan):     {}", actual);
            println!("  Divergent Move Path: {:?}", path);
            std::process::exit(1);
        }
    }

    // Stage 3: Depth 6
    match run_phase(&fens, 6) {
        Ok(_) => println!("Stage 3 (Depth 6) completed successfully! All 960 positions match."),
        Err((fen, d, expected, actual, path)) => {
            println!("\n[ERROR] Stage 3 Mismatch detected!");
            println!("  FEN: {}", fen);
            println!("  Depth: {}", d);
            println!("  Expected (Shakmaty): {}", expected);
            println!("  Actual (Arasan):     {}", actual);
            println!("  Divergent Move Path: {:?}", path);
            std::process::exit(1);
        }
    }

    println!("\n=== SUCCESS: ALL 960 CHESS960 STARTING POSITIONS MATCH EXACTLY AT DEPTH 6! ===");
}
