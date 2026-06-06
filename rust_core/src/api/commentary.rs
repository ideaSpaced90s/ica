use std::collections::HashMap;
use std::sync::{Mutex, OnceLock};

static HISTORY: OnceLock<Mutex<HashMap<String, Vec<usize>>>> = OnceLock::new();

fn get_history() -> &'static Mutex<HashMap<String, Vec<usize>>> {
    HISTORY.get_or_init(|| Mutex::new(HashMap::new()))
}

#[flutter_rust_bridge::frb(sync)]
pub fn reset_commentary_history_rust() {
    if let Ok(mut history) = get_history().lock() {
        history.clear();
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn select_commentary_template_rust(
    quality: String,
    previous_quality: String,
    game_phase: String,
    eval_diff: f64,
    has_fork: bool,
    has_pin: bool,
    has_hanging: bool,
) -> String {
    // 1. Narrative Continuity / Transition Anchors
    if previous_quality == "Blunder" || previous_quality == "Mistake" {
        if quality == "Blunder" || quality == "Mistake" {
            // Scenario A: Compounded Blunder
            return "Unbelievable! Instead of realizing the danger pointed out on the last move, [Player] doubles down on bad calculations with [Move]. This isn't just an error; it's a structural collapse.".to_string();
        }
        if quality == "Brilliant" || quality == "Strong" {
            // Scenario B: Tactical Refutation
            return "And there is the swift punishment GM Chanakya warned you about. [Player] instantly spots the structural opening left on the previous move and delivers a crushing tactical blow with [Move].".to_string();
        }
    } else if (previous_quality == "Neutral" || previous_quality == "Strong") && quality == "Strong" {
        // Scenario C: Steady Improvement
        return "Building beautifully upon the solid development of the previous phase, [Player] pushes the advantage further with [Move]. The pressure is mounting.".to_string();
    }

    // 2. Gate Decision Hierarchy
    let category = if game_phase == "Opening" {
        if quality == "Blunder" || quality == "Mistake" || quality == "Inaccuracy" {
            "A2" // Early Inaccuracies
        } else {
            "A1" // High Theoretical Conformity
        }
    } else if game_phase == "Endgame" {
        if quality == "Blunder" || quality == "Mistake" || quality == "Inaccuracy" {
            "D2" // Endgame Blunders
        } else {
            "D1" // Flawless Technical Conversion
        }
    } else { // Middlegame
        if quality == "Blunder" || quality == "Mistake" {
            "C1" // Major Blunders
        } else if quality == "Brilliant" {
            "C2" // Brilliant/Surgical Strike
        } else {
            // Inaccuracy, Neutral, Strong
            if eval_diff <= -0.5 || has_fork || has_pin || has_hanging {
                "B2" // Structural Degradation
            } else {
                "B1" // Outpost Creation / Piece Optimization
            }
        }
    };

    // 3. Shuffling Ring-Buffer index selection
    let comp = get_components_for_category(category);
    let intro_idx = select_index_with_ring_buffer(&format!("{}_intro", category), comp.intros.len());
    let obs_idx = select_index_with_ring_buffer(&format!("{}_obs", category), comp.observations.len());
    let conc_idx = select_index_with_ring_buffer(&format!("{}_conc", category), comp.conclusions.len());

    format!("{} {} {}", comp.intros[intro_idx], comp.observations[obs_idx], comp.conclusions[conc_idx])
}

struct CommentaryComponents {
    intros: &'static [&'static str],
    observations: &'static [&'static str],
    conclusions: &'static [&'static str],
}

fn get_components_for_category(category: &str) -> CommentaryComponents {
    match category {
        "A1" => CommentaryComponents {
            intros: &[
                "A perfectly respectable choice here.",
                "Classic textbook chess.",
                "GM Chanakya approves.",
                "Sound development.",
                "An elegant step.",
                "Maintaining structural harmony.",
                "A standard weapon in this setup.",
                "Clean, unpretentious development.",
            ],
            observations: &[
                "By securing control over the center early, [Player] lays down healthy foundations.",
                "[Player] complies completely with structural principles, staking a claim in the core.",
                "This line preserves the elasticity of the pawn structure, keeping options open.",
                "[Player] prioritizes developing the minor pieces before embarking on flank attacks.",
                "This setup is structurally resilient, ensuring no immediate tactical surprises.",
                "The piece slips naturally into the development chain, safeguarding the position.",
                "This establishes a dynamic balance, challenging the opponent to prove their antidote.",
                "The pawn/piece placement is positionally sound, commanding respect without overextending.",
            ],
            conclusions: &[
                "No need to reinvent the wheel.",
                "Quietly asking the opponent to reveal their intentions.",
                "This is how solid chess is played.",
                "Aiming to slowly squeeze the opponent out of comfortable squares.",
                "The king's future home remains secure.",
                "Development is proceeding exactly as it should.",
                "A very stable base for the upcoming middlegame.",
                "A calm, collected beginning.",
            ],
        },
        "A2" => CommentaryComponents {
            intros: &[
                "A severe violation of opening principles.",
                "Premature enthusiasm here.",
                "A positional luxury that [Player] simply cannot afford.",
                "This move lacks dynamic urgency.",
                "An erratic choice by [Player] in the opening.",
                "A superficial threat that is easily defused.",
                "Neglecting prophylaxis this early is dangerous.",
                "An awkward square for the [Piece].",
            ],
            observations: &[
                "Moving the same piece twice before the rest of the army develops is an invitation to trouble.",
                "Bringing the queen out this early makes her a massive target for enemy pieces.",
                "This slow pawn push on the flank ignores the burning fires in the center.",
                "While it doesn't drop material, it allows the opponent an unearned opportunity to seize the initiative.",
                "Developing minor pieces to passive squares like [Square] congests the back rank.",
                "Making a move that your opponent can answer with a developing move only gives away free tempos.",
                "It blocks the natural path of the surrounding pawns, creating a bottleneck in the camp.",
                "[Player] is playing as if the board is empty, completely ignoring operational threats.",
            ],
            conclusions: &[
                "Speed is everything in the opening.",
                "This is an invitation to immediate pressure.",
                "GM Chanakya always teaches: prioritize piece harmony.",
                "A clear misdirection of resources.",
                "Expect the opponent to exploit this bottleneck shortly.",
                "You cannot afford to lose tempos like this.",
                "A skilled tactician will expose this weakness soon.",
                "A passive submission that hurts your prospects.",
            ],
        },
        "B1" => CommentaryComponents {
            intros: &[
                "Magnificent placement!",
                "A masterful positional repositioning.",
                "Surgical precision by [Player].",
                "This is textbook positional asphyxiation.",
                "An excellent re-routing maneuver.",
                "Dominating the open file.",
                "A beautiful demonstration of piece harmony.",
                "Increasing the strategic tension.",
            ],
            observations: &[
                "The [Piece] anchors itself firmly onto the [Square] outpost—a pristine operational base.",
                "The [Piece] was doing nothing on its old square; now it acts as a central coordinator.",
                "[Player] identifies the structural hole on [Square] and immediately occupies it.",
                "Step by step, piece by piece, [Player] is restricting the oxygen supply of the opponent's army.",
                "It exemplifies the patient preparation GM Chanakya preaches—improving the worst-placed piece.",
                "By placing the rook/queen on [Square], [Player] establishes an open highway into the enemy camp.",
                "Every element of [Player]'s setup is working toward a clear, strategic objective.",
                "Instead of rushing into a trade, this move maintains pressure and forces a tough choice.",
            ],
            conclusions: &[
                "It will radiate immense pressure across the enemy camp.",
                "The opponent's defensive options are paralyzed.",
                "That piece cannot be easily evicted, making it a permanent thorn.",
                "A high-level positional decision.",
                "The strategic advantage is slowly but surely shifting.",
                "The pressure on the opponent is mounting.",
                "A class act in positional mastery.",
                "A masterpiece of tactical restraint.",
            ],
        },
        "B2" => CommentaryComponents {
            intros: &[
                "A strategic blunder that will haunt [Player].",
                "This pawn push is an act of structural self-sabotage.",
                "Unforced panic in the camp.",
                "A short-sighted trade.",
                "Overextension on the kingside!",
                "A passive concession.",
                "This is a classic 'bad bishop' scenario.",
                "Allowing pawns to be doubled is positionally irresponsible.",
            ],
            observations: &[
                "Crippling the pawn skeleton with this unforced capture creates a permanently isolated pawn on [Square].",
                "It leaves behind a gaping hole on [Square] that will serve as a holiday home for the enemy.",
                "By altering the pawn tension this way, [Player] transforms a dynamic structure into a backward mess.",
                "Giving up the active piece leaves [Player]'s complex of squares dangerously naked.",
                "This aggressive pawn advance creates irreversible structural damage around the king.",
                "Giving up the active center for a defensive posture condemns [Player] to a long defense.",
                "[Player] places another pawn on the same color as their own bishop, reducing its mobility.",
                "The choice to abandon the central blockade allows the opponent's pawns to become active.",
            ],
            conclusions: &[
                "A lapse in tactical prophylaxis.",
                "The endgame prospects just took a massive dive.",
                "This will require constant protection for the rest of the game.",
                "Converting a safe shelter into a house of cards.",
                "A skilled opponent will exploit this fifty moves down the line.",
                "A slow institutional suicide.",
                "The structural foundation is crumbling.",
                "A high price to pay for a superficial threat.",
            ],
        },
        "C1" => CommentaryComponents {
            intros: &[
                "An absolute tactical catastrophe on [Square].",
                "Total blindness from [Player].",
                "A catastrophic hallucination.",
                "This is a tactical disaster.",
                "An unimaginable blunder.",
                "A complete collapse of board vision.",
                "A fatal tactical oversight.",
                "Disastrous calculation.",
            ],
            observations: &[
                "[Player] completely misses a rudimentary tactical sequence, dropping material.",
                "[Player] walks directly into a devastating pin/fork that was entirely predictable.",
                "[Player] believed this was an attack, but overlooked a simple defensive response.",
                "The [Piece] on [Square] is left completely unguarded—hanging like a ripe fruit.",
                "At the academy, we call this 'playing chess with your eyes closed.'",
                "[Player] steps into a forced mate sequence that is easily spotted.",
                "This move unprotects the back rank, leaving the king vulnerable.",
                "[Player] initiated a trade sequence on [Square] without counting the defenders accurately.",
            ],
            conclusions: &[
                "Game over at this level.",
                "A shocking lapse in concentration that destroys hours of work.",
                "Leaves [Player] down a piece for zero compensation.",
                "The immediate tactical punishment is severe.",
                "The position collapses instantly.",
                "A psychological breakdown under minor pressure.",
                "All strategic sanity has been abandoned.",
                "A basic arithmetic failure.",
            ],
        },
        "C2" => CommentaryComponents {
            intros: &[
                "Sensational!",
                "Surgical violence of the highest order.",
                "Deep, computer-like calculation.",
                "An absolutely sparkling tactical execution.",
                "A breathtaking intermediate move (Zwischenzug)!",
                "Pure artistry on the board.",
                "An astonishing clearance sacrifice.",
                "A tactical masterpiece.",
            ],
            observations: &[
                "[Player] uncorks a spectacular sacrifice on [Square] that shatters the defensive shell.",
                "This stunning move exploits a hidden geometry on the board, forcing material gain.",
                "[Player] realized that the apparent loss of material actually leads to a forced win.",
                "It completely scrambles the opponent's defensive communication, exposing the king.",
                "Instead of recapturing immediately, [Player] inserts this deadly check, causing chaos.",
                "This quiet, non-checking move leaves the opponent completely paralyzed.",
                "By sacrificing the pawn on [Square], [Player] clears a high-speed highway for the attack.",
                "[Player] masterfully orchestrates a double attack that leaves two major pieces hanging.",
            ],
            conclusions: &[
                "A move of profound tactical beauty.",
                "Spotting a subtle alignment defect in the opponent's camp is highly rewarding.",
                "A profound tactical liquidation that transitions into a winning endgame.",
                "The opponent is left completely without answers.",
                "It will be remembered as a brilliant strike.",
                "Simply world-class calculation.",
                "The execution is flawless.",
                "A decisive blow that ends all resistance.",
            ],
        },
        "D1" => CommentaryComponents {
            intros: &[
                "An impeccable display of endgame technique.",
                "A masterclass in endgame principles.",
                "Surgical endgame calculation.",
                "Beautifully clean simplification.",
                "Flawless truncation of options.",
                "The ultimate triumph of patience.",
                "Excellent execution of theoretical mechanics.",
                "Highly sophisticated square calculation.",
            ],
            observations: &[
                "[Player] understands that in the endgame, the king is an active attacking piece.",
                "The passed pawn on the [Square] file is transformed into an absolute monster.",
                "[Player] systematically stretches the opponent's lone defensive pieces.",
                "This precise king maneuver secures the opposition, forcing the enemy king to yield.",
                "By forcing a rook/piece trade, [Player] transitions into a mathematically won pawn ending.",
                "[Player] uses extra material to create a textbook dynamic barrier.",
                "[Player] slowly suffocates the remaining active enemy pieces.",
                "This quiet king step completely neutralizes the opponent's desperate counterplay.",
            ],
            conclusions: &[
                "Activating the king is vital in the endgame.",
                "With every step it takes, the opponent's options shrink.",
                "Reaching a breaking point is inevitable for the defense.",
                "No room for counterplay remains.",
                "Converting a tiny positional edge into a full point.",
                "A textbook demonstration of outside passed pawn geometry.",
                "A clean, technical victory.",
                "The win is now a simple matter of technique.",
            ],
        },
        "D2" => CommentaryComponents {
            intros: &[
                "A horrific technical blunder.",
                "An unpardonable lapse in basic endgame knowledge.",
                "Tragic carelessness from [Player].",
                "A basic calculation error regarding pawn square geometry.",
                "An unforced tactical giveaway in the endgame.",
                "Completely misjudging the king's path.",
                "A passive defensive mindset.",
                "A shocking failure to spot a basic defense.",
            ],
            observations: &[
                "Leaving the king hidden in the corner during a minor piece endgame is heresy.",
                "This premature pawn push allows the opponent to establish a permanent blockade.",
                "[Player] had a trivial technical conversion but allowed the enemy rook/piece to infiltrate.",
                "[Player] failed to count the squares accurately, allowing the king to kill the pawn.",
                "By dropping a critical pawn on the kingside, [Player] gives the opponent a new lease on life.",
                "This roundabout journey allows the opponent's passed pawn to gain critical tempos.",
                "Rook endgames must be played with activity; this passive defense is slow suicide.",
                "[Player] rushed the conversion and walked straight into a stalemate trap.",
            ],
            conclusions: &[
                "In the endgame, the king must fight!",
                "This turns a clean win into a disappointing draw.",
                "This will create chaos and cost the win.",
                "The win has slipped directly through [Player]'s fingers.",
                "This is why players must study their theoretical endgames.",
                "An expensive lesson in endgame precision.",
                "A heartbreaking throwaway of a hard-fought game.",
                "A basic arithmetic oversight.",
            ],
        },
        _ => CommentaryComponents {
            intros: &["GM Chanakya is contemplating..."],
            observations: &["observing the board state."],
            conclusions: &["The path forward remains yours to choose."],
        },
    }
}

fn select_index_with_ring_buffer(category: &str, length: usize) -> usize {
    if length <= 1 {
        return 0;
    }
    if let Ok(mut history) = get_history().lock() {
        let entry = history.entry(category.to_string()).or_insert_with(Vec::new);
        let mut available = Vec::new();
        for i in 0..length {
            if !entry.contains(&i) {
                available.push(i);
            }
        }
        if available.is_empty() {
            entry.clear();
            for i in 0..length {
                available.push(i);
            }
        }

        // Standard hash/pseudo-random seed derived from current system time
        let seed = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.as_nanos())
            .unwrap_or(0);
        let selected_index = (seed % (available.len() as u128)) as usize;
        let val = available[selected_index];

        entry.push(val);
        if entry.len() > 4 {
            entry.remove(0);
        }
        val
    } else {
        0
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_gates_opening_conformity() {
        let text = select_commentary_template_rust(
            "Strong".to_string(),
            "".to_string(),
            "Opening".to_string(),
            0.6,
            false,
            false,
            false
        );
        // Should pull from A1 components
        let comp = get_components_for_category("A1");
        assert!(comp.intros.iter().any(|&intro| text.contains(intro)));
        assert!(comp.conclusions.iter().any(|&conc| text.contains(conc)));
    }

    #[test]
    fn test_gates_compound_blunder() {
        let text = select_commentary_template_rust(
            "Blunder".to_string(),
            "Mistake".to_string(),
            "Middlegame".to_string(),
            -3.5,
            false,
            false,
            false
        );
        // Compounded blunder scenario
        assert!(text.contains("doubles down on bad calculations"));
    }
}
