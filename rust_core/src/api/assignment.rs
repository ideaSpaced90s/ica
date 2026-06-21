use super::cognitive::ScotomaResult;

#[derive(Clone, Debug, Copy)]
pub enum ChanakyaTaskType {
    Arena,
    Puzzle,
    Tutorial,
}

#[derive(Clone, Debug)]
pub struct ChanakyaTask {
    pub title: String,
    pub description: String,
    pub task_type: ChanakyaTaskType,
    pub target_id: String,   // E.g. "avatar_6" or "knf" or "14"
    pub target_value: i32,   // Target count (e.g. 5 puzzles, or 10 moves)
}

#[derive(Clone, Debug)]
pub struct ChanakyaRoutine {
    pub tasks: Vec<ChanakyaTask>,
    pub wisdom_message: String,
}

#[derive(Clone, Debug)]
pub struct ChanakyaWeeklySummary {
    pub blunders_found: i32,
    pub annotated_moves_count: i32,
    pub worst_scotoma_axis: String,
    pub match_category: String,
    pub commentary_prompt: String,
    pub fallback_report: String,
}

// Helper: Determine worst scotoma axis and score
fn get_worst_scotoma(scotoma: &ScotomaResult) -> (&'static str, f64) {
    let mut worst_name = "king_safety";
    let mut worst_score = scotoma.king_safety;

    if scotoma.diagonal_retreats > worst_score {
        worst_name = "diagonal_retreats";
        worst_score = scotoma.diagonal_retreats;
    }
    if scotoma.horizontal_swings > worst_score {
        worst_name = "horizontal_swings";
        worst_score = scotoma.horizontal_swings;
    }
    if scotoma.knight_forks > worst_score {
        worst_name = "knight_forks";
        worst_score = scotoma.knight_forks;
    }
    if scotoma.time_panic > worst_score {
        worst_name = "time_panic";
        worst_score = scotoma.time_panic;
    }
    if scotoma.material_greed > worst_score {
        worst_name = "material_greed";
        worst_score = scotoma.material_greed;
    }
    if scotoma.tunnel_vision > worst_score {
        worst_name = "tunnel_vision";
        worst_score = scotoma.tunnel_vision;
    }
    if scotoma.pinned_pieces > worst_score {
        worst_name = "pinned_pieces";
        worst_score = scotoma.pinned_pieces;
    }
    (worst_name, worst_score)
}

// Helper: Recommend AI Avatar based on ELO and scotoma
fn select_ai_avatar(elo: i32, worst_scotoma: &str) -> (String, String) {
    let base_idx = if elo < 550 {
        0 // Sparky
    } else if elo < 750 {
        1 // Pawnzy
    } else if elo < 900 {
        2 // Coward
    } else if elo < 1000 {
        3 // Rookie
    } else if elo < 1100 {
        4 // Scholar
    } else if elo < 1200 {
        5 // Molly
    } else if elo < 1350 {
        6 // Berserker
    } else if elo < 1500 {
        7 // Blaire
    } else if elo < 1600 {
        8 // Python
    } else if elo < 1700 {
        9 // Gambit
    } else if elo < 1800 {
        10 // Trapper
    } else if elo < 1900 {
        11 // Assassin
    } else if elo < 2000 {
        12 // Vala
    } else if elo < 2150 {
        13 // Magician
    } else if elo < 2300 {
        14 // Sentinel
    } else if elo < 2450 {
        15 // Murphy
    } else if elo < 2600 {
        16 // Titan
    } else if elo < 2750 {
        17 // Alien
    } else if elo < 2900 {
        18 // Champ
    } else {
        19 // King
    };

    let target_idx = match worst_scotoma {
        "king_safety" => {
            if base_idx <= 6 { 6 } // Berserker
            else if base_idx <= 8 { 7 } // Blaire
            else if base_idx <= 12 { 11 } // Assassin
            else if base_idx <= 14 { 13 } // Magician
            else { 15 } // Murphy
        },
        "material_greed" | "diagonal_retreats" | "horizontal_swings" => {
            if base_idx <= 5 { 5 } // Molly
            else if base_idx <= 10 { 8 } // Python
            else if base_idx <= 15 { 14 } // Sentinel
            else { 16 } // Titan
        },
        "knight_forks" | "pinned_pieces" => {
            if base_idx <= 4 { 4 } // Scholar
            else if base_idx <= 10 { 10 } // Trapper
            else { 12 } // Vala
        },
        _ => base_idx,
    };

    let id = format!("avatar_{}", target_idx);
    let name = match target_idx {
        0 => "Sparky",
        1 => "Pawzy",
        2 => "Timorous",
        3 => "Rookie",
        4 => "Scholar",
        5 => "Molly",
        6 => "Berserker",
        7 => "Blaire",
        8 => "Python",
        9 => "Gambit",
        10 => "Trapper",
        11 => "Assassin",
        12 => "Vala",
        13 => "Magician",
        14 => "Sentinel",
        15 => "Murphy",
        16 => "Titan",
        17 => "Alien",
        18 => "Champ",
        _ => "King",
    };

    (id, name.to_string())
}

// Helper: Recommend academy chapter index
fn select_tutorial_target(elo: i32, completed: &[i32]) -> (i32, String) {
    let basic_chapters = vec![1, 2, 3, 4, 5, 6, 7, 8, 9];
    let intermediate_chapters = vec![10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20];
    let advanced_chapters: Vec<i32> = (21..=53).collect();

    if elo < 1000 {
        for chap in &basic_chapters {
            if !completed.contains(chap) {
                return (*chap, get_chapter_title(*chap));
            }
        }
    }

    if elo < 1600 {
        for chap in &intermediate_chapters {
            if !completed.contains(chap) {
                return (*chap, get_chapter_title(*chap));
            }
        }
    }

    for chap in &advanced_chapters {
        if !completed.contains(chap) {
            return (*chap, get_chapter_title(*chap));
        }
    }

    (20, "Opening Principles".to_string())
}

fn get_chapter_title(chap: i32) -> String {
    match chap {
        1 => "Board Introduction".to_string(),
        2 => "Coordinates & Tiles".to_string(),
        3 => "Pawn Movement".to_string(),
        4 => "Rook Movement".to_string(),
        5 => "Bishop Movement".to_string(),
        6 => "Knight Movement".to_string(),
        7 => "Queen Movement".to_string(),
        8 => "King Movement".to_string(),
        9 => "Capturing Pieces".to_string(),
        10 => "Pawn Promotion".to_string(),
        11 => "Kingside Castling".to_string(),
        12 => "Queenside Castling".to_string(),
        13 => "En Passant Capture".to_string(),
        14 => "Understanding Check".to_string(),
        15 => "Escaping Check".to_string(),
        16 => "Checkmate".to_string(),
        17 => "Stalemate".to_string(),
        18 => "Draw Conditions".to_string(),
        19 => "Piece Value Concepts".to_string(),
        20 => "Opening Principles".to_string(),
        21 => "Tactical Patterns".to_string(),
        _ => format!("Academy Chapter {}", chap),
    }
}

// Helper: Chanakya daily quote based on scotoma
fn get_chanakya_wisdom(worst_scotoma: &str, score: f64) -> String {
    let severity = if score > 0.6 { "grave" } else { "moderate" };
    match worst_scotoma {
        "king_safety" => {
            if severity == "grave" {
                "Apprentice, your king safety is a major vulnerability. You cast your king aside while tactical fires consume the center. Your focus today must be defense: build your fortress and guard the king.".to_string()
            } else {
                "Your king safety is acceptable, but you miss subtle mating nets. Train your eye to defend early and secure the king's back rank before launching attacks.".to_string()
            }
        },
        "material_greed" => {
            "Greed is a poison that blinds the eyes, Apprentice. You capture pieces with haste, failing to calculate the poison inside. Today, focus on prophylaxis: ask what your opponent threatens before you strike.".to_string()
        },
        "diagonal_retreats" => {
            "Your eyes fail to track diagonal lines, especially retreating bishops. Today, play with deliberate diagonal sweeps. Force the opponent to run, then catch them on the long flank.".to_string()
        },
        "horizontal_swings" => {
            "Rooks sweeping horizontally catch you off guard. Master the horizontal ranks. Open up files and keep rooks active on the rank.".to_string()
        },
        "knight_forks" => {
            "The knight is a trickster that leaps over defenses. You fall victim to forks on the flank. Learn to trace the knight's path. Spot the L-leap before the trap is sprung.".to_string()
        },
        "pinned_pieces" => {
            "A pinned piece is a ghost defender. It looks solid but cannot move. You rely on pinned defenders to hold the center, only to watch them vanish. Learn to spot the pin before you count your support.".to_string()
        },
        "tunnel_vision" => {
            "You focus on one side of the board, blind to the other. The decisive blow always comes from the flank you ignore. Today, look at the whole board. Take a deep breath before every move.".to_string()
        },
        "time_panic" => {
            "Time pressure is a shadow that clouds your calculation, Apprentice. Under the ticking clock, your sight fails and you strike in panic. Today, train to remain calm under pressure. Speed must not sacrifice precision.".to_string()
        },
        _ => {
            "Apprentice, your tactical vision is balanced. Now we sharpen all edges. Discipline and patience are the weapons of the master strategist. Begin today's training.".to_string()
        }
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn recommend_tasks_rust(
    elo: i32,
    scotoma: ScotomaResult,
    completed_tutorials: Vec<i32>,
) -> ChanakyaRoutine {
    let (worst_name, worst_score) = get_worst_scotoma(&scotoma);
    let has_diagnosis = {
        let affected_games = (worst_score * scotoma.analyzed_games as f64).round() as i32;
        scotoma.analyzed_games >= 5 && worst_score >= 0.15 && affected_games >= 2
    };

    // Arena challenge target
    let (avatar_id, avatar_name) = select_ai_avatar(elo, worst_name);
    let arena_desc = format!("Play a game in the Arena against {} (Rating: {}). Focus on maintaining structure and eliminating blindspots.", avatar_name, elo);
    let arena_task = ChanakyaTask {
        title: "Arena Combat".to_string(),
        description: arena_desc,
        task_type: ChanakyaTaskType::Arena,
        target_id: avatar_id,
        target_value: 1,
    };

    // Prescription puzzle target
    let puzzle_axis = if has_diagnosis {
        match worst_name {
            "diagonal_retreats" => "dgb",
            "horizontal_swings" => "hrz",
            "knight_forks" => "knf",
            "time_panic" => "tmp",
            "material_greed" => "grd",
            "tunnel_vision" => "tnl",
            "pinned_pieces" => "pin",
            _ => "ksb",
        }
    } else {
        "balanced"
    };

    let puzzle_desc = if puzzle_axis == "balanced" {
        "Complete 5 general mastery puzzles to sharpen all cognitive-visual dimensions.".to_string()
    } else {
        format!("Complete 5 scotoma puzzles targeting the '{}' axis to cure visual blindness.", puzzle_axis.to_uppercase())
    };

    let puzzle_task = ChanakyaTask {
        title: "Tactical Prescription".to_string(),
        description: puzzle_desc,
        task_type: ChanakyaTaskType::Puzzle,
        target_id: puzzle_axis.to_string(),
        target_value: 5,
    };

    // Academy tutorial target
    let (chapter_id, chapter_title) = select_tutorial_target(elo, &completed_tutorials);
    let tutorial_desc = format!("Attend GM Chanakya's Academy and complete Chapter {}: '{}'.", chapter_id, chapter_title);
    let tutorial_task = ChanakyaTask {
        title: "Academy Syllabus".to_string(),
        description: tutorial_desc,
        task_type: ChanakyaTaskType::Tutorial,
        target_id: chapter_id.to_string(),
        target_value: 1,
    };

    let wisdom = if has_diagnosis {
        get_chanakya_wisdom(worst_name, worst_score)
    } else {
        "Apprentice, your tactical vision is balanced. Now we sharpen all edges. Discipline and patience are the weapons of the master strategist. Begin today's training.".to_string()
    };

    ChanakyaRoutine {
        tasks: vec![arena_task, puzzle_task, tutorial_task],
        wisdom_message: wisdom,
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn analyze_submitted_game_rust(
    pgn_content: String,
    scotoma: ScotomaResult,
) -> ChanakyaWeeklySummary {
    let mut blunder_count = 0;
    let mut comment_count = 0;
    let mut moves_count = 0;
    
    let mut in_comment = false;
    let mut current_comment = String::new();
    let mut comments = Vec::new();
    
    let chars: Vec<char> = pgn_content.chars().collect();
    let mut i = 0;
    while i < chars.len() {
        let c = chars[i];
        if c == '{' {
            in_comment = true;
            comment_count += 1;
        } else if c == '}' {
            in_comment = false;
            comments.push(current_comment.trim().to_string());
            current_comment.clear();
        } else if in_comment {
            current_comment.push(c);
        } else {
            if c.is_ascii_digit() && i + 1 < chars.len() && chars[i + 1] == '.' {
                moves_count += 1;
            }
            if c == '?' {
                blunder_count += 1;
                if i + 1 < chars.len() && (chars[i + 1] == '?' || chars[i + 1] == '!') {
                    i += 1;
                }
            }
        }
        i += 1;
    }
    
    let (worst_scotoma, worst_score) = get_worst_scotoma(&scotoma);
    
    // Create LLM system instruction prompt
    let commentary_prompt = format!(
        "You are GM Chanakya, the supreme chess mentor of the Academy. Address the user as 'Apprentice'. \
         Analyze the following game summary and the player's annotations. \
         Move Count: {}. Blunders annotated: {}. User comments found: {}. \
         User's worst scotoma: {} (score: {:.2}). \
         User's annotations/thoughts: \n{:?} \n\
         Generate a detailed coaching review report in your mentoring, data-driven, yet human tone. \
         Explain their tactical pitfalls, identify how their blindspot was exploited in their loss, \
         and propose a concrete, wise improvement plan.",
        moves_count, blunder_count, comment_count, worst_scotoma, worst_score, comments
    );
    
    let display_scotoma_name = match worst_scotoma {
        "diagonal_retreats" => "Diagonal Retreat Blindspot",
        "horizontal_swings" => "Lateral/Horizontal Sweeps",
        "knight_forks" => "Knight Vision/Fork Vulnerability",
        "pinned_pieces" => "Pinned Piece Hallucination",
        "king_safety" => "King Safety Neglect",
        "material_greed" => "Poisoned Captures/Material Greed",
        "tunnel_vision" => "Single-Side/Tunnel Vision",
        _ => "Time Panic",
    };
    
    let fallback_report = format!(
        "### GM CHANAKYA'S WEEKLY REPORT\n\n\
         *\"Losing hurts, Apprentice, but it teaches faster than winning. Let us examine the record.\"*\n\n\
         **Game Metrics Analyzed:**\n\
         - **Game Length:** {} moves\n\
         - **Critical Pitfalls:** {} blunders annotated\n\
         - **Personal Reflections:** {} annotations registered\n\n\
         **Diagnostic Diagnosis:**\n\
         Your annotations confirm that your worst cognitive blindspot is the **{}**. \
         In this battle, your comments show you were either unaware of the threat or too late in detecting it. \
         Your reflection: *\"{}\"* shows you are beginning to notice, but your reaction speed must be sharper.\n\n\
         **Proposed Improvement Plan:**\n\
         1. **Tactical Restraint:** Spend at least 3 seconds studying opponent threats before executing any captures. Greed is a poor shield against checkmate.\n\
         2. **Daily Routine:** Complete the daily scotoma puzzle prescriptions I assign you. They are targeted medicine for your visual field.\n\
         3. **Arena Sparring:** Challenge the AI avatar in your next routine, focusing entirely on piece coordinating on the weak files.\n\n\
         Stay disciplined, Apprentice. The board does not lie.",
        moves_count, blunder_count, comment_count, display_scotoma_name, 
        if comments.is_empty() { "None recorded. Ensure you write comments on your blunders in Analysis mode." } else { &comments[0] }
    );
    
    ChanakyaWeeklySummary {
        blunders_found: blunder_count,
        annotated_moves_count: comment_count,
        worst_scotoma_axis: worst_scotoma.to_string(),
        match_category: "Loss".to_string(),
        commentary_prompt,
        fallback_report,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_get_worst_scotoma() {
        let scotoma = ScotomaResult {
            diagonal_retreats: 0.1,
            horizontal_swings: 0.2,
            knight_forks: 0.8, // highest
            time_panic: 0.1,
            material_greed: 0.3,
            tunnel_vision: 0.4,
            pinned_pieces: 0.5,
            king_safety: 0.15,
            total_rated_games: 10,
            analyzed_games: 10,
            skipped_games: 0,
        };
        let (name, score) = get_worst_scotoma(&scotoma);
        assert_eq!(name, "knight_forks");
        assert!((score - 0.8).abs() < 1e-9);
    }

    #[test]
    fn test_select_ai_avatar() {
        // Lower ELO should get beginner avatars
        let (_id, name) = select_ai_avatar(400, "knight_forks");
        assert_eq!(name, "Scholar"); // knight_forks maps Scholar for low ELO

        let (_id2, name2) = select_ai_avatar(1200, "king_safety");
        assert_eq!(name2, "Berserker"); // king_safety maps Berserker

        let (_id3, name3) = select_ai_avatar(1500, "material_greed");
        assert_eq!(name3, "Python"); // material_greed maps Python
    }

    #[test]
    fn test_select_tutorial_target() {
        // ELO < 1000 and basic chapters not completed should return next basic chapter
        let completed = vec![1, 2, 3];
        let (chap, title) = select_tutorial_target(800, &completed);
        assert_eq!(chap, 4);
        assert_eq!(title, "Rook Movement");

        // ELO < 1000 and all basic chapters completed should return next chapter
        let completed_all_basic: Vec<i32> = (1..=9).collect();
        let (chap2, _title2) = select_tutorial_target(800, &completed_all_basic);
        assert_eq!(chap2, 10); // First intermediate chapter
    }

    #[test]
    fn test_analyze_submitted_game_rust() {
        let pgn = "[Event \"Rated Duel\"]\n[Site \"Kingslayer\"]\n[Result \"0-1\"]\n\n1. e4 {Too aggressive?} e5 2. Bc4?? {Bishop blunder} Nf6 3. Nc3? {knight fork?}".to_string();
        let scotoma = ScotomaResult {
            diagonal_retreats: 0.1,
            horizontal_swings: 0.1,
            knight_forks: 0.9,
            time_panic: 0.1,
            material_greed: 0.1,
            tunnel_vision: 0.1,
            pinned_pieces: 0.1,
            king_safety: 0.1,
            total_rated_games: 10,
            analyzed_games: 10,
            skipped_games: 0,
        };
        let summary = analyze_submitted_game_rust(pgn, scotoma);
        assert_eq!(summary.blunders_found, 2); // '??' and '?' count as blunders
        assert_eq!(summary.annotated_moves_count, 3); // three comments found
        assert_eq!(summary.worst_scotoma_axis, "knight_forks");
        assert!(summary.fallback_report.contains("GM CHANAKYA'S WEEKLY REPORT"));
    }

    #[test]
    fn test_get_chanakya_wisdom_time_panic() {
        let wisdom = get_chanakya_wisdom("time_panic", 0.5);
        assert!(wisdom.contains("Time pressure is a shadow"));
    }
}
