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
    _has_fork: bool,
    _has_pin: bool,
    _has_hanging: bool,
) -> String {
    // 1. Narrative Continuity / Transition Anchors
    if previous_quality == "Blunder" || previous_quality == "Mistake" {
        if quality == "Blunder" || quality == "Mistake" {
            // Scenario A: Compounded Blunder
            let openers = &[
                "Unbelievable! Instead of realizing the danger pointed out on the last move, [Player] doubles down on bad calculations with [Move]. This isn't just an error; it's a structural collapse.",
                "Astonishing! The very warning I issued moments ago has been disregarded. [Player] piles another blunder onto the previous one with [Move] — a cascading failure of board vision.",
                "Alarming! [Player] compounds the previous mistake, doubling down on misguided logic with [Move]. The position now borders on the indefensible.",
                "A second blow to their own position — [Player] fails to absorb the lesson of the previous move and walks further into trouble with [Move]. The rot sets in deeper.",
            ];
            let idx = time_seed() % openers.len();
            return openers[idx].to_string();
        }
        if quality == "Brilliant" || quality == "Strong" {
            // Scenario B: Tactical Refutation
            let openers = &[
                "And there is the swift punishment GM Chanakya warned you about. [Player] instantly spots the structural opening left on the previous move and delivers a crushing tactical blow with [Move].",
                "The reckoning arrives. [Player] seizes on the weakness left by the prior blunder and strikes decisively with [Move] — a cold, clinical refutation.",
                "Swift justice. [Player] identifies the tactical fracture created on the previous turn and exploits it immediately with [Move]. This is how masters punish errors.",
                "The error has been answered. [Player] converts the positional gift from the prior mistake into a concrete advantage with [Move]. A textbook punishment.",
            ];
            let idx = time_seed() % openers.len();
            return openers[idx].to_string();
        }
    } else if (previous_quality == "Neutral" || previous_quality == "Strong") && quality == "Strong" {
        // Scenario C: Steady Improvement
        let openers = &[
            "Building beautifully upon the solid development of the previous phase, [Player] pushes the advantage further with [Move]. The pressure is mounting.",
            "The momentum continues. Following the strong prior sequence, [Player] maintains the initiative with [Move] and keeps the opponent firmly on the defensive.",
            "A chain of precision. [Player] consolidates the gains of the last move and escalates the strategic pressure with [Move]. There is no respite for the opponent.",
            "The rhythm is consistent. [Player] continues to pile up small advantages, and [Move] is the latest link in a sequence of strong decisions.",
        ];
        let idx = time_seed() % openers.len();
        return openers[idx].to_string();
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
        } else if quality == "Strong" {
            "B1" // Outpost Creation / Piece Optimization
        } else {
            // Inaccuracy, Neutral
            if quality == "Inaccuracy" || eval_diff <= -0.5 {
                "B2" // Structural Degradation
            } else {
                "B1" // Outpost Creation / Piece Optimization
            }
        }
    };

    // 3. Shuffling Ring-Buffer index selection
    let comp = get_components_for_category(category);
    let hook_idx   = select_index_with_ring_buffer(&format!("{}_hook",  category), comp.hooks.len());
    let intro_idx  = select_index_with_ring_buffer(&format!("{}_intro", category), comp.intros.len());
    let obs_idx    = select_index_with_ring_buffer(&format!("{}_obs",   category), comp.observations.len());
    let conc_idx   = select_index_with_ring_buffer(&format!("{}_conc",  category), comp.conclusions.len());

    format!(
        "{} {} {} {}",
        comp.hooks[hook_idx],
        comp.intros[intro_idx],
        comp.observations[obs_idx],
        comp.conclusions[conc_idx]
    )
}

struct CommentaryComponents {
    hooks:        &'static [&'static str],
    intros:       &'static [&'static str],
    observations: &'static [&'static str],
    conclusions:  &'static [&'static str],
}

fn get_components_for_category(category: &str) -> CommentaryComponents {
    match category {

        // ── A1: Opening – High Theoretical Conformity ─────────────────────────
        "A1" => CommentaryComponents {
            hooks: &[
                "At this early juncture,",
                "In the opening theater,",
                "With development still unfolding,",
                "This early in the game,",
                "In these critical first moves,",
                "As the armies marshal their forces,",
                "Before the first real battle is joined,",
                "In this foundational phase,",
            ],
            intros: &[
                "A perfectly respectable choice here.",
                "Classic textbook chess.",
                "GM Chanakya approves.",
                "Sound development.",
                "An elegant step.",
                "Maintaining structural harmony.",
                "A standard weapon in this setup.",
                "Clean, unpretentious development.",
                "A principled, theory-aligned decision.",
                "Solid positional reasoning behind this.",
                "A move that speaks to experience.",
                "The engine nods in quiet agreement.",
                "This is how the masters open the fight.",
                "An unhurried, confident step forward.",
                "Precision before creativity.",
                "A calm foundation, correctly laid.",
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
                "Connecting the minor pieces and eyeing central squares — a disciplined sequence.",
                "Each developing move builds toward a coordinated, unified army.",
                "[Player] avoids the temptation to move prematurely, instead completing the setup.",
                "The pawn triangle forms a sturdy platform from which to launch later operations.",
                "No dramatic gestures here — just clean, focused development.",
                "This keeps all strategic options alive, committing to nothing prematurely.",
                "[Player] follows the cardinal rule: develop, castle, unite the rooks.",
                "This quiet improvement makes the entire position subtly more harmonious.",
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
                "The position holds no weaknesses — a sign of opening mastery.",
                "Every pawn and piece serves a purpose.",
                "The structural foundation is sound and ready for the middlegame.",
                "A patient build-up that leaves nothing exposed.",
                "Textbook opening play — nothing more, nothing less, and that is enough.",
                "A position that gives the opponent nothing free to target.",
                "The troops are assembled. The true battle is about to begin.",
                "Understated, yet deeply correct.",
            ],
        },

        // ── A2: Opening – Early Inaccuracies ──────────────────────────────────
        "A2" => CommentaryComponents {
            hooks: &[
                "So early in the game, and already",
                "In this critical development phase,",
                "Before even completing basic development,",
                "At this delicate opening stage,",
                "With the armies barely deployed,",
                "In the first few moves — of all times —",
                "This early in the contest,",
                "In the opening, where every tempo counts,",
            ],
            intros: &[
                "A severe violation of opening principles.",
                "Premature enthusiasm here.",
                "A positional luxury that [Player] simply cannot afford.",
                "This move lacks dynamic urgency.",
                "An erratic choice by [Player] in the opening.",
                "A superficial threat that is easily defused.",
                "Neglecting prophylaxis this early is dangerous.",
                "An awkward square for the [Piece].",
                "A tempo squandered at the worst possible moment.",
                "This goes against every opening principle in the book.",
                "A positional concession before the fight has truly begun.",
                "The opponent will not let this invitation go unanswered.",
                "This gives away the initiative without compensation.",
                "A passive choice where activity was demanded.",
                "Moving the wrong piece at the wrong time.",
                "This creates a problem that will take moves to resolve.",
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
                "This allows the opponent to plant a piece on a strong central square with tempo.",
                "By delaying castling, [Player] leaves the king exposed to central file threats.",
                "The bishop buries itself behind its own pawns — a passive, congested placement.",
                "The knight retreats to the rim, the worst possible square, just as the fight begins.",
                "This pawn advance prematurely weakens the king's shelter before castling.",
                "Grabbing a pawn at the cost of 3 tempos and a compromised position is poor arithmetic.",
                "[Player] ignores the opponent's central pressure in favor of a meaningless flank maneuver.",
                "The position cries out for piece development; this pawn move answers a question nobody asked.",
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
                "Every wasted move is a free turn handed to the opposition.",
                "This will cost dearly in the coming middlegame.",
                "An opponent with any opening knowledge will seize this chance immediately.",
                "The price of this inaccuracy will be collected with interest.",
                "The development deficit begins here — and it rarely gets repaid.",
                "This passivity emboldens the opponent to play boldly and freely.",
                "A structural blemish in an otherwise manageable position.",
                "In chess, free tempos are never truly free for the one who gives them.",
            ],
        },

        // ── B1: Middlegame – Piece Optimization / Outpost Creation ────────────
        "B1" => CommentaryComponents {
            hooks: &[
                "In this rich middlegame,",
                "As the position crystallizes,",
                "At this critical juncture,",
                "With the middlegame fully engaged,",
                "In this strategically charged moment,",
                "As both armies vie for control,",
                "With the initiative firmly in hand,",
                "In this subtle, high-level position,",
            ],
            intros: &[
                "Magnificent placement!",
                "A masterful positional repositioning.",
                "Surgical precision by [Player].",
                "This is textbook positional asphyxiation.",
                "An excellent re-routing maneuver.",
                "Dominating the open file.",
                "A beautiful demonstration of piece harmony.",
                "Increasing the strategic tension.",
                "A move of quiet, profound strength.",
                "The hallmark of a true strategist.",
                "A calm, controlled escalation of pressure.",
                "Positional mastery distilled into a single move.",
                "An understated move with enormous consequences.",
                "The best piece improves itself.",
                "A move that changes the whole geometry of the position.",
                "Elegant in its simplicity, devastating in its effect.",
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
                "The [Piece] now eyes both flanks simultaneously, maximizing its operational radius.",
                "This creates a powerful battery that the opponent simply cannot ignore.",
                "The knight on [Square] is a monster — it cannot be evicted by any pawn.",
                "The rook lifts from its passive role and enters the game as an active, dangerous weapon.",
                "[Player] does not rush; instead, every piece is placed on its ideal square before striking.",
                "A quiet prophylactic move that prevents the opponent's main counterplay idea.",
                "By controlling [Square], [Player] cuts the enemy army in half.",
                "The coordinated activity of [Player]'s pieces creates threats on multiple fronts.",
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
                "The opponent must now solve an uncomfortable equation.",
                "Every additional move tightens the strategic vice.",
                "The position is becoming technically winning for [Player].",
                "Long-term, this outpost will prove more valuable than any material gain.",
                "The resulting zugzwang-like pressure will be very hard to endure.",
                "A quiet move that speaks loudly about the difference in understanding.",
                "The walls close in — slowly, inevitably.",
                "From here, the conversion is a matter of technique and patience.",
            ],
        },

        // ── B2: Middlegame – Structural Degradation ───────────────────────────
        "B2" => CommentaryComponents {
            hooks: &[
                "In this sharp middlegame position,",
                "At this critical moment,",
                "With the evaluation already under pressure,",
                "In this delicate structural moment,",
                "As the imbalances reach a tipping point,",
                "At this key decision point,",
                "With both sides in a complex fight,",
                "In this tense, charged position,",
            ],
            intros: &[
                "A strategic blunder that will haunt [Player].",
                "This pawn push is an act of structural self-sabotage.",
                "Unforced panic in the camp.",
                "A short-sighted trade.",
                "Overextension on the kingside!",
                "A passive concession.",
                "This is a classic 'bad bishop' scenario.",
                "Allowing pawns to be doubled is positionally irresponsible.",
                "A decision made without counting the structural cost.",
                "A positional misjudgment that creates lasting damage.",
                "An unnecessary weakening of the pawn skeleton.",
                "The position demanded activity; this move offers passivity.",
                "A trade that benefits the opponent far more than [Player].",
                "This move surrenders the strategic high ground.",
                "An impulsive decision that violates structural principles.",
                "A slow deterioration, chosen voluntarily.",
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
                "The resulting isolated pawn on [Square] becomes a chronic target that demands constant attention.",
                "This exchange surrenders the bishop pair, giving the opponent a long-term positional advantage.",
                "The doubled pawns on this file are immobile and indefensible in the coming endgame.",
                "By releasing the central tension, [Player] removes all fighting chances from the position.",
                "The knight retreats to a passive square, abandoning its grip on the key central outpost.",
                "This backward pawn on [Square] will require a permanent piece to defend it.",
                "The king's shelter crumbles with this advance — a luxury the position cannot afford.",
                "The resulting bad bishop is completely entombed behind its own pawns, a purely decorative piece.",
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
                "The chronic weakness created here will outlast the game.",
                "The positional seeds of defeat have been sown.",
                "A self-inflicted wound that the opponent will never let heal.",
                "The endgame conversion just became significantly harder.",
                "From today, [Player] must defend this weakness forever.",
                "A subtle move with catastrophic long-term consequences.",
                "The opponent now has a permanent target to aim at.",
                "This is the kind of position that makes endgame books.",
            ],
        },

        // ── C1: Middlegame – Major Blunders ───────────────────────────────────
        "C1" => CommentaryComponents {
            hooks: &[
                "In what should have been a controlled position,",
                "With the game hanging in the balance,",
                "At this critical crossroads,",
                "In a position that demanded extreme care,",
                "With so much at stake in this moment,",
                "In this sharp, unforgiving middlegame,",
                "Just when precision was most needed,",
                "When the slightest inaccuracy proves fatal,",
            ],
            intros: &[
                "An absolute tactical catastrophe on [Square].",
                "Total blindness from [Player].",
                "A catastrophic hallucination.",
                "This is a tactical disaster.",
                "An unimaginable blunder.",
                "A complete collapse of board vision.",
                "A fatal tactical oversight.",
                "Disastrous calculation.",
                "A stunning lapse in concentration.",
                "The hand moved before the mind finished calculating.",
                "A blunder of the highest magnitude.",
                "An oversight that destroys the game in one stroke.",
                "The position demanded one thing; [Player] delivered the opposite.",
                "A self-destruct sequence in a single move.",
                "One move ends all the careful work that preceded it.",
                "A haunting miscalculation that will echo in the post-mortem.",
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
                "The simple defensive resource [Player] overlooked would have held the position easily.",
                "A one-move combination that any intermediate player would spot ends the game here.",
                "[Player] creates an undefended piece on [Square] while ignoring the opponent's obvious reply.",
                "The back rank collapses without warning — a classic oversight in a complex position.",
                "A discovered attack on the queen was hiding behind this advance; [Player] did not see it.",
                "[Player] misses that the [Piece] is now pinned, and the entire calculation falls apart.",
                "The double attack after this move wins material immediately — a basic tactical pattern.",
                "[Player] captures the wrong piece in the sequence, reversing the intended outcome entirely.",
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
                "The opponent will not hesitate to deliver the punishment.",
                "This single move turns a comfortable game into a lost one.",
                "Chess is cruel, and a single oversight is all it takes.",
                "The damage is irreparable from this point.",
                "The tactical fall-out of this move is immeasurable.",
                "A position that was salvageable has become hopeless.",
                "From a competitive game to a matter of resignation.",
                "The endgame begins — already down material, against a precise opponent.",
            ],
        },

        // ── C2: Middlegame – Brilliant / Surgical Strike ──────────────────────
        "C2" => CommentaryComponents {
            hooks: &[
                "In this complex, razor-sharp position,",
                "Amidst the tactical chaos,",
                "In this moment of profound calculation,",
                "Where lesser players would hesitate,",
                "In a position of extreme complexity,",
                "When the board demanded a genius-level solution,",
                "With the entire game hanging on a single move,",
                "In this breathtaking tightrope of a position,",
            ],
            intros: &[
                "Sensational!",
                "Surgical violence of the highest order.",
                "Deep, computer-like calculation.",
                "An absolutely sparkling tactical execution.",
                "A breathtaking intermediate move (Zwischenzug)!",
                "Pure artistry on the board.",
                "An astonishing clearance sacrifice.",
                "A tactical masterpiece.",
                "A move of devastating elegance.",
                "The kind of move that silences the room.",
                "An unexpected resource that changes everything.",
                "A stunning conception, flawlessly executed.",
                "The engine bows its head in respect.",
                "A profound quiet move — the hardest kind to find.",
                "A blinding tactical shot from a seemingly quiet position.",
                "This is why we study chess — for moments like this.",
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
                "The sacrifice on [Square] opens the diagonal and exposes the king to a decisive attack.",
                "An in-between move that the opponent had completely failed to anticipate.",
                "[Player] sidesteps the obvious recapture and delivers a move of immense subtlety.",
                "The combination unfolds across five moves — all seen and calculated in advance.",
                "A pin-breaking sacrifice that transitions the game from complexity to a clean win.",
                "By deflecting the key defender, [Player] creates an unstoppable mating net.",
                "The quiet rook move to [Square] is the key — it ties the opponent's pieces in knots.",
                "[Player] finds the only winning move in a sea of plausible alternatives.",
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
                "The curtain falls on the opponent's hopes.",
                "Precision of this caliber is rare even at the grandmaster level.",
                "A combination that will appear in tactical textbooks.",
                "The beauty of chess is fully on display here.",
                "The opponent's position disintegrates like a house of cards.",
                "Calculation that borders on the inhuman.",
                "This is what separates champions from pretenders.",
                "A moment of pure chess artistry.",
            ],
        },

        // ── D1: Endgame – Flawless Technical Conversion ───────────────────────
        "D1" => CommentaryComponents {
            hooks: &[
                "In this technical endgame position,",
                "With the game entering its final phase,",
                "As the dust of the middlegame settles,",
                "In this precise endgame scenario,",
                "With the win within reach,",
                "As the decisive phase approaches,",
                "In this endgame that demands perfect technique,",
                "With only the most accurate play winning,",
            ],
            intros: &[
                "An impeccable display of endgame technique.",
                "A masterclass in endgame principles.",
                "Surgical endgame calculation.",
                "Beautifully clean simplification.",
                "Flawless truncation of options.",
                "The ultimate triumph of patience.",
                "Excellent execution of theoretical mechanics.",
                "Highly sophisticated square calculation.",
                "A quiet, inevitable step toward the win.",
                "The hallmark of a complete player.",
                "Endgame mastery in its purest form.",
                "Economy and precision — the two virtues of the endgame.",
                "A move that demonstrates deep theoretical knowledge.",
                "Patience weaponized into a winning technique.",
                "Clinically eliminating all counterplay.",
                "An endgame move of textbook elegance.",
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
                "The triangulation maneuver gains a crucial tempo and achieves the opposition.",
                "The Lucena position is reached — from here, the win is purely mechanical.",
                "[Player] marches the king to the queening square, ignoring all diversions.",
                "By cutting off the enemy king with the rook, [Player] creates an unstoppable passer.",
                "The zugzwang is set. Every move the opponent makes worsens their position.",
                "The rook behind the passed pawn is worth more than any piece combination now.",
                "A two-move king maneuver that gains a crucial pawn at the cost of nothing.",
                "The endgame tablebase result was known three moves ago — [Player] is converting perfectly.",
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
                "The opponent has no defense — resignation looms.",
                "From here, the path to the queen is clear and unstoppable.",
                "The technique is impeccable — not a single tempo wasted.",
                "This is endgame chess at its most efficient.",
                "Every move from here is a forced step toward the full point.",
                "The opponent's last piece of hope is extinguished with this king march.",
                "The position is won by any reasonable continuation from here.",
                "A masterful conversion — the hardest part of chess, executed with calm precision.",
            ],
        },

        // ── D2: Endgame – Blunders / Technical Failures ───────────────────────
        "D2" => CommentaryComponents {
            hooks: &[
                "With the win nearly in hand,",
                "In this endgame that required only accuracy,",
                "So close to victory,",
                "In a position that should be straightforward,",
                "With the opponent on the verge of resignation,",
                "Just as the finish line came into view,",
                "In this technically winning endgame,",
                "With full theoretical clarity available,",
            ],
            intros: &[
                "A horrific technical blunder.",
                "An unpardonable lapse in basic endgame knowledge.",
                "Tragic carelessness from [Player].",
                "A basic calculation error regarding pawn square geometry.",
                "An unforced tactical giveaway in the endgame.",
                "Completely misjudging the king's path.",
                "A passive defensive mindset.",
                "A shocking failure to spot a basic defense.",
                "A conversion error that turns victory into ash.",
                "The win was there — and it has been thrown away.",
                "An endgame that any club player would convert, fumbled here.",
                "A stunning miscalculation of the pawn race geometry.",
                "Theoretical ignorance strikes at the worst moment.",
                "Overconfidence leads to an unforced endgame error.",
                "A premature action that undoes all the work of the game.",
                "Technical failure in an otherwise won game.",
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
                "The king needed to be in front of the pawn, not beside it — a basic theoretical error.",
                "This rook trade allows the opponent to blockade with the king — a classic technical pitfall.",
                "The wrong pawn was advanced; the other one was the key to the win.",
                "[Player] fails to use the Lucena or Philidor technique, and the draw escapes the opponent.",
                "A simple counting exercise would have revealed the stalemate threat — overlooked entirely.",
                "The king marches to the wrong square, ceding the opposition at the critical moment.",
                "By capturing this pawn, [Player] walks into a theoretical draw that cannot be avoided.",
                "This knight maneuver, which looks active, actually eliminates all winning chances.",
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
                "A half-point thrown away through a moment of carelessness.",
                "The opponent has been gifted a second life — and they will not waste it.",
                "From a won game, we now have the anguish of a drawn one.",
                "Study the Philidor. Study the Lucena. Let this be the last time.",
                "A game that will haunt the post-mortem analysis.",
                "Endgame study is not optional — this result proves it.",
                "The full point was earned in the middlegame and lost in the endgame.",
                "A costly reminder that endgame technique must be as sharp as tactical vision.",
            ],
        },

        _ => CommentaryComponents {
            hooks:        &["GM Chanakya observes:"],
            intros:       &["GM Chanakya is contemplating..."],
            observations: &["observing the board state."],
            conclusions:  &["The path forward remains yours to choose."],
        },
    }
}

fn time_seed() -> usize {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_nanos() as usize)
        .unwrap_or(0)
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
        if entry.len() > 5 {
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
        // Compounded blunder scenario — one of 4 variants
        let has_expected = text.contains("doubles down on bad calculations")
            || text.contains("piles another blunder")
            || text.contains("compounds the previous mistake")
            || text.contains("A second blow to their own position");
        assert!(has_expected);
    }

    #[test]
    fn test_hooks_prepended() {
        let text = select_commentary_template_rust(
            "Strong".to_string(),
            "".to_string(),
            "Middlegame".to_string(),
            0.4,
            false,
            false,
            false
        );
        // Should not be empty and should have at least 3 words
        let words: Vec<&str> = text.split_whitespace().collect();
        assert!(words.len() > 3);
    }
}
