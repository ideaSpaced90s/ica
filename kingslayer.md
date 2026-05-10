# KINGSLAYER: The Ultimate Grandmaster Experience

KINGSLAYER is a state-of-the-art Android mobile chess application that blends a professional, modern "Scholarly" aesthetic with cutting-edge High Council AI and the world-class Stockfish S-engine.

---

## 🚀 Core Features

### 1. Advanced Chess Gameplay
- **True UCI Integration**: Full support for the Universal Chess Interface protocol.
- **Move Validation**: Precise legal move detection including En Passant, Castling, and Pawn Promotion.
- **Game States**: Handles Check, Checkmate, Stalemate, and Draw by Repetition/50-move rule.
- **Undo/Redo**: Complete history tracking for move traversal.
- **Side Switching**: Ability to flip the board and play as either White or Black.

### 2. High Council (AI)
- **On-Demand Grandmaster**: The High Council AI derives intelligence from the position and reveals it only when asked.
- **Thought Stripping**: Integrated logic ensures the AI's internal thoughts (<think> blocks) are removed before delivery.
- **Witty Personality**: Specifically tuned to deliver short, sharp, and grandmaster-style insights.
- **Sleek Interface**: Refined chat-focused commentary with bubble-style messaging for a premium conversational feel.

### 3. Engine-Grade Analysis & Robot Mode
- **Stockfish ARMv8**: Integrated legendary chess engine for professional-level analysis, optimized for Android devices.
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

## ✨ Chessboard & Piece Animations

### 1. Modular Theme Engine
- **Decoupled Architecture**: Board and piece rendering are fully decoupled via a polymorphic `ChessTheme` system.
- **Theme Registry**: Centralized management for all visual styles (Classic, Slate, Matrix, Walnut, Shadow, etc.).
- **Persistence**: User-selected themes are saved and restored across sessions.

### 2. Advanced Square Animations
- **The "Orbiting Star"**: A High-Precision `CustomPainter` effect that orbits the perimeter of selected, engine-recommended (Gold), and threatened (Red) squares.
- **Smooth Transitions**: `AnimatedContainer` logic for square color shifts and border highlights.
- **Trail Movement**: Smooth linear interpolation for piece transit across the board.

### 3. Piece & Interaction Animations
- **Levitation Effect**: Selected pieces "float" with a synchronized pulsing glow.
- **Elastic Selection Pop**: A spring-loaded scale-up effect when a piece is chosen.
- **Interactive Drag Feedback**: Pieces automatically enlarge while being dragged to ensure visibility.
- **Movement Ghosting**: Opacity "ghosting" applied to pieces while they are in motion.

---

## 🧠 AI & Engine Architecture

### The "Engine" Layer (Stockfish / S-engine)
- **Binary Management**: Managed via `StockfishService` using a native Android library (`libstockfish.so`).
- **Gameplay Authority**: The S-engine is responsible for all board moves, executing strikes immediately upon calculation.
- **UCI Protocol**: Communicates via `stdin/stdout`, translating FEN strings into evaluations and moves.

### The "Brain" Layer (High Council / AI)
- **Engine**: Powered by Sarvam AI / Gemini Cloud via a dedicated Python FastAPI backend.
- **On-Demand Intelligence**: Remains silent by default, only revealing insights when explicitly requested (Hints/Chat).
- **Decoupled Workflow**: Completely separated from the S-engine's move execution to ensure rapid gameplay.

---

## 🛠️ System Wiring

### 1. State Hub (`Riverpod`)
- **`ChessProvider`**: Manages the `chess.dart` engine and core state.
- **`StockfishController`**: Bridges the Flutter state with the native engine process.

### 2. Communication Loop
1.  **User Action**: Piece movement is validated by `ChessProvider`.
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
- [x] Finalize Save/Load persistent storage and Theme persistence.
- [x] Implement time controls and auto-play delay settings.
- [x] **Complete**: Transition Analysis Mode to placeholder for sleeker UX.
