use rusqlite::{Connection, params};

pub struct PgnGameHeader {
    pub event: String,
    pub site: String,
    pub date: String,
    pub white: String,
    pub black: String,
    pub white_elo: Option<i32>,
    pub black_elo: Option<i32>,
    pub result: String,
    pub eco: String,
    pub opening: String,
}

pub struct PgnGameRecord {
    pub header: PgnGameHeader,
    pub moves_pgn: String,   // Raw moves-only portion (possibly with annotations/comments)
    pub index: usize,        // Index of the game within the file/database
}

static OPENINGS: phf::Map<&'static str, (&'static str, &'static str)> = phf::phf_map! {
    "e4" => ("B00", "King's Pawn Game"),
    "e4 e5" => ("C20", "Open Game"),
    "e4 e5 Nf3" => ("C40", "King's Knight Opening"),
    "e4 e5 Nf3 Nc6" => ("C50", "King's Pawn Game: Three Knights Game"),
    "e4 e5 Nf3 Nc6 Bb5" => ("C60", "Ruy Lopez (Spanish Opening)"),
    "e4 e5 Nf3 Nc6 Bc4" => ("C50", "Italian Game"),
    "e4 e5 Nf3 Nc6 Nc3" => ("C46", "Three Knights Game"),
    "e4 e5 Nf3 Nc6 Nc3 Nf6" => ("C47", "Four Knights Game"),
    "e4 e5 Nf3 Nf6" => ("C42", "Petrov's Defense"),
    "e4 e5 Nf3 d6" => ("C41", "Philidor Defense"),
    "e4 e5 f4" => ("C30", "King's Gambit"),
    "e4 c5" => ("B20", "Sicilian Defense"),
    "e4 c5 Nf3 d6 d4 cxd4 Nxd4 Nf6 Nc3" => ("B90", "Sicilian Defense: Najdorf Variation"),
    "e4 c5 Nf3 Nc6 d4 cxd4 Nxd4 Nf6 Nc3 d6" => ("B56", "Sicilian Defense: Classical Variation"),
    "e4 c5 Nf3 e6 d4 cxd4 Nxd4" => ("B40", "Sicilian Defense: French Variation"),
    "e4 e6" => ("C00", "French Defense"),
    "e4 e6 d4 d5 Nc3 Nf6" => ("C11", "French Defense: Classical Variation"),
    "e4 e6 d4 d5 Nd2" => ("C03", "French Defense: Tarrasch Variation"),
    "e4 e6 d4 d5 exd5" => ("C01", "French Defense: Exchange Variation"),
    "e4 c6" => ("B12", "Caro-Kann Defense"),
    "e4 c6 d4 d5 exd5 cxd5 Bd3" => ("B13", "Caro-Kann Defense: Exchange Variation"),
    "e4 c6 d4 d5 e5" => ("B12", "Caro-Kann Defense: Advance Variation"),
    "e4 d6" => ("B07", "Pirc Defense"),
    "e4 g6" => ("B06", "Modern Defense"),
    "e4 Nf6" => ("B02", "Alekhine's Defense"),
    "e4 d5" => ("B01", "Scandinavian Defense"),
    "d4" => ("A40", "Queen's Pawn Game"),
    "d4 d5" => ("D00", "Queen's Pawn Game: Closed Game"),
    "d4 d5 c4" => ("D06", "Queen's Gambit"),
    "d4 d5 c4 e6" => ("D30", "Queen's Gambit Declined"),
    "d4 d5 c4 e6 Nc3 Nf6" => ("D35", "Queen's Gambit Declined: Orthodox"),
    "d4 d5 c4 c6" => ("D10", "Queen's Gambit Accepted / Slav Defense"),
    "d4 d5 c4 dxc4" => ("D20", "Queen's Gambit Accepted"),
    "d4 Nf6" => ("A45", "Queen's Pawn Game: Indian Defense"),
    "d4 Nf6 c4 g6" => ("E60", "King's Indian Defense"),
    "d4 Nf6 c4 g6 Nc3 Bg7 e4 d6 Nf3 O-O" => ("E90", "King's Indian Defense: Classical"),
    "d4 Nf6 c4 e6 Nf3 b6" => ("E12", "Queen's Indian Defense"),
    "d4 Nf6 c4 e6 Nf3 d5" => ("D30", "Queen's Gambit Declined"),
    "d4 Nf6 c4 e6 Nc3 Bb4" => ("E20", "Nimzo-Indian Defense"),
    "d4 Nf6 c4 g6 Nc3 d5" => ("D80", "Grunfeld Defense"),
    "d4 Nf6 c4 c5 d5" => ("A56", "Benoni Defense"),
    "d4 f5" => ("A80", "Dutch Defense"),
    "Nf3" => ("A04", "Reti Opening"),
    "c4" => ("A10", "English Opening"),
    "g3" => ("A00", "Benko's Opening / King's Fianchetto"),
    "f4" => ("A02", "Bird's Opening"),
    "b3" => ("A01", "Nimzowitsch-Larsen Attack"),
    "b4" => ("A00", "Sokolsky Opening"),
    "g4" => ("A00", "Grob's Attack"),
};

// Parse a multi-game PGN string into a list of game records
#[flutter_rust_bridge::frb(sync)]
pub fn parse_pgn_database(pgn_text: String) -> Vec<PgnGameRecord> {
    let mut games = Vec::new();
    let mut current_headers = std::collections::HashMap::new();
    let mut current_moves = Vec::new();
    let mut parsing_moves = false;
    let mut game_index = 0;

    for line in pgn_text.lines() {
        let trimmed = line.trim();
        if trimmed.is_empty() {
            continue;
        }

        if trimmed.starts_with('[') && trimmed.ends_with(']') {
            if parsing_moves {
                let game = build_game_record(&current_headers, &current_moves, game_index);
                games.push(game);
                game_index += 1;
                
                current_headers.clear();
                current_moves.clear();
                parsing_moves = false;
            }
            
            if let Some((key, val)) = parse_header_line(trimmed) {
                current_headers.insert(key, val);
            }
        } else {
            parsing_moves = true;
            current_moves.push(trimmed.to_string());
        }
    }

    if !current_headers.is_empty() || !current_moves.is_empty() {
        let game = build_game_record(&current_headers, &current_moves, game_index);
        games.push(game);
    }

    games
}

fn parse_header_line(line: &str) -> Option<(String, String)> {
    let content = &line[1..line.len()-1];
    let first_space = content.find(' ')?;
    let key = content[..first_space].trim().to_string();
    let val_part = content[first_space..].trim();
    if val_part.starts_with('"') && val_part.ends_with('"') && val_part.len() >= 2 {
        let val = val_part[1..val_part.len()-1].to_string();
        Some((key, val))
    } else {
        Some((key, val_part.to_string()))
    }
}

fn build_game_record(
    headers: &std::collections::HashMap<String, String>,
    moves: &[String],
    index: usize,
) -> PgnGameRecord {
    let event = headers.get("Event").cloned().unwrap_or_else(|| "Unknown Event".to_string());
    let site = headers.get("Site").cloned().unwrap_or_else(|| "Unknown Site".to_string());
    let date = headers.get("Date").cloned().unwrap_or_else(|| "????.??.??".to_string());
    let white = headers.get("White").cloned().unwrap_or_else(|| "White Player".to_string());
    let black = headers.get("Black").cloned().unwrap_or_else(|| "Black Player".to_string());
    
    let white_elo = headers.get("WhiteElo").and_then(|s| s.parse::<i32>().ok());
    let black_elo = headers.get("BlackElo").and_then(|s| s.parse::<i32>().ok());
    let result = headers.get("Result").cloned().unwrap_or_else(|| "*".to_string());
    let eco = headers.get("ECO").cloned().unwrap_or_else(|| "".to_string());
    let opening = headers.get("Opening").cloned().unwrap_or_else(|| "".to_string());

    let header = PgnGameHeader {
        event,
        site,
        date,
        white,
        black,
        white_elo,
        black_elo,
        result,
        eco,
        opening,
    };

    let moves_pgn = moves.join("\n");

    PgnGameRecord {
        header,
        moves_pgn,
        index,
    }
}

// Serialize a game to PGN format with custom headers
#[flutter_rust_bridge::frb(sync)]
pub fn export_pgn_with_headers(header: PgnGameHeader, annotated_pgn: String) -> String {
    let mut buffer = String::new();
    buffer.push_str(&format!("[Event \"{}\"]\n", header.event));
    buffer.push_str(&format!("[Site \"{}\"]\n", header.site));
    buffer.push_str(&format!("[Date \"{}\"]\n", header.date));
    buffer.push_str(&format!("[White \"{}\"]\n", header.white));
    buffer.push_str(&format!("[Black \"{}\"]\n", header.black));
    if let Some(elo) = header.white_elo {
        buffer.push_str(&format!("[WhiteElo \"{}\"]\n", elo));
    }
    if let Some(elo) = header.black_elo {
        buffer.push_str(&format!("[BlackElo \"{}\"]\n", elo));
    }
    buffer.push_str(&format!("[Result \"{}\"]\n", header.result));
    if !header.eco.is_empty() {
        buffer.push_str(&format!("[ECO \"{}\"]\n", header.eco));
    }
    if !header.opening.is_empty() {
        buffer.push_str(&format!("[Opening \"{}\"]\n", header.opening));
    }
    buffer.push_str("\n");
    buffer.push_str(&annotated_pgn);
    buffer
}

// Classify the opening from a list of SAN moves
#[flutter_rust_bridge::frb(sync)]
pub fn classify_opening_eco(moves_san: Vec<String>) -> (String, String) {
    let mut longest_match = ("A00".to_string(), "Custom Analysis Line".to_string());
    let mut longest_len = 0;
    
    for i in 1..=moves_san.len() {
        let prefix = moves_san[..i].join(" ");
        if let Some(&(eco, name)) = OPENINGS.get(prefix.as_str()) {
            if i > longest_len {
                longest_len = i;
                longest_match = (eco.to_string(), name.to_string());
            }
        }
    }
    
    longest_match
}

// Persistence: Save study to local SQLite DB
#[flutter_rust_bridge::frb(sync)]
pub fn save_study_to_db(db_path: String, game: PgnGameRecord) -> bool {
    let conn = match Connection::open(&db_path) {
        Ok(c) => c,
        Err(_) => return false,
    };

    let result = conn.execute(
        "CREATE TABLE IF NOT EXISTS studies (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            event TEXT,
            site TEXT,
            date TEXT,
            white TEXT,
            black TEXT,
            white_elo INTEGER,
            black_elo INTEGER,
            result TEXT,
            eco TEXT,
            opening TEXT,
            moves_pgn TEXT,
            game_index INTEGER
        )",
        [],
    );

    if result.is_err() {
        return false;
    }

    let insert_result = conn.execute(
        "INSERT INTO studies (event, site, date, white, black, white_elo, black_elo, result, eco, opening, moves_pgn, game_index)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12)",
        params![
            game.header.event,
            game.header.site,
            game.header.date,
            game.header.white,
            game.header.black,
            game.header.white_elo,
            game.header.black_elo,
            game.header.result,
            game.header.eco,
            game.header.opening,
            game.moves_pgn,
            game.index as i64,
        ],
    );

    insert_result.is_ok()
}

// Persistence: Load all studies from local SQLite DB
#[flutter_rust_bridge::frb(sync)]
pub fn load_studies_from_db(db_path: String) -> Vec<PgnGameRecord> {
    let conn = match Connection::open(&db_path) {
        Ok(c) => c,
        Err(_) => return Vec::new(),
    };

    // Ensure the table exists before attempting to select
    let _ = conn.execute(
        "CREATE TABLE IF NOT EXISTS studies (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            event TEXT,
            site TEXT,
            date TEXT,
            white TEXT,
            black TEXT,
            white_elo INTEGER,
            black_elo INTEGER,
            result TEXT,
            eco TEXT,
            opening TEXT,
            moves_pgn TEXT,
            game_index INTEGER
        )",
        [],
    );

    let mut stmt = match conn.prepare(
        "SELECT event, site, date, white, black, white_elo, black_elo, result, eco, opening, moves_pgn, game_index FROM studies"
    ) {
        Ok(s) => s,
        Err(_) => return Vec::new(),
    };

    let game_iter = stmt.query_map([], |row| {
        Ok(PgnGameRecord {
            header: PgnGameHeader {
                event: row.get(0)?,
                site: row.get(1)?,
                date: row.get(2)?,
                white: row.get(3)?,
                black: row.get(4)?,
                white_elo: row.get(5)?,
                black_elo: row.get(6)?,
                result: row.get(7)?,
                eco: row.get(8)?,
                opening: row.get(9)?,
            },
            moves_pgn: row.get(10)?,
            index: row.get::<_, i64>(11)? as usize,
        })
    });

    match game_iter {
        Ok(rows) => rows.filter_map(|r| r.ok()).collect(),
        Err(_) => Vec::new(),
    }
}

// Persistence: Clear all studies in the database
#[flutter_rust_bridge::frb(sync)]
pub fn clear_all_studies(db_path: String) -> bool {
    let conn = match Connection::open(&db_path) {
        Ok(c) => c,
        Err(_) => return false,
    };
    conn.execute("DROP TABLE IF EXISTS studies", []).is_ok()
}
