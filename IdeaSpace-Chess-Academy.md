# IdeaSpace Chess Academy: The Ultimate Grandmaster Experience

IdeaSpace Chess Academy is a state-of-the-art Android mobile chess application that blends a professional, modern "Scholarly" aesthetic with cutting-edge High Council AI and the world-class Stockfish S-engine.

---

## 🚀 Core Features

### 1. Advanced Chess Gameplay
- **True UCI Integration**: Full support for the Universal Chess Interface protocol via native `libstockfish.so`.
- **Move Validation**: Precise legal move detection including En Passant, Castling, and Pawn Promotion.
- **Game States**: Handles Check, Checkmate, Stalemate, and Draw by Repetition/50-move rule.
- **Undo/Redo**: Complete history tracking for move traversal with snapshot-based state restoration.
- **Side Switching**: Ability to flip the board and play as either White or Black while maintaining "Down = User" ergonomics.

### 2. High Council (AI)
- **On-Demand Grandmaster**: The High Council AI (powered by Sarvam/Gemini) reveals strategic insights only when explicitly requested.
- **Thought Stripping**: Integrated logic ensures the AI's internal thoughts (<think> blocks) are removed for professional delivery.
- **Witty Personality**: Specifically tuned to deliver short, sharp, and grandmaster-style insights.
- **Sleek Interface**: Refined chat-focused commentary with bubble-style messaging for a premium conversational feel.

### 3. Engine-Grade Analysis & Robot Mode
- **Stockfish ARMv8**: Integrated legendary chess engine optimized for mobile performance.
- **Robot Mode**: One-click "Engine vs Engine" gameplay where Stockfish plays itself.
- **Real-time Eval**: A dynamic evaluation bar showing the current material and positional advantage.
- **Difficulty Scaling**: Adjustable skill levels (A-E) from beginner to grandmaster.
- **Analysis Placeholder**: The lightbulb icon remains as a non-functional placeholder to maintain UI balance while focusing on direct gameplay.

### 4. Modern Scholarly Aesthetic
- **Professional Design**: A sleek, minimal "office-style" interface using the custom Scholarly design system.
- **Turn Indicators**: Contrasting pulsing Knight icons (White-on-Black and Black-on-White) in the header to clearly show active player.
- **Glassmorphism**: Elegant transparent panels and blur effects (GlassPanel) for a premium feel.
- **High Council Interface**: Interactive AI profile image with a pulsing glow when analyzing and a grayscale effect when idle.
- **Dynamic Splash Screen**: A professional boot-up sequence synchronized with game service initialization.

---

## 🎨 UI & UX Details

### Layout Components
- **`MainPage`**: The root container featuring a modern, distraction-free scholarly environment.
- **`BoardStage`**: The focal point, featuring a responsive board with a modular theme engine.
- **`CommentaryHistory`**: A sleek, metric-free chat interface for communicating with the High Council.
- **`EvaluationBar`**: A precision-engineered vertical gauge providing instant feedback on positional advantage.
- **`GameMetrics`**: Displays high-precision game clocks and turn status.
- **`PromotionOverlay`**: A dedicated "Ascension" interface for selecting pawn promotion pieces.

### Custom Effects
- **Movement Trails**: Visual indicators for the last move made.
- **Check Animation**: Subtle UI alerts when a King is under attack.
- **Settings Dashboard**: Redesigned layout with compact icons and persistent theme selection.

---

## 🎬 Cinematic Animation System

### 1. Dynamic Board Camera
- **Intelligent Drift**: The board subtly shifts based on the direction of the move, creating a sense of momentum.
- **Dynamic Zoom**: Automatic camera zooming for captures (subtle), checks (medium), and checkmates (dramatic).
- **Saturation Shift**: A grayscale "time-dilation" effect applied to the board during checkmate events.

### 2. Signature Piece Identities
Every piece type has a unique motion profile defined in `PieceMotionProfile`:
- **♟ Pawns**: Fast, flat, and persistent glides.
- **♞ Knights**: Arced "jumping" movement with a signature mid-air tilt.
- **♝ Bishops**: Ultra-smooth diagonal transits with faint ghost trails.
- **♜ Rooks**: Heavy, grounded movement with strong deceleration and landing compression.
- **♛ Queens**: Fast, dominant, and fluid transits with a confident "levitation" presence.
- **♚ Kings**: Deliberate and cautious pace with fragile, minimal settle effects.

### 3. Tactile Feedback & Interaction
- **Landing Settle**: Pieces exhibit physical weight through micro-settle compression and spring-back effects upon landing.
- **Breathing Selection**: Selected pieces exhibit a subtle 1–2% "living" breath cycle to indicate focus.
- **Check Pulse**: The King piece pulses with a gentle scale oscillation when in check, heightening tactical tension.
- **Interactive Tap Ripples**: High-fidelity visual ripples propagate from squares upon selection.

---

## ✨ Chessboard & Piece Themes

### 1. Modular Theme Engine
- **Decoupled Architecture**: Board and piece rendering are fully decoupled via a polymorphic `ChessTheme` system.
- **Theme Registry**: Centralized management for all 10 visual styles (Classic, Forest, Ink, Platinum, Steampunk, Matrix, Slate, Walnut, Toy, Shadow).
- **Persistence**: User-selected themes are saved and restored across sessions.

### 2. Advanced Square Animations
- **The "Orbiting Star"**: A High-Precision `CustomPainter` effect that orbits the perimeter of selected, engine-recommended (Gold), and threatened (Red) squares.
- **Smooth Transitions**: `AnimatedContainer` logic for square color shifts and border highlights.

### 3. Accessibility & Contrast
- **Theme Optimization**: Refined contrast for "Digital Matrix" and "Forest" themes to ensure piece visibility.
- **High-Contrast Pieces**: Optional high-visibility piece sets for improved accessibility.

---

## 🧠 AI & Engine Architecture

### 1. The "Engine" Layer (Stockfish / S-engine)
- **Binary Management**: Managed via `StockfishService` using a native Android library (`libstockfish.so`).
- **Gameplay Authority**: The S-engine is responsible for all board moves, executing strikes immediately upon calculation.
- **UCI Protocol**: Communicates via `stdin/stdout`, translating FEN strings into evaluations and moves.

### 2. The "Brain" Layer (High Council / AI)
- **Engine**: Powered by Sarvam AI / Gemini Cloud via a dedicated Python FastAPI backend.
- **On-Demand Intelligence**: Remains silent by default, only revealing insights when explicitly requested (Hints/Chat).
- **Decoupled Workflow**: Completely separated from the S-engine's move execution to ensure rapid gameplay.

### 3. The "Bare-Metal" State Layer (Rust FFI / `shakmaty`)
- **Native Bitboard Authority**: Integrated bare-metal Rust core via `flutter_rust_bridge` to handle advanced board mechanics instantly.
- **Unified Logic Handling**: Evaluates real-time threats, precise status conditions (check/mate/stalemate), legal move destination arrays, and blazingly fast PGN/SAN tape assembly directly on 64-bit CPU bitmasks.
- **Side-by-Side Parity Checks**: Runs non-blocking microsecond validation in parallel with Dart state for seamless runtime reliability.

---

## 🛠️ System Wiring

### 1. State Hub (`Riverpod` & FFI Core)
- **`ChessProvider`**: Manages the application lifecycle, orchestration loops, and persistent configurations.
- **`ChessGame` Domain Model**: Encapsulates unified board state management, querying native Rust FFI interfaces (`moves.rs`, `status.rs`, `state.rs`, `history.rs`) to compute legal moves and status conditions in microseconds.
- **`StockfishController`**: Bridges the Flutter state with the native engine process.

### 2. Communication Loop
1.  **User Action**: Piece movement and square selections trigger native Rust bitboard destination arrays and state validation.
2.  **Engine Dispatch**: Valid moves trigger a FEN update to the S-engine.
3.  **Immediate Strike**: S-engine responds with a move calculation.
4.  **Requested Insight**: High Council (AI) provides contextual narration on demand.

---

## 📝 Implementation Roadmap

### Phase 1: Engine Stability
- [x] Integrate Stockfish process management.
- [x] Implement UCI communication loop.
- [x] Fix cross-platform pathing (Windows/Android).

### Phase 2: AI Integration & Backend Council
- [x] Set up Sarvam AI API integration.
- [x] Build context-aware prompt engineering.
- [x] **Complete**: Strip AI internal monologue in the backend logic.
- [x] **Complete**: Decouple S-engine moves from High Council narration.

### Phase 3: Visual Polish & UI Mastery
- [x] Modernize UI from Windows 98 to Scholarly/Office style.
- [x] Implement Checkmate/Game Over/Draw modals with GlassPanel logic.
- [x] **Complete**: Implement modular `ChessTheme` system and Registry.
- [x] **Complete**: Redesign Settings page and compact icons.

### Phase 4: Intelligence & Refinement
- [x] Implement "On-Demand" High Council intelligence (Hints/Chat).
- [x] **Complete**: Implement pulsing Knight turn indicators in header.
- [x] **Complete**: Finalize Save/Load persistent storage and Theme persistence.
- [x] **Complete**: Implement time controls and auto-play delay settings.
- [x] **Complete**: Transition Analysis Mode to placeholder for sleeker UX.

### Phase 5: Cinematic Excellence
- [x] **Complete**: Implement Cinematic Board Camera with dynamic zoom and drift.
- [x] **Complete**: Implement Signature Movement profiles for all piece types.
- [x] **Complete**: Add Landing Feedback (micro-settle) and Tap Ripple systems.
- [x] **Complete**: Implement Breathing Selection and King Check pulse effects.
- [x] **Complete**: Refine theme contrast and accessibility.

### Phase 6: Bare-Metal Core Optimization (Complete)
- [x] **Complete**: Scaffold `flutter_rust_bridge` infrastructure and high-speed `shakmaty` core logic.
- [x] **Complete**: Implement instant multi-threaded square Threat evaluation engine.
- [x] **Complete**: Migrate game termination Status conditions (check/checkmate/stalemate) to native bitmask verifications.
- [x] **Complete**: Embed microsecond Legal Destinations arrays and multi-move post-state validation directly inside the UI selection pipelines.
- [x] **Complete**: Assemble unified bare-metal PGN/SAN tape compilation.
