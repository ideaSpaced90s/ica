#[derive(Debug, Clone)]
pub struct Puzzle {
    pub id: String,
    pub fen: String,
    pub moves: Vec<String>,
    pub rating: i32,
    pub themes: String,
}

pub fn search_puzzles(
    db_path: String,
    theme: Option<String>,
    min_rating: Option<i32>,
    max_rating: Option<i32>,
    limit: Option<i32>,
) -> Vec<Puzzle> {
    let conn = match rusqlite::Connection::open(&db_path) {
        Ok(c) => c,
        Err(e) => {
            eprintln!("Failed to open database: {}", e);
            return Vec::new();
        }
    };

    // Find table name safely
    let mut table_name = "puzzles".to_string();
    if let Ok(mut stmt) = conn.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name != 'sqlite_sequence'") {
        let mut names = Vec::new();
        if let Ok(rows) = stmt.query_map([], |row| row.get::<_, String>(0)) {
            for name in rows.flatten() {
                names.push(name);
            }
        }
        if let Some(first) = names.first() {
            table_name = first.clone();
        }
    }

    // Resolve column names dynamically using PRAGMA table_info to handle any schema variations safely
    let mut id_col = "PuzzleId".to_string();
    let mut fen_col = "FEN".to_string();
    let mut moves_col = "Moves".to_string();
    let mut rating_col = "Rating".to_string();
    let mut themes_col = "Themes".to_string();

    if let Ok(mut stmt) = conn.prepare(&format!("PRAGMA table_info({})", table_name)) {
        if let Ok(rows) = stmt.query_map([], |row| row.get::<_, String>(1)) {
            let cols: Vec<String> = rows.flatten().collect();
            for c in cols {
                let lower = c.to_lowercase();
                if lower == "puzzleid" || lower == "puzzle_id" || lower == "id" {
                    id_col = c;
                } else if lower == "fen" {
                    fen_col = c;
                } else if lower == "moves" {
                    moves_col = c;
                } else if lower == "rating" || lower == "elo" {
                    rating_col = c;
                } else if lower == "themes" || lower == "theme" {
                    themes_col = c;
                }
            }
        }
    }

    let mut sql = format!(
        "SELECT {}, {}, {}, {}, {} FROM {} WHERE 1=1",
        id_col, fen_col, moves_col, rating_col, themes_col, table_name
    );

    if let Some(min_r) = min_rating {
        sql.push_str(&format!(" AND {} >= {}", rating_col, min_r));
    }
    if let Some(max_r) = max_rating {
        sql.push_str(&format!(" AND {} <= {}", rating_col, max_r));
    }
    if let Some(ref t) = theme {
        let sanitized = t.replace('\'', "");
        sql.push_str(&format!(" AND {} LIKE '%{}%'", themes_col, sanitized));
    }

    sql.push_str(" ORDER BY RANDOM()");

    let lim = limit.unwrap_or(10);
    sql.push_str(&format!(" LIMIT {}", lim));

    let mut results = Vec::new();
    let mut stmt = match conn.prepare(&sql) {
        Ok(s) => s,
        Err(e) => {
            eprintln!("Prepare query failed: {}", e);
            return Vec::new();
        }
    };

    let rows = stmt.query_map([], |row| {
        let id: String = row.get(0)?;
        let fen: String = row.get(1)?;
        let moves_str: String = row.get(2)?;
        let rating: i32 = row.get(3)?;
        let themes: String = row.get(4)?;

        let moves: Vec<String> = moves_str.split_whitespace().map(|s| s.to_string()).collect();

        Ok(Puzzle {
            id,
            fen,
            moves,
            rating,
            themes,
        })
    });

    if let Ok(mapped_rows) = rows {
        for puzzle in mapped_rows.flatten() {
            results.push(puzzle);
        }
    }

    results
}

pub fn get_random_puzzle(
    db_path: String,
    min_rating: Option<i32>,
    max_rating: Option<i32>,
) -> Option<Puzzle> {
    search_puzzles(db_path, None, min_rating, max_rating, Some(1))
        .into_iter()
        .next()
}
