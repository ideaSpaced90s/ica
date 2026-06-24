import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/ambient_scaffold.dart';
import '../scholarly_theme.dart';
import '../../application/study_lab_provider.dart';
import '../../application/chess_provider.dart';
import '../../application/analysis_engine_controller.dart';
import '../../application/practice_lab_provider.dart';
import '../../services/chess_sound_service.dart';
import 'analysis_board.dart';
import 'position_setup_page.dart';
import 'workspace_page.dart';
import 'widgets/game_report_panel.dart';
import 'widgets/practice_mode_panel.dart';
import 'widgets/practice_lab_board.dart';
import 'widgets/sparring_active_view.dart';
import '../mobile_navigation_shell.dart';

enum EnginePlayMode {
  manual,
  autoWhite,
  autoBlack,
  engineVsEngine,
}

class AnalysisPage extends ConsumerStatefulWidget {
  const AnalysisPage({super.key});

  @override
  ConsumerState<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends ConsumerState<AnalysisPage> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late TabController _tabController;
  int _currentTabIndex = 2;
  bool _isAutoPlaying = false;
  Timer? _autoPlayTimer;
  
  // Engine Autoplay state
  EnginePlayMode _enginePlayMode = EnginePlayMode.manual;
  Timer? _autoEngineMoveTimer;
  bool _isEngineThinking = false;
  bool _waitingForImmediateMove = false;
  bool _isAutoMode = false;

  late final PageController _horizontalPageController;
  int _activeHorizontalPage = 1; // Default to Move Notation (page 1)

  @override
  void dispose() {
    _tabController.dispose();
    _horizontalPageController.dispose();
    _autoPlayTimer?.cancel();
    _autoEngineMoveTimer?.cancel();
    ref.read(backButtonOverridesProvider.notifier).update((map) {
      final newMap = Map<int, Future<bool> Function()>.from(map);
      newMap.remove(5);
      return newMap;
    });
    super.dispose();
  }

  Future<bool> _handleBackPress() async {
    final isDirty = ref.read(studyLabProvider).isDirty;
    if (isDirty) {
      final shouldLeave = await _showUnsavedChangesDialog(context);
      return !shouldLeave;
    }
    return false;
  }

  void _startAutoPlay(StudyLabNotifier notifier) {
    _autoPlayTimer?.cancel();
    setState(() => _isAutoPlaying = true);
    _autoPlayTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      final state = ref.read(studyLabProvider);
      if (!state.canRedo) {
        _stopAutoPlay();
        return;
      }
      notifier.redo();
      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    if (mounted) setState(() => _isAutoPlaying = false);
  }

  void _setEnginePlayMode(EnginePlayMode mode, StudyLabState studyState, AnalysisEngineController engineNotifier, {required bool isAuto}) {
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
    setState(() {
      if (_enginePlayMode == mode && _isAutoMode == isAuto) {
        _enginePlayMode = EnginePlayMode.manual;
        _isAutoMode = false;
      } else {
        _enginePlayMode = mode;
        _isAutoMode = isAuto;
        
        final isWhiteToMove = !studyState.activeFen.contains(' b ');
        if ((mode == EnginePlayMode.autoWhite && isWhiteToMove) ||
            (mode == EnginePlayMode.autoBlack && !isWhiteToMove)) {
          _waitingForImmediateMove = true;
        }

        // Ensure engine is on
        final engineState = ref.read(analysisEngineControllerProvider);
        if (!engineState.isEngineOn) {
          engineNotifier.toggleEngine(true, studyState.activeFen);
        }
      }
    });
    _checkAutoEngineMove();
  }

  void _makeEngineMove(StudyLabNotifier studyNotifier, {bool immediate = false}) {
    if (_isEngineThinking) return;

    final engineState = ref.read(analysisEngineControllerProvider);
    if (engineState.isEngineOn && engineState.topLines.isNotEmpty) {
      final firstLine = engineState.topLines.first;
      if (firstLine.moves.isNotEmpty) {
        final uci = firstLine.moves.first;
        if (uci.length >= 4) {
          final from = uci.substring(0, 2);
          final to = uci.substring(2, 4);
          final promotion = uci.length > 4 ? uci.substring(4, 5) : "";

          if (immediate) {
            studyNotifier.makeMove(from, to, promotion);
          } else {
            setState(() {
              _isEngineThinking = true;
            });

            Timer(const Duration(milliseconds: 600), () {
              if (!mounted) return;
              studyNotifier.makeMove(from, to, promotion);
              setState(() {
                _isEngineThinking = false;
              });
            });
          }
        }
      }
    }
  }

  void _checkAutoEngineMove({bool isEngineUpdate = false}) {
    if (isEngineUpdate && _autoEngineMoveTimer?.isActive == true) {
      return;
    }

    final engineState = ref.read(analysisEngineControllerProvider);
    if (!engineState.isEngineOn) return;
    if (_enginePlayMode == EnginePlayMode.manual) return;

    final studyState = ref.read(studyLabProvider);
    final isWhiteToMove = !studyState.activeFen.contains(' b ');

    bool shouldPlay = false;
    if (_enginePlayMode == EnginePlayMode.autoWhite && isWhiteToMove) {
      shouldPlay = _isAutoMode || _waitingForImmediateMove;
    } else if (_enginePlayMode == EnginePlayMode.autoBlack && !isWhiteToMove) {
      shouldPlay = _isAutoMode || _waitingForImmediateMove;
    }

    if (shouldPlay) {
      if (engineState.topLines.isEmpty) {
        return; // Wait for engine lines
      }

      final bool isImmediate = _waitingForImmediateMove;
      _waitingForImmediateMove = false; // Reset the flag

      // If this was a single tap play (not auto), reset mode back to manual immediately
      if (!_isAutoMode) {
        setState(() {
          _enginePlayMode = EnginePlayMode.manual;
        });
      }

      if (!isEngineUpdate || isImmediate) {
        _autoEngineMoveTimer?.cancel();
      }

      final delay = isImmediate ? const Duration(milliseconds: 50) : const Duration(milliseconds: 1200);
      _autoEngineMoveTimer = Timer(delay, () {
        if (!mounted) return;
        final latestEngineState = ref.read(analysisEngineControllerProvider);
        if (latestEngineState.isEngineOn && latestEngineState.topLines.isNotEmpty) {
          _makeEngineMove(ref.read(studyLabProvider.notifier), immediate: isImmediate);
        }
      });
    } else {
      _waitingForImmediateMove = false;
      _autoEngineMoveTimer?.cancel();
    }
  }

  Widget _buildGlowButton({
    required String label,
    required bool isActive,
    Color? activeColor,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    required String tooltip,
  }) {
    final Color buttonColor = activeColor ?? ScholarlyTheme.accentBlue;
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 28,
            decoration: BoxDecoration(
              color: isActive 
                  ? buttonColor.withValues(alpha: 0.15) 
                  : ScholarlyTheme.panelStroke.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isActive 
                    ? buttonColor.withValues(alpha: 0.6) 
                    : ScholarlyTheme.panelStroke.withValues(alpha: 0.15),
                width: isActive ? 1.5 : 1.0,
              ),
              boxShadow: isActive ? [
                BoxShadow(
                  color: buttonColor.withValues(alpha: 0.25),
                  blurRadius: 6,
                  spreadRadius: 1,
                )
              ] : null,
            ),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  color: isActive ? buttonColor : ScholarlyTheme.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _horizontalPageController = PageController(initialPage: 1);
    _tabController = TabController(length: 5, vsync: this, initialIndex: 2);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    Future.microtask(() => ref.read(chessProvider.notifier).loadSavedGames());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(backButtonOverridesProvider.notifier).update((map) => {
          ...map,
          5: _handleBackPress,
        });
      }
    });
  }


  Widget _buildLandscapeLayout(
    BuildContext context,
    StudyLabState state,
    StudyLabNotifier notifier,
    BoxConstraints constraints,
  ) {
    final double paddingHorizontal = 16.0;
    final double boardSize = math.min(
      constraints.maxWidth * 0.55,
      constraints.maxHeight - 110,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 11,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBoardWithEval(context, state, notifier, boardSize),
                const SizedBox(height: 8),
                _buildUnifiedControlPanel(context, state, notifier, boardSize),
              ],
            ),
          ),
          Container(
            width: 1.5,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5),
          ),
          Expanded(
            flex: 9,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.isGuessingMode) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: ScholarlyTheme.accentBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'GUESS THE MOVE TRAINING',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11, color: ScholarlyTheme.accentBlue),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: ScholarlyTheme.accentBlue, borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            '${state.guessedNodes.length} CORRECT',
                            style: GoogleFonts.inter(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                _buildEnginePanel(context),
                if (ref.watch(analysisEngineControllerProvider).isEngineOn)
                  const SizedBox(height: 8),
                Expanded(
                  child: _buildNotationPane(context, state, notifier, isScrollable: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    StudyLabState state,
    StudyLabNotifier notifier,
    BoxConstraints constraints,
  ) {
    final double boardSize = constraints.maxWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.isGuessingMode)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: ScholarlyTheme.accentBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GUESS THE MOVE TRAINING',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11, color: ScholarlyTheme.accentBlue),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: ScholarlyTheme.accentBlue, borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      '${state.guessedNodes.length} CORRECT',
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        _buildBoardWithEval(context, state, notifier, boardSize),

        // VCR controls & action buttons
        Padding(
          padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 8.0, bottom: 2.0),
          child: _buildUnifiedControlPanel(
            context,
            state,
            notifier,
            boardSize,
            isPortrait: true,
          ),
        ),

        // Horizontal page views for engine and moves, taking up the remaining height
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 2.0, 12.0, 12.0),
            child: _buildHorizontalPanels(
              context,
              state,
              notifier,
              boardSize,
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSparringBoardWithEval(
    BuildContext context,
    PracticeLabState practiceState,
    double maxWidth,
  ) {
    final showEval = practiceState.isSessionActive;
    const double evalBarWidth = 6.0;
    const double evalBarPadding = 4.0;
    final double actualBoardSize = showEval
        ? (maxWidth - evalBarWidth - evalBarPadding)
        : maxWidth;

    final isMobile = MediaQuery.of(context).size.width <= 800;

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showEval) ...[
            EvalBar(
              evalScore: practiceState.evalScore,
              isMate: practiceState.isMate,
              mateIn: practiceState.mateIn,
              isEngineOn: true,
              isFlipped: practiceState.isBoardFlipped,
              height: actualBoardSize,
              width: evalBarWidth,
            ),
            const SizedBox(width: evalBarPadding),
          ],
          Stack(
            alignment: Alignment.center,
            children: [
              PracticeLabBoard(
                boardSize: actualBoardSize,
              ),
              if (practiceState.isGameOver && practiceState.gameConclusion != null)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              practiceState.gameConclusion!,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSparringUnifiedControlPanel(
    BuildContext context,
    PracticeLabState practiceState,
    double boardSize, {
    bool isPortrait = false,
  }) {
    final panelWidth = isPortrait ? boardSize - 24 : boardSize;
    final practiceNotifier = ref.read(practiceLabProvider.notifier);

    final canStepBack = practiceState.isSessionActive &&
        practiceState.moveHistory.isNotEmpty &&
        (practiceState.viewingMoveIndex == null || practiceState.viewingMoveIndex! > -1);
    
    final canStepForward = practiceState.isSessionActive &&
        practiceState.viewingMoveIndex != null;

    final canGoToStart = practiceState.isSessionActive &&
        practiceState.moveHistory.isNotEmpty &&
        practiceState.viewingMoveIndex != -1;

    final canGoToEnd = practiceState.isSessionActive &&
        practiceState.viewingMoveIndex != null;

    final canUndo = practiceState.isSessionActive &&
        practiceState.moveHistory.length >= 2 &&
        !practiceState.isEngineThinking &&
        practiceState.viewingMoveIndex == null;

    return SizedBox(
      width: panelWidth,
      child: JuicyGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        borderRadius: 12,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Go to Start
              _CompactBoxButton(
                tooltip: 'Go to Start',
                activeColor: const Color(0xFF29B6F6),
                onTap: canGoToStart
                    ? () {
                        practiceNotifier.navigateToMove(-1);
                        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
                      }
                    : null,
                child: const Icon(Icons.first_page_rounded),
              ),
              const SizedBox(width: 8),
              // Step Backward
              _CompactBoxButton(
                tooltip: 'Step Backward',
                activeColor: const Color(0xFF29B6F6),
                onTap: canStepBack
                    ? () {
                        practiceNotifier.stepBackward();
                        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
                      }
                    : null,
                child: const Icon(Icons.chevron_left_rounded),
              ),
              const SizedBox(width: 8),
              // Step Forward
              _CompactBoxButton(
                tooltip: 'Step Forward',
                activeColor: const Color(0xFF29B6F6),
                onTap: canStepForward
                    ? () {
                        practiceNotifier.stepForward();
                        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
                      }
                    : null,
                child: const Icon(Icons.chevron_right_rounded),
              ),
              const SizedBox(width: 8),
              // Go to End (Live Game)
              _CompactBoxButton(
                tooltip: 'Go to End',
                activeColor: const Color(0xFF29B6F6),
                onTap: canGoToEnd
                    ? () {
                        practiceNotifier.navigateToMove(null);
                        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
                      }
                    : null,
                child: const Icon(Icons.last_page_rounded),
              ),
              const SizedBox(width: 8),
              // Undo Move (Back Button)
              _CompactBoxButton(
                tooltip: 'Undo Move',
                activeColor: const Color(0xFF29B6F6),
                onTap: canUndo
                    ? () {
                        practiceNotifier.undo();
                      }
                    : null,
                child: const Icon(Icons.undo_rounded),
              ),
              const SizedBox(width: 8),
              // Stop Sparring
              _CompactBoxButton(
                tooltip: 'Stop Sparring',
                activeColor: Colors.redAccent,
                onTap: practiceState.isSessionActive
                    ? () {
                        final studyState = ref.read(studyLabProvider);
                        practiceNotifier.endSession(studyState.activeFen);
                      }
                    : null,
                child: const Icon(Icons.stop_circle_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitSparringLayout(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final double boardSize = constraints.maxWidth;
    final practiceState = ref.watch(practiceLabProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSparringBoardWithEval(context, practiceState, boardSize),
        Padding(
          padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 8.0, bottom: 2.0),
          child: _buildSparringUnifiedControlPanel(
            context,
            practiceState,
            boardSize,
            isPortrait: true,
          ),
        ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(12.0, 2.0, 12.0, 12.0),
            child: PracticeModePanel(),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeSparringLayout(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final double paddingHorizontal = 16.0;
    final double boardSize = math.min(
      constraints.maxWidth * 0.55,
      constraints.maxHeight - 110,
    );
    final practiceState = ref.watch(practiceLabProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 11,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSparringBoardWithEval(context, practiceState, boardSize),
                const SizedBox(height: 8),
                _buildSparringUnifiedControlPanel(
                  context,
                  practiceState,
                  boardSize,
                ),
              ],
            ),
          ),
          Container(
            width: 1.5,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5),
          ),
          const Expanded(
            flex: 9,
            child: PracticeModePanel(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studyLabProvider);
    final notifier = ref.read(studyLabProvider.notifier);
    final practiceState = ref.watch(practiceLabProvider);

    // Listen to FEN changes to restart the engine
    ref.listen<String>(studyLabProvider.select((s) => s.activeFen), (previous, next) {
      ref.read(analysisEngineControllerProvider.notifier).setFen(next);
      _checkAutoEngineMove();
    });

    // Listen to engine updates for autoplay scheduler
    ref.listen(analysisEngineControllerProvider, (previous, next) {
      if (next.isEngineOn) {
        _checkAutoEngineMove(isEngineUpdate: true);
      }
    });

    Widget activeTabBody;
    switch (_currentTabIndex) {
      case 0:
        activeTabBody = GameLibraryTab(
          onGameLoaded: () {
            _tabController.animateTo(2);
            setState(() {
              _currentTabIndex = 2;
            });
          },
        );
        break;
      case 1:
        activeTabBody = BoardEditorTab(
          onApply: () {
            _tabController.animateTo(2);
            setState(() {
              _currentTabIndex = 2;
            });
          },
        );
        break;
      case 2:
        activeTabBody = LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            if (isLandscape) {
              return _buildLandscapeLayout(context, state, notifier, constraints);
            }
            return _buildPortraitLayout(context, state, notifier, constraints);
          },
        );
        break;
      case 3:
        activeTabBody = LayoutBuilder(
          builder: (context, constraints) {
            if (practiceState.isSessionActive) {
              // ── ACTIVE GAME: dedicated sparring board + headers + move list ──
              return SparringActiveView(constraints: constraints);
            }
            // ── LOBBY: side-selector + settings + start button + preview board ──
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            if (isLandscape) {
              return _buildLandscapeSparringLayout(context, constraints);
            }
            return _buildPortraitSparringLayout(context, constraints);
          },
        );
        break;
      case 4:
        activeTabBody = const GameReportPanel();
        break;
      default:
        activeTabBody = const SizedBox.shrink();
    }

    return AmbientScaffold(
      scaffoldKey: _scaffoldKey,
      blob1Color: const Color(0xFFF3E8FF),
      blob2Color: const Color(0xFFDBEAFE),
      blob3Color: const Color(0xFFFEF3C7),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: ScholarlyTheme.panelBase,
          border: Border(top: BorderSide(color: ScholarlyTheme.panelStroke.withValues(alpha: 0.15))),
        ),
        child: SafeArea(
          child: TabBar(
            controller: _tabController,
            labelColor: ScholarlyTheme.accentBlue,
            unselectedLabelColor: ScholarlyTheme.textMuted,
            indicatorColor: Colors.transparent, // Hide default line indicator for bottom nav style
            labelPadding: EdgeInsets.zero,
            onTap: (idx) {
              ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
            },
            tabs: const [
              Tab(icon: Icon(Icons.folder_copy_rounded, size: 20), text: 'Library'),
              Tab(icon: Icon(Icons.design_services_rounded, size: 20), text: 'Editor'),
              Tab(icon: Icon(Icons.grid_on_rounded, size: 20), text: 'Board'),
              Tab(icon: Icon(Icons.sports_esports_rounded, size: 20), text: 'Sparring'),
              Tab(icon: Icon(Icons.analytics_rounded, size: 20), text: 'Report'),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: activeTabBody,
      ),
    );
  }

  Widget _buildBoardWithEval(
    BuildContext context,
    StudyLabState state,
    StudyLabNotifier notifier,
    double maxWidth,
  ) {
    final engineState = ref.watch(analysisEngineControllerProvider);
    final bestLine = engineState.topLines.firstOrNull;

    const double evalBarWidth = 6.0;
    const double evalBarPadding = 4.0;
    final double actualBoardSize = maxWidth - evalBarWidth - evalBarPadding;

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EvalBar(
            evalScore: bestLine?.eval,
            isMate: bestLine?.isMate ?? false,
            mateIn: bestLine?.mateIn,
            isEngineOn: engineState.isEngineOn,
            isFlipped: state.isBoardFlipped,
            height: actualBoardSize,
            width: evalBarWidth,
          ),
          const SizedBox(width: evalBarPadding),
          StudyLabChessBoard(
            state: state,
            notifier: notifier,
            boardSize: actualBoardSize,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSelectorIcon(int index, IconData icon, String tooltip) {
    final isSelected = _activeHorizontalPage == index;
    final activeColor = ScholarlyTheme.accentBlue;
    final inactiveColor = ScholarlyTheme.textMuted.withValues(alpha: 0.5);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          _horizontalPageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? activeColor.withValues(alpha: 0.2) : Colors.transparent,
            ),
          ),
          child: Icon(
            icon,
            color: isSelected ? activeColor : inactiveColor,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalPanels(
    BuildContext context,
    StudyLabState state,
    StudyLabNotifier notifier,
    double boardSize, {
    bool isExpanded = false,
  }) {
    final engineState = ref.watch(analysisEngineControllerProvider);
    final isEngineOn = engineState.isEngineOn;

    return JuicyGlassCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      borderRadius: 16,
      child: SizedBox(
        height: isExpanded ? null : 170, // Fixed height or auto height depending on context
        child: Row(
          children: [
            // Left side: PageView content
            Expanded(
              child: PageView(
                controller: _horizontalPageController,
                onPageChanged: (index) {
                  setState(() {
                    _activeHorizontalPage = index;
                  });
                },
                children: [
                  // Page 0: Engine Analysis
                  isEngineOn
                      ? _buildEnginePanel(context, hasCard: false)
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bolt,
                                size: 28,
                                color: ScholarlyTheme.textMuted.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Engine is Off',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: ScholarlyTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Enable analysis under the board.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: ScholarlyTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),

                  // Page 1: Move Notation
                  _buildNotationPane(context, state, notifier, isScrollable: true, hasCard: false),
                ],
              ),
            ),
            // Right side: Vertical Stack of Icon switchers
            Container(
              width: 1.5,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              color: ScholarlyTheme.panelStroke.withValues(alpha: 0.3),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCompactSelectorIcon(0, Icons.bolt, 'Engine Analysis'),
                  const SizedBox(height: 10),
                  _buildCompactSelectorIcon(1, Icons.list_alt_rounded, 'Move Notation'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _convertUciListToSan(String startFen, List<String> uciMoves, int limit) {
    try {
      final chess = chess_lib.Chess.fromFEN(startFen);
      final List<String> sanMoves = [];
      for (final uci in uciMoves.take(limit)) {
        if (uci.length < 4) break;
        final from = uci.substring(0, 2);
        final to = uci.substring(2, 4);
        final promotion = uci.length > 4 ? uci[4] : null;

        final moves = chess.generate_moves();
        chess_lib.Move? matchedMove;
        for (final m in moves) {
          final mFrom = chess_lib.Chess.algebraic(m.from);
          final mTo = chess_lib.Chess.algebraic(m.to);
          final mPromo = m.promotion?.name;
          if (mFrom == from && mTo == to && (promotion == null || mPromo == promotion)) {
            matchedMove = m;
            break;
          }
        }

        if (matchedMove != null) {
          final san = chess.move_to_san(matchedMove);
          chess.make_move(matchedMove);
          sanMoves.add(san);
        } else {
          break;
        }
      }
      if (sanMoves.isEmpty) return uciMoves.take(limit).join(' ');
      return sanMoves.join(' ');
    } catch (e) {
      debugPrint("Error converting UCI moves to SAN: $e");
      return uciMoves.take(limit).join(' ');
    }
  }

  Widget _buildEnginePanel(BuildContext context, {bool hasCard = true}) {
    final engineState = ref.watch(analysisEngineControllerProvider);
    if (!engineState.isEngineOn) return const SizedBox.shrink();

    final studyState = ref.watch(studyLabProvider);
    final engineNotifier = ref.read(analysisEngineControllerProvider.notifier);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt, size: 14, color: Colors.orangeAccent),
                const SizedBox(width: 4),
                Text(
                  'ENGINE - Depth ${engineState.currentDepth}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: ScholarlyTheme.textMuted,
                  ),
                ),
              ],
            ),
            if (engineState.isAnalyzing)
              const SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.orangeAccent),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildGlowButton(
              label: 'White',
              isActive: _enginePlayMode == EnginePlayMode.autoWhite && engineState.isEngineOn,
              activeColor: _isAutoMode ? Colors.green : ScholarlyTheme.accentBlue,
              onTap: () => _setEnginePlayMode(EnginePlayMode.autoWhite, studyState, engineNotifier, isAuto: false),
              onLongPress: () => _setEnginePlayMode(EnginePlayMode.autoWhite, studyState, engineNotifier, isAuto: true),
              tooltip: 'White plays (Tap to play one move, Long-press for auto-play)',
            ),
            const SizedBox(width: 5),
            _buildGlowButton(
              label: 'Black',
              isActive: _enginePlayMode == EnginePlayMode.autoBlack && engineState.isEngineOn,
              activeColor: _isAutoMode ? Colors.green : ScholarlyTheme.accentBlue,
              onTap: () => _setEnginePlayMode(EnginePlayMode.autoBlack, studyState, engineNotifier, isAuto: false),
              onLongPress: () => _setEnginePlayMode(EnginePlayMode.autoBlack, studyState, engineNotifier, isAuto: true),
              tooltip: 'Black plays (Tap to play one move, Long-press for auto-play)',
            ),
            const SizedBox(width: 5),
            _buildGlowButton(
              label: 'Self',
              isActive: _enginePlayMode == EnginePlayMode.manual && engineState.isEngineOn,
              onTap: () => _setEnginePlayMode(EnginePlayMode.manual, studyState, engineNotifier, isAuto: false),
              tooltip: 'Manual analysis mode (turn engine auto-play off)',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (engineState.topLines.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Calculating...',
                      style: GoogleFonts.inter(fontSize: 11, fontStyle: FontStyle.italic, color: ScholarlyTheme.textMuted),
                    ),
                  )
                else
                  ...engineState.topLines.map((line) {
                    final evalText = line.isMate && line.mateIn != null
                        ? 'M${line.mateIn}'
                        : '${line.eval > 0 ? "+" : ""}${line.eval.toStringAsFixed(2)}';

                    final state = ref.read(studyLabProvider);
                    final movesText = _convertUciListToSan(state.activeFen, line.moves, 4);

                    return GestureDetector(
                      onTap: () {
                        if (line.moves.isNotEmpty) {
                          final firstMove = line.moves.first;
                          if (firstMove.length >= 4) {
                            final from = firstMove.substring(0, 2);
                            final to = firstMove.substring(2, 4);
                            final promo = firstMove.length > 4 ? firstMove[4] : '';
                            ref.read(studyLabProvider.notifier).makeMove(from, to, promo);
                          }
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              alignment: Alignment.center,
                              child: Text(
                                '#${line.pvIndex}',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: ScholarlyTheme.textMuted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                movesText,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 13,
                                  color: ScholarlyTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              evalText,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: line.eval >= 0 ? Colors.green : Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );

    if (!hasCard) return Padding(padding: const EdgeInsets.symmetric(horizontal: 6.0), child: content);
    return JuicyGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: 16,
      child: content,
    );
  }

  Widget _buildSaveStudyButton(BuildContext context, StudyLabState state, StudyLabNotifier notifier) {
    final isDirty = state.isDirty && state.nodes.isNotEmpty;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _CompactBoxButton(
          tooltip: isDirty ? 'Save Study (Unsaved Changes)' : 'Save Study',
          activeColor: const Color(0xFF00E676),
          isActive: isDirty,
          onTap: isDirty
              ? () async {
                  ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                  if (state.libraryIndex != null) {
                    final success = await notifier.saveExistingStudyInLibrary(state.libraryIndex!);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success ? 'Study saved successfully!' : 'Failed to save study.',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: success ? const Color(0xFF00E676) : Colors.redAccent,
                        ),
                      );
                    }
                  } else {
                    _showSaveStudyDialog(context, notifier, state);
                  }
                }
              : null,
          child: const Icon(Icons.save_rounded),
        ),
        if (isDirty)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFFF6B35),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUnifiedControlPanel(
    BuildContext context,
    StudyLabState state,
    StudyLabNotifier notifier,
    double boardSize, {
    bool isPortrait = false,
  }) {
    final activeIndex = state.currentNodeIndex;
    final bool hasActiveNode = activeIndex != null && activeIndex < state.nodes.length;
    final activeNode = hasActiveNode ? state.nodes[activeIndex] : null;

    final double panelWidth = isPortrait ? boardSize - 24 : boardSize;

    return SizedBox(
      width: panelWidth,
      child: JuicyGlassCard(

        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        borderRadius: 12,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: VCR Navigation Controls
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FlashingEngineButton(
                    isEngineOn: ref.watch(analysisEngineControllerProvider).isEngineOn,
                    size: 24,
                    onTap: () {
                      final engineState = ref.read(analysisEngineControllerProvider);
                      ref.read(analysisEngineControllerProvider.notifier).toggleEngine(!engineState.isEngineOn, state.activeFen);
                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiToggle);
                    },
                  ),
                  Container(width: 1.5, height: 24, color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5)),
                  _CompactBoxButton(
                    tooltip: 'Go to Start',
                    activeColor: const Color(0xFF29B6F6), // Vibrant Cyan/Blue
                    onTap: state.currentNodeIndex != null
                        ? () {
                            _stopAutoPlay();
                            notifier.selectNode(null);
                            ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
                          }
                        : null,
                    child: const Icon(Icons.first_page_rounded),
                  ),
                  _CompactBoxButton(
                    tooltip: 'Undo Move',
                    activeColor: const Color(0xFF69F0AE), // Vibrant Green
                    onTap: state.canUndo
                        ? () {
                            _stopAutoPlay();
                            notifier.undo();
                            ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
                          }
                        : null,
                    child: const Icon(Icons.chevron_left_rounded),
                  ),
                  _CompactBoxButton(
                    tooltip: 'Redo Move',
                    activeColor: const Color(0xFF69F0AE), // Vibrant Green
                    onTap: state.canRedo
                        ? () {
                            _stopAutoPlay();
                            notifier.redo();
                            ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
                          }
                        : null,
                    child: const Icon(Icons.chevron_right_rounded),
                  ),
                  _CompactBoxButton(
                    tooltip: 'Go to End',
                    activeColor: const Color(0xFF29B6F6), // Vibrant Cyan/Blue
                    onTap: state.canRedo
                        ? () {
                            _stopAutoPlay();
                            int? current = state.currentNodeIndex;
                            while (true) {
                              final children = current == null
                                  ? state.nodes.where((n) => n.parentIndex == null).toList()
                                  : state.nodes[current].childIndices.map((idx) => state.nodes[idx]).toList();
                              if (children.isEmpty) break;
                              current = children.first.index;
                            }
                            notifier.selectNode(current);
                            ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
                          }
                        : null,
                    child: const Icon(Icons.last_page_rounded),
                  ),
                  Container(width: 1.5, height: 24, color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5)),
                  _CompactBoxButton(
                    tooltip: 'Flip Board',
                    activeColor: const Color(0xFFD500F9), // Vibrant Purple
                    isActive: state.isBoardFlipped,
                    onTap: () {
                      notifier.flipBoard();
                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
                    },
                    child: const Icon(Icons.flip_camera_android_rounded),
                  ),
                  _CompactBoxButton(
                    tooltip: 'Reset Position',
                    activeColor: const Color(0xFFFF5252), // Vibrant Red
                    onTap: state.nodes.isNotEmpty
                        ? () {
                            _showResetConfirmation(context, notifier);
                          }
                        : null,
                    child: const Icon(Icons.refresh_rounded),
                  ),
                  Container(width: 1.5, height: 24, color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5)),
                  _CompactBoxButton(
                    tooltip: _isAutoPlaying ? 'Pause' : 'Play Through',
                    activeColor: const Color(0xFF69F0AE), // Green
                    isActive: _isAutoPlaying,
                    onTap: state.nodes.isNotEmpty
                        ? () {
                            if (_isAutoPlaying) {
                              _stopAutoPlay();
                            } else {
                              _startAutoPlay(notifier);
                            }
                            ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiToggle);
                          }
                        : null,
                    child: Icon(_isAutoPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  ),
                  _CompactBoxButton(
                    tooltip: 'Stop',
                    activeColor: const Color(0xFFFF5252),
                    onTap: (_isAutoPlaying || state.currentNodeIndex != null)
                        ? () {
                            _stopAutoPlay();
                            notifier.selectNode(null);
                            ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
                          }
                        : null,
                    child: const Icon(Icons.stop_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Divider
            Container(height: 1, color: ScholarlyTheme.panelStroke.withValues(alpha: 0.3)),
            const SizedBox(height: 6),
            // Row 2: Annotations Toolbar
            Opacity(
              opacity: hasActiveNode ? 1.0 : 0.4,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ...MoveAnnotation.values.where((a) => a != MoveAnnotation.none).map((ann) {
                      final isApplied = activeNode?.annotation == ann;
                      final color = _getChipColor(ann);

                      return _CompactBoxButton(
                        tooltip: ann.name.toUpperCase(),
                        activeColor: color,
                        isActive: isApplied,
                        onTap: hasActiveNode
                            ? () {
                                notifier.setAnnotation(
                                  activeNode!.index,
                                  isApplied ? MoveAnnotation.none : ann,
                                );
                              }
                            : null,
                        child: Text(_getGlyph(ann)),
                      );
                    }),
                    Container(width: 1.5, height: 24, color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5)),
                    _CompactBoxButton(
                      tooltip: 'Add move comment',
                      activeColor: ScholarlyTheme.accentBlue,
                      isActive: activeNode?.comment.isNotEmpty == true,
                      onTap: hasActiveNode ? () => _showCommentDialog(context, activeNode!, notifier) : null,
                      child: Icon(
                        activeNode?.comment.isNotEmpty == true ? Icons.comment : Icons.comment_outlined,
                      ),
                    ),
                    Container(width: 1.5, height: 24, color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5)),
                    _buildSaveStudyButton(context, state, notifier),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getChipColor(MoveAnnotation a) {
    switch (a) {
      case MoveAnnotation.brilliant:
        return const Color(0xFF00BCD4);
      case MoveAnnotation.good:
        return const Color(0xFF00C853);
      case MoveAnnotation.interesting:
        return const Color(0xFF9C27B0);
      case MoveAnnotation.dubious:
        return const Color(0xFFFF6F00);
      case MoveAnnotation.mistake:
        return const Color(0xFFE53935);
      case MoveAnnotation.blunder:
        return const Color(0xFFD50000);
      case MoveAnnotation.none:
        return Colors.grey;
    }
  }

  String _getGlyph(MoveAnnotation a) {
    switch (a) {
      case MoveAnnotation.brilliant: return '!!';
      case MoveAnnotation.good: return '!';
      case MoveAnnotation.interesting: return '!?';
      case MoveAnnotation.dubious: return '?!';
      case MoveAnnotation.mistake: return '?';
      case MoveAnnotation.blunder: return '??';
      case MoveAnnotation.none: return '';
    }
  }

  void _showCommentDialog(BuildContext context, StudyLabMoveNode node, StudyLabNotifier notifier) {
    final controller = TextEditingController(text: node.comment);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ScholarlyTheme.panelBase,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: ScholarlyTheme.panelStroke, width: 1.5),
          ),
          title: Text(
            'Edit Move Comment',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: ScholarlyTheme.textPrimary,
            ),
          ),
          content: TextField(
            controller: controller,
            maxLines: 4,
            style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter your thoughts or positional analysis...',
              hintStyle: GoogleFonts.inter(color: ScholarlyTheme.textMuted),
              filled: true,
              fillColor: ScholarlyTheme.panelBase,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: ScholarlyTheme.panelStroke),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: ScholarlyTheme.accentBlue),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: ScholarlyTheme.textMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ScholarlyTheme.accentBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                notifier.updateCommentAt(node.index, controller.text);
                Navigator.pop(context);
              },
              child: Text(
                'Save',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showResetConfirmation(BuildContext context, StudyLabNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ScholarlyTheme.panelBase,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reset Analysis Board?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary),
        ),
        content: Text(
          'This will clear all moves, custom variations, and move annotations. Do you want to continue?',
          style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted)),
          ),
          FilledButton(
            onPressed: () {
              notifier.clearBoard();
              Navigator.pop(context);
              ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiToggle);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('Clear Everything', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }



  void _showSaveStudyDialog(BuildContext context, StudyLabNotifier notifier, StudyLabState state) {
    final defaultName = (state.metadata.event.isNotEmpty &&
            state.metadata.event != 'Study Lab Analysis')
        ? state.metadata.event
        : '';
    final controller = TextEditingController(text: defaultName);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: ScholarlyTheme.panelBase,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: ScholarlyTheme.panelStroke, width: 1.5),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.save_rounded, color: Color(0xFF00E676), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Save to Game Library',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: ScholarlyTheme.textPrimary,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Give your progress a title to save it in the game library.',
                style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. Ruy Lopez Study, Endgame Practice...',
                  hintStyle: GoogleFonts.inter(color: ScholarlyTheme.textMuted),
                  filled: true,
                  fillColor: ScholarlyTheme.panelBase,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ScholarlyTheme.panelStroke),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00E676), width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_rounded, size: 16, color: Colors.white),
              label: Text('Save', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                final success = await notifier.saveCurrentGameToLibrary(name);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? 'Study "$name" saved successfully!' : 'Failed to save study. Please try again.',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: success ? const Color(0xFF00E676) : Colors.redAccent,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// Shows the unsaved changes dialog. Returns true if the user chose to leave
  /// (either by saving or discarding), false if they want to stay.
  Future<bool> _showUnsavedChangesDialog(BuildContext context) async {
    final notifier = ref.read(studyLabProvider.notifier);
    final state = ref.read(studyLabProvider);
    bool shouldLeave = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: ScholarlyTheme.panelBase,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.orangeAccent.withValues(alpha: 0.6), width: 1.5),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Unsaved Changes',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: ScholarlyTheme.textPrimary,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Your study has unsaved changes. Would you like to save before leaving?',
            style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                shouldLeave = false;
                Navigator.pop(ctx);
              },
              child: Text('Cancel', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted)),
            ),
            TextButton(
              onPressed: () {
                notifier.clearDirty();
                shouldLeave = true;
                Navigator.pop(ctx);
              },
              child: Text(
                'Discard',
                style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_rounded, size: 15, color: Colors.white),
              label: Text('Save & Leave', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                if (state.libraryIndex != null) {
                  final success = await notifier.saveExistingStudyInLibrary(state.libraryIndex!);
                  if (success) {
                    shouldLeave = true;
                    if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  }
                } else {
                  _showSaveAndLeaveDialog(context, notifier, state, onSaved: () {
                    shouldLeave = true;
                    if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  });
                }
              },
            ),
          ],
        );
      },
    );

    return shouldLeave;
  }

  void _showSaveAndLeaveDialog(
    BuildContext context,
    StudyLabNotifier notifier,
    StudyLabState state, {
    required VoidCallback onSaved,
  }) {
    final defaultName = (state.metadata.event.isNotEmpty &&
            state.metadata.event != 'Study Lab Analysis')
        ? state.metadata.event
        : '';
    final controller = TextEditingController(text: defaultName);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: ScholarlyTheme.panelBase,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: ScholarlyTheme.panelStroke, width: 1.5),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.save_rounded, color: Color(0xFF00E676), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Save to Game Library',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: ScholarlyTheme.textPrimary,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Give your progress a title to save it in the game library.',
                style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. Ruy Lopez Study, Endgame Practice...',
                  hintStyle: GoogleFonts.inter(color: ScholarlyTheme.textMuted),
                  filled: true,
                  fillColor: ScholarlyTheme.panelBase,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ScholarlyTheme.panelStroke),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00E676), width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: Text('Cancel', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_rounded, size: 16, color: Colors.white),
              label: Text('Save', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                final success = await notifier.saveCurrentGameToLibrary(name);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? 'Study "$name" saved!' : 'Save failed. Please try again.',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: success ? const Color(0xFF00E676) : Colors.redAccent,
                    ),
                  );
                }
                if (success) onSaved();
              },
            ),
          ],
        );
      },
    );
  }

  // Workspace pages refactored to workspace_page.dart

  Widget _buildNotationPane(
    BuildContext context,
    StudyLabState state,
    StudyLabNotifier notifier, {
    bool isScrollable = false,
    bool hasCard = true,
  }) {
    final List<Widget> moveChips = [];
    _buildMoveTreeChips(state, notifier, null, moveChips, 0);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: isScrollable ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (state.commentary != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: ScholarlyTheme.accentBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              state.commentary!,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: ScholarlyTheme.accentBlue,
              ),
            ),
          ),
        ],
        if (isScrollable)
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: moveChips.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.center,
                      child: Text(
                        'No moves played yet. Play some moves on the board!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: ScholarlyTheme.textMuted,
                        ),
                      ),
                    )
                  : Wrap(
                      spacing: 6.0,
                      runSpacing: 8.0,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: moveChips,
                    ),
            ),
          )
        else
          moveChips.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  child: Text(
                    'No moves played yet. Play some moves on the board!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: ScholarlyTheme.textMuted,
                    ),
                  ),
                )
              : Wrap(
                  spacing: 6.0,
                  runSpacing: 8.0,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: moveChips,
                ),
      ],
    );

    if (!hasCard) return Padding(padding: const EdgeInsets.symmetric(horizontal: 6.0), child: content);
    return JuicyGlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 16,
      child: content,
    );
  }

  void _buildMoveTreeChips(
    StudyLabState state,
    StudyLabNotifier notifier,
    int? parentIdx,
    List<Widget> chips,
    int depth,
  ) {
    final children = state.nodes.where((n) => n.parentIndex == parentIdx).toList();
    if (children.isEmpty) return;

    final mainNode = children.first;
    final moveNumber = _getMoveNumberFromFen(mainNode.fen);
    final isWhite = !mainNode.fen.contains(' b ');

    if (isWhite) {
      chips.add(Text(' $moveNumber.', style: GoogleFonts.jetBrainsMono(color: ScholarlyTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)));
    } else if (parentIdx == null) {
      chips.add(Text(' ${math.max(1, moveNumber - 1)}...', style: GoogleFonts.jetBrainsMono(color: ScholarlyTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)));
    }

    final isCurrent = state.currentNodeIndex == mainNode.index;

    chips.add(
      GestureDetector(
        onTap: () {
          notifier.selectNode(mainNode.index);
          ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
        },
        onLongPress: () {
          _showMoveChipContextMenu(context, mainNode, notifier);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isCurrent ? ScholarlyTheme.accentBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isCurrent ? ScholarlyTheme.accentBlue : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (mainNode.annotation != MoveAnnotation.none) ...[
                _buildMoveListAnnotationPrefix(mainNode.annotation, isCurrent),
                const SizedBox(width: 4),
              ],
              Text(
                mainNode.san,
                style: GoogleFonts.inter(
                  color: isCurrent ? Colors.white : ScholarlyTheme.textPrimary,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    for (int i = 1; i < children.length; i++) {
      final sideNode = children[i];
      chips.add(Text(' (', style: GoogleFonts.inter(color: ScholarlyTheme.textSubtle, fontSize: 11)));

      final isSideCurrent = state.currentNodeIndex == sideNode.index;

      chips.add(
        GestureDetector(
          onTap: () {
            notifier.selectNode(sideNode.index);
            ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
          },
          onLongPress: () {
            _showMoveChipContextMenu(context, sideNode, notifier);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSideCurrent ? ScholarlyTheme.accentBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSideCurrent ? ScholarlyTheme.accentBlue : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sideNode.annotation != MoveAnnotation.none) ...[
                  _buildMoveListAnnotationPrefix(sideNode.annotation, isSideCurrent),
                  const SizedBox(width: 4),
                ],
                Text(
                  sideNode.san,
                  style: GoogleFonts.inter(
                    color: isSideCurrent ? Colors.white : ScholarlyTheme.textPrimary,
                    fontWeight: isSideCurrent ? FontWeight.bold : FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      _buildMoveTreeChips(state, notifier, sideNode.index, chips, depth + 1);
      chips.add(Text(')', style: GoogleFonts.inter(color: ScholarlyTheme.textSubtle, fontSize: 11)));
    }

    _buildMoveTreeChips(state, notifier, mainNode.index, chips, depth);
  }

  Widget _buildMoveListAnnotationPrefix(MoveAnnotation a, bool isCurrentNode) {
    final color = a.color;
    final glyph = a.glyph;

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: isCurrentNode ? Colors.white : color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        glyph,
        style: GoogleFonts.outfit(
          fontSize: glyph.length > 1 ? 6.5 : 8.5,
          fontWeight: FontWeight.w900,
          color: isCurrentNode ? color : Colors.white,
          height: 1.0,
        ),
      ),
    );
  }

  int _getMoveNumberFromFen(String fen) {
    final parts = fen.split(' ');
    if (parts.length >= 6) {
      return int.tryParse(parts[5]) ?? 1;
    }
    return 1;
  }

  void _showMoveChipContextMenu(BuildContext context, StudyLabMoveNode node, StudyLabNotifier notifier) {
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
    showModalBottomSheet(
      context: context,
      backgroundColor: ScholarlyTheme.panelBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        final hasSelectedNode = ref.read(studyLabProvider).currentNodeIndex != null;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Options for ${node.san}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: ScholarlyTheme.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ),
              const Divider(color: ScholarlyTheme.panelStroke),
              ListTile(
                leading: const Icon(Icons.star_border_rounded, color: ScholarlyTheme.accentBlue),
                title: Text('Promote to Mainline', style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary)),
                onTap: () {
                  notifier.promoteVariation(node.index);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: Text('Delete Variation', style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary)),
                onTap: () {
                  notifier.deleteCurrentNode();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.comment_outlined, color: hasSelectedNode ? Colors.teal : Colors.teal.withValues(alpha: 0.4)),
                title: Text('Edit Comment', style: GoogleFonts.inter(color: hasSelectedNode ? ScholarlyTheme.textPrimary : ScholarlyTheme.textMuted)),
                onTap: hasSelectedNode ? () {
                  Navigator.pop(context);
                  _showCommentEditDialog(context, node, notifier);
                } : null,
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showCommentEditDialog(BuildContext context, StudyLabMoveNode node, StudyLabNotifier notifier) {
    final controller = TextEditingController(text: node.comment);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ScholarlyTheme.panelBase,
          title: Text('Edit comment for ${node.san}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Type comment...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                notifier.updateCommentAt(node.index, controller.text);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

}

class _CompactBoxButton extends StatefulWidget {
  final Widget child;
  final String tooltip;
  final VoidCallback? onTap;
  final bool isActive;
  final Color activeColor;

  const _CompactBoxButton({
    required this.child,
    required this.tooltip,
    this.onTap,
    this.isActive = false,
    required this.activeColor,
  });

  @override
  State<_CompactBoxButton> createState() => _CompactBoxButtonState();
}

class _CompactBoxButtonState extends State<_CompactBoxButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onTap != null;

    final baseColor = widget.activeColor;
    final hsl = HSLColor.fromColor(baseColor);
    final darker = hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0)).toColor();

    // Box border color
    final Color borderClr = isEnabled
        ? baseColor.withValues(alpha: widget.isActive ? 0.6 : 0.35)
        : ScholarlyTheme.panelStroke.withValues(alpha: 0.15);

    // Dynamic child text/icon color
    final Color childColor = isEnabled
        ? Colors.black
        : ScholarlyTheme.textMuted.withValues(alpha: 0.35);

    final content = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: isEnabled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  baseColor.withValues(alpha: widget.isActive ? 0.40 : 0.25),
                  darker.withValues(alpha: widget.isActive ? 0.30 : 0.15),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.03),
                ],
              ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderClr,
          width: widget.isActive ? 1.5 : 1.0,
        ),
        boxShadow: [
          if (isEnabled)
            BoxShadow(
              color: baseColor.withValues(alpha: widget.isActive ? 0.25 : 0.12),
              blurRadius: widget.isActive ? 10 : 5,
              spreadRadius: widget.isActive ? 1.5 : 0.5,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            if (isEnabled)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.25),
                        Colors.white.withValues(alpha: 0.08),
                        Colors.transparent,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.25, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            Center(
              child: IconTheme(
                data: IconThemeData(
                  size: 22,
                  color: childColor,
                ),
                child: DefaultTextStyle(
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: childColor,
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Tooltip(
      message: widget.tooltip,
      decoration: BoxDecoration(
        color: ScholarlyTheme.backgroundDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => _controller.forward() : null,
        onTapUp: isEnabled ? (_) => _controller.reverse() : null,
        onTapCancel: isEnabled ? () => _controller.reverse() : null,
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: content,
        ),
      ),
    );
  }
}

class FlashingEngineButton extends StatefulWidget {
  final bool isEngineOn;
  final VoidCallback onTap;
  final double size;

  const FlashingEngineButton({
    super.key,
    required this.isEngineOn,
    required this.onTap,
    this.size = 34.0,
  });

  @override
  State<FlashingEngineButton> createState() => _FlashingEngineButtonState();
}

class _FlashingEngineButtonState extends State<FlashingEngineButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacityAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isEngineOn) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(FlashingEngineButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEngineOn != oldWidget.isEngineOn) {
      if (widget.isEngineOn) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = const Color(0xFFFFC107);
    final hsl = HSLColor.fromColor(baseColor);
    final darker = hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0)).toColor();
    final borderColor = hsl.withLightness((hsl.lightness + 0.10).clamp(0.0, 1.0)).toColor();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double opacity = widget.isEngineOn ? _opacityAnimation.value : 1.0;
        final double scale = widget.isEngineOn ? _scaleAnimation.value : 1.0;

        final bgGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor.withValues(alpha: opacity),
            darker.withValues(alpha: opacity),
          ],
        );

        final borderClr = borderColor.withValues(alpha: 0.6 * opacity);
        final shadowClr = baseColor.withValues(alpha: (widget.isEngineOn ? 0.5 : 0.25) * opacity);
        final double blurRadius = widget.isEngineOn ? (10.0 * opacity) : 5.0;
        final double spreadRadius = widget.isEngineOn ? (1.5 * opacity) : 0.5;

        final buttonContainer = Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: bgGradient,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderClr,
              width: widget.isEngineOn ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowClr,
                blurRadius: blurRadius,
                spreadRadius: spreadRadius,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.25 * opacity),
                          Colors.white.withValues(alpha: 0.08 * opacity),
                          Colors.transparent,
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.25, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
                const Center(
                  child: Icon(
                    Icons.bolt_rounded,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );

        return Tooltip(
          message: widget.isEngineOn ? 'Turn Engine Off' : 'Turn Engine On',
          decoration: BoxDecoration(
            color: ScholarlyTheme.backgroundDark.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Transform.scale(
              scale: scale,
              child: buttonContainer,
            ),
          ),
        );
      },
    );
  }
}



