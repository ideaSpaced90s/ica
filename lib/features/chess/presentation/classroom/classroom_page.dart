import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kingslayer_chess/src/rust/api/pgn_db.dart' as rust_pgn;
import 'package:kingslayer_chess/features/chess/data/saved_game.dart';
import 'package:kingslayer_chess/features/chess/domain/models/historical_game.dart';
import 'package:chess/chess.dart' as chess_lib;

import '../../services/local_classroom_service.dart';
import '../../services/chess_sound_service.dart';
import '../../services/auth_service.dart';
import '../../application/study_lab_provider.dart';
import '../../application/chess_provider.dart';
import '../../application/analysis_engine_controller.dart';
import '../../application/historical_cinema_provider.dart';
import '../analysis/analysis_board.dart';
import '../analysis/themes/analysis_classic_theme.dart';
import '../widgets/ambient_scaffold.dart';
import '../scholarly_theme.dart';
import '../mobile_navigation_shell.dart';

enum EnginePlayMode {
  manual,
  autoWhite,
  autoBlack,
  engineVsEngine,
}

enum ClassroomLibraryItemType {
  customStudy,
  academyGame,
  historicalGame,
}

class ClassroomLibraryItem {
  final String id;
  final ClassroomLibraryItemType type;
  final String title;
  final String details;
  final DateTime date;
  final dynamic data;

  const ClassroomLibraryItem({
    required this.id,
    required this.type,
    required this.title,
    required this.details,
    required this.date,
    required this.data,
  });
}

class ClassroomPage extends ConsumerStatefulWidget {
  const ClassroomPage({super.key});

  @override
  ConsumerState<ClassroomPage> createState() => _ClassroomPageState();
}

class _ClassroomPageState extends ConsumerState<ClassroomPage> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _classIdController = TextEditingController();
  final TextEditingController _meetUrlController = TextEditingController();
  final TextEditingController _editorFenController = TextEditingController();
  
  late TabController _tabController;
  final bool _showEvalBar = true;
  String? _activeClassroomTool; // 'editor', 'clock', 'navigation', or null
  bool _isAutoplayRunning = false;
  Timer? _autoplayTimer;
  
  // Sparring state
  // String? _sparringStudentA;
  // String? _sparringStudentB;

  // Engine Autoplay state
  EnginePlayMode _enginePlayMode = EnginePlayMode.manual;
  Timer? _autoEngineMoveTimer;
  bool _isEngineThinking = false;
  bool _waitingForImmediateMove = false;

  // Library Explorer state
  String _librarySearchQuery = '';
  int _librarySubTabIndex = 0; // 0: Studies, 1: Academy Games, 2: Historical Games
  Future<List<rust_pgn.PgnGameRecord>>? _libraryFuture;

  // Chess Clock / Timer state
  bool _showTimer = false;
  bool _isClockRunning = false;
  Duration _whiteTimeLeft = const Duration(minutes: 10);
  Duration _blackTimeLeft = const Duration(minutes: 10);
  Duration _baseTimeDuration = const Duration(minutes: 10);
  Duration _incrementDuration = const Duration(seconds: 0);
  Timer? _chessClockTimer;

  // Board Editor states
  final Map<String, String> _boardPieces = {};
  String _selectedPaletteItem = 'wP';
  bool _isWhiteToMove = true;
  bool _wkCastling = true;
  bool _wqCastling = true;
  bool _bkCastling = true;
  bool _bqCastling = true;
  String _enPassant = '-';
  int _halfMoves = 0;
  int _fullMoves = 1;
  bool _isBoardEditorActive = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: 2);
    
    // Bind current user to local classroom service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateChangesProvider).value;
      final name = user?.displayName ?? 'Master';
      final uid = user?.uid ?? 'master_uid';
      ref.read(localClassroomProvider.notifier).initializeUser(uid: uid, displayName: name);
      
      // Register back button override
      ref.read(backButtonOverridesProvider.notifier).update((map) => {
        ...map,
        14: _handleBackPress, // tab index 14 for Classroom
      });
    });
  }

  void _startAutoplay(StudyLabState studyState, StudyLabNotifier studyNotifier) {
    _autoplayTimer?.cancel();
    setState(() {
      _isAutoplayRunning = true;
    });
    
    _autoplayTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final currentIdx = ref.read(studyLabProvider).currentNodeIndex ?? 0;
      final children = ref.read(studyLabProvider).nodes.where((n) => n.parentIndex == currentIdx).toList();
      
      if (children.isEmpty) {
        // Reached the end of the line
        setState(() {
          _isAutoplayRunning = false;
        });
        timer.cancel();
      } else {
        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
        studyNotifier.redo();
      }
    });
  }

  void _stopAutoplay() {
    _autoplayTimer?.cancel();
    setState(() {
      _isAutoplayRunning = false;
    });
  }

  @override
  void dispose() {
    _classIdController.dispose();
    _meetUrlController.dispose();
    _editorFenController.dispose();
    _tabController.dispose();
    _autoEngineMoveTimer?.cancel();
    _chessClockTimer?.cancel();
    _autoplayTimer?.cancel();
    super.dispose();
  }

  Future<bool> _handleBackPress() async {
    final classroomState = ref.read(localClassroomProvider);
    if (classroomState.isJoined) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: ScholarlyTheme.panelBase,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Leave Session', style: GoogleFonts.outfit(color: ScholarlyTheme.textPrimary, fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to exit the Classroom session?', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Leave', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await ref.read(localClassroomProvider.notifier).leaveClassroom();
        return false; // Allow nav pop/exit to dashboard
      }
      return true; // Block pop
    }
    return false;
  }

  // _sharePgnFile removed as unused

  Future<void> _launchMeetLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch Meet link')),
      );
    }
  }

  // --- Clock Settings & Operations ---
  void _startChessClock() {
    _chessClockTimer?.cancel();
    if (!_showTimer || !_isClockRunning) return;

    DateTime lastTick = DateTime.now();
    _chessClockTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || !_isClockRunning) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      final elapsed = now.difference(lastTick);
      lastTick = now;

      final studyState = ref.read(studyLabProvider);
      final isWhiteToMove = !studyState.activeFen.contains(' b ');

      setState(() {
        if (isWhiteToMove) {
          final newTime = _whiteTimeLeft - elapsed;
          if (newTime <= Duration.zero) {
            _whiteTimeLeft = Duration.zero;
            _isClockRunning = false;
            _chessClockTimer?.cancel();
            _playTimeOutSound();
          } else {
            _whiteTimeLeft = newTime;
          }
        } else {
          final newTime = _blackTimeLeft - elapsed;
          if (newTime <= Duration.zero) {
            _blackTimeLeft = Duration.zero;
            _isClockRunning = false;
            _chessClockTimer?.cancel();
            _playTimeOutSound();
          } else {
            _blackTimeLeft = newTime;
          }
        }
      });
    });
  }

  void _setTimerPreset(Duration base, Duration inc, String name) {
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
    setState(() {
      _baseTimeDuration = base;
      _incrementDuration = inc;
      _whiteTimeLeft = base;
      _blackTimeLeft = base;
      _isClockRunning = false;
      _showTimer = true;
    });
    _chessClockTimer?.cancel();
  }

  void _resetTimer() {
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
    setState(() {
      _whiteTimeLeft = _baseTimeDuration;
      _blackTimeLeft = _baseTimeDuration;
      _isClockRunning = false;
    });
    _chessClockTimer?.cancel();
  }

  void _playTimeOutSound() {
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Time Out! Game Over.'), backgroundColor: Colors.redAccent),
    );
  }

  // --- Engine Autoplay Operations ---
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
    if (_enginePlayMode == EnginePlayMode.engineVsEngine) {
      shouldPlay = true;
    } else if (_enginePlayMode == EnginePlayMode.autoWhite && isWhiteToMove) {
      shouldPlay = true;
    } else if (_enginePlayMode == EnginePlayMode.autoBlack && !isWhiteToMove) {
      shouldPlay = true;
    }

    if (shouldPlay) {
      if (engineState.topLines.isEmpty) {
        return; // Wait for engine lines
      }

      final bool isImmediate = _waitingForImmediateMove;
      _waitingForImmediateMove = false; // Reset the flag

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

  // --- Board Editor Operations ---
  void _initializeEditorState(String fen) {
    try {
      final chess = chess_lib.Chess.fromFEN(fen);
      _boardPieces.clear();
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          final files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
          final ranks = ['8', '7', '6', '5', '4', '3', '2', '1'];
          final sq = '${files[c]}${ranks[r]}';
          final piece = chess.get(sq);
          if (piece != null) {
            final side = piece.color == chess_lib.Color.WHITE ? 'w' : 'b';
            final code = '$side${piece.type.toString().toUpperCase()}';
            _boardPieces[sq] = code;
          }
        }
      }
      _isWhiteToMove = chess.turn == chess_lib.Color.WHITE;
      _wkCastling = chess.fen.contains('K');
      _wqCastling = chess.fen.contains('Q');
      _bkCastling = chess.fen.contains('k');
      _bqCastling = chess.fen.contains('q');

      final parts = fen.split(' ');
      if (parts.length >= 4) {
        _enPassant = parts[3];
      } else {
        _enPassant = '-';
      }
      if (parts.length >= 5) {
        _halfMoves = int.tryParse(parts[4]) ?? 0;
      } else {
        _halfMoves = 0;
      }
      if (parts.length >= 6) {
        _fullMoves = int.tryParse(parts[5]) ?? 1;
      } else {
        _fullMoves = 1;
      }
    } catch (e) {
      debugPrint("Error initializing editor state: $e");
    }
  }

  String _generateEditorFen() {
    final buffer = StringBuffer();
    for (var r = 0; r < 8; r++) {
      var emptyCount = 0;
      for (var c = 0; c < 8; c++) {
        final files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
        final ranks = ['8', '7', '6', '5', '4', '3', '2', '1'];
        final sq = '${files[c]}${ranks[r]}';
        final piece = _boardPieces[sq];
        if (piece == null) {
          emptyCount++;
        } else {
          if (emptyCount > 0) {
            buffer.write(emptyCount);
            emptyCount = 0;
          }
          final side = piece[0];
          final type = piece[1];
          buffer.write(side == 'w' ? type.toUpperCase() : type.toLowerCase());
        }
      }
      if (emptyCount > 0) {
        buffer.write(emptyCount);
      }
      if (r < 7) {
        buffer.write('/');
      }
    }

    buffer.write(_isWhiteToMove ? ' w ' : ' b ');

    var castlingStr = '';
    if (_wkCastling) castlingStr += 'K';
    if (_wqCastling) castlingStr += 'Q';
    if (_bkCastling) castlingStr += 'k';
    if (_bqCastling) castlingStr += 'q';
    buffer.write(castlingStr.isEmpty ? '-' : castlingStr);

    buffer.write(' $_enPassant');
    buffer.write(' $_halfMoves $_fullMoves');

    return buffer.toString();
  }

  bool _applyEditorState({bool silent = false}) {
    final fen = _generateEditorFen();
    final validation = chess_lib.Chess.validate_fen(fen);
    final isValid = validation['valid'] as bool;

    if (!isValid) {
      if (!silent) {
        final errorMsg = validation['error'] as String;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid Position: $errorMsg'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return false;
    }

    ref.read(studyLabProvider.notifier).loadPositionSetup(fen);
    return true;
  }

  void _clearEditorBoard() {
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
    setState(() {
      _boardPieces.clear();
      _wkCastling = false;
      _wqCastling = false;
      _bkCastling = false;
      _bqCastling = false;
      _enPassant = '-';
      _halfMoves = 0;
      _fullMoves = 1;
      _applyEditorState(silent: true);
    });
  }

  void _resetEditorToDefault() {
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
    setState(() {
      final chess = chess_lib.Chess();
      _initializeEditorState(chess.fen);
      _applyEditorState(silent: true);
    });
  }

  void _handleEditorSquareTap(String sq) {
    setState(() {
      final existing = _boardPieces[sq];
      if (_selectedPaletteItem == 'trash') {
        _boardPieces.remove(sq);
      } else {
        if (existing == _selectedPaletteItem) {
          _boardPieces.remove(sq);
        } else {
          _boardPieces[sq] = _selectedPaletteItem;
        }
      }
      _applyEditorState(silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(localClassroomProvider);
    final studyState = ref.watch(studyLabProvider);
    final studyNotifier = ref.read(studyLabProvider.notifier);

    // Sync board FEN to student when teacher makes move
    ref.listen<String>(studyLabProvider.select((s) => s.activeFen), (previous, next) {
      _checkAutoEngineMove();
      if (state.isJoined && state.isTeacher && state.syncToTeacher) {
        ref.read(localClassroomProvider.notifier).updateTeacherBoardFen(next);
      }
    });

    // Update local student board when teacher broadcasts a sync FEN
    ref.listen<ClassroomState>(localClassroomProvider, (previous, next) {
      if (next.isJoined && !next.isTeacher && next.syncToTeacher) {
        if (previous == null || previous.teacherBoardFen != next.teacherBoardFen) {
          if (studyState.activeFen != next.teacherBoardFen) {
            studyNotifier.loadPositionSetup(next.teacherBoardFen);
          }
        }
      }
    });

    // Listen to engine updates for autoplay scheduler
    ref.listen(analysisEngineControllerProvider, (previous, next) {
      if (next.isEngineOn) {
        _checkAutoEngineMove(isEngineUpdate: true);
      }
    });

    return AmbientScaffold(
      scaffoldKey: _scaffoldKey,
      blob1Color: const Color(0xFFEFF6FF),
      blob2Color: const Color(0xFFECFDF5),
      blob3Color: const Color(0xFFFFFBEB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(state),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe gestures to avoid conflicting with chessboard dragging
                children: [
                  _buildFullMovesTab(studyState, studyNotifier),
                  _buildFullLibraryTab(studyState, studyNotifier),
                  _buildFullClassTab(state, studyState, studyNotifier),
                  _buildFullEngineTab(studyState, studyNotifier),
                  _buildFullConnectTab(state),
                ],
              ),
            ),
          ],
        ),
      ),
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
              Tab(icon: Icon(Icons.list_alt_rounded, size: 20), text: 'Moves'),
              Tab(icon: Icon(Icons.folder_copy_rounded, size: 20), text: 'Library'),
              Tab(icon: Icon(Icons.school_rounded, size: 20), text: 'Class'),
              Tab(icon: Icon(Icons.analytics_rounded, size: 20), text: 'Engine'),
              Tab(icon: Icon(Icons.sensors_rounded, size: 20), text: 'Connect'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ClassroomState state) {
    if (!state.isJoined) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
              foregroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.exit_to_app_rounded, size: 16),
            label: const Text('Leave'),
            onPressed: () async {
              final confirm = await _handleBackPress();
              if (!confirm) {
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFullMovesTab(StudyLabState studyState, StudyLabNotifier studyNotifier) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ScholarlyTheme.panelBase,
        border: Border.all(color: ScholarlyTheme.panelStroke),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GAME NOTATION',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: ScholarlyTheme.accentBlue),
              ),
              Text(
                'Moves Played: ${studyState.nodes.length - 1}',
                style: GoogleFonts.inter(fontSize: 11, color: ScholarlyTheme.textMuted),
              ),
            ],
          ),
          const Divider(height: 20, color: ScholarlyTheme.panelStroke),
          Expanded(
            child: _buildMovesTab(studyState, studyNotifier),
          ),
        ],
      ),
    );
  }

  Widget _buildFullLibraryTab(StudyLabState studyState, StudyLabNotifier studyNotifier) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ScholarlyTheme.panelBase,
        border: Border.all(color: ScholarlyTheme.panelStroke),
        borderRadius: BorderRadius.circular(16),
      ),
      child: _buildLibraryTab(studyState, studyNotifier),
    );
  }

  Widget _buildFullEngineTab(StudyLabState studyState, StudyLabNotifier studyNotifier) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ScholarlyTheme.panelBase,
        border: Border.all(color: ScholarlyTheme.panelStroke),
        borderRadius: BorderRadius.circular(16),
      ),
      child: _buildEngineTab(studyState, studyNotifier),
    );
  }

  Widget _buildFullConnectTab(ClassroomState state) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ScholarlyTheme.panelBase,
        border: Border.all(color: ScholarlyTheme.panelStroke),
        borderRadius: BorderRadius.circular(16),
      ),
      child: _buildConnectTab(state),
    );
  }

  Widget _buildFullClassTab(
    ClassroomState state,
    StudyLabState studyState,
    StudyLabNotifier studyNotifier,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final double availableHeight = constraints.maxHeight;
        final isLandscape = availableWidth > availableHeight;

        if (isLandscape) {
          final boardSize = math.min(availableWidth * 0.52, availableHeight - 60);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPlayerBar(isOpponent: true, studyState: studyState),
                  SizedBox(
                    width: boardSize,
                    height: boardSize,
                    child: StudyLabChessBoard(
                      state: studyState,
                      notifier: studyNotifier,
                      boardSize: boardSize,
                      showEvalBar: _showEvalBar,
                      isEditorMode: _isBoardEditorActive,
                      onSquareTap: _handleEditorSquareTap,
                    ),
                  ),
                  _buildPlayerBar(isOpponent: false, studyState: studyState),
                  _buildQuickToolsRow(studyState, studyNotifier),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: ScholarlyTheme.panelBase,
                    border: Border.all(color: ScholarlyTheme.panelStroke),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _buildClassroomCleanArea(state, studyState, studyNotifier),
                ),
              ),
            ],
          );
        }

        // Portrait Layout
        final boardSize = availableWidth;
        return Column(
          children: [
            _buildPlayerBar(isOpponent: true, studyState: studyState),
            SizedBox(
              width: boardSize,
              height: boardSize,
              child: StudyLabChessBoard(
                state: studyState,
                notifier: studyNotifier,
                boardSize: boardSize,
                showEvalBar: _showEvalBar,
                isEditorMode: _isBoardEditorActive,
                onSquareTap: _handleEditorSquareTap,
              ),
            ),
            _buildPlayerBar(isOpponent: false, studyState: studyState),
            _buildQuickToolsRow(studyState, studyNotifier),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  color: ScholarlyTheme.panelBase,
                  border: Border.all(color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5)),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: _buildClassroomCleanArea(state, studyState, studyNotifier),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildClassroomCleanArea(
    ClassroomState state,
    StudyLabState studyState,
    StudyLabNotifier studyNotifier,
  ) {
    if (_activeClassroomTool == 'editor') {
      return _buildInlineBoardEditor(studyState, studyNotifier);
    } else if (_activeClassroomTool == 'clock') {
      return _buildInlineClockSettings(studyState, studyNotifier);
    } else if (_activeClassroomTool == 'navigation') {
      return _buildMoveNavigationPanel(studyState, studyNotifier);
    }

    // Default clean area
    if (state.isJoined) {
      return _buildSessionPanel(state, studyState, studyNotifier);
    } else {
      return _buildMoveNavigationPanel(studyState, studyNotifier);
    }
  }

  Widget _buildInlineBoardEditor(StudyLabState studyState, StudyLabNotifier studyNotifier) {
    if (!_isBoardEditorActive) {
      _initializeEditorState(studyState.activeFen);
      _editorFenController.text = studyState.activeFen;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _isBoardEditorActive = true;
        });
      });
    }

    final pieces = [
      'wK', 'wQ', 'wR', 'wB', 'wN', 'wP',
      'bK', 'bQ', 'bR', 'bB', 'bN', 'bP',
    ];

    const theme = AnalysisClassicTheme();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('BOARD EDITOR', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: ScholarlyTheme.accentBlue)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                    onPressed: () {
                      final ok = _applyEditorState(silent: false);
                      if (ok) {
                        setState(() {
                          _isBoardEditorActive = false;
                          _activeClassroomTool = null;
                        });
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: ScholarlyTheme.textMuted),
                    onPressed: () {
                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                      setState(() {
                        _isBoardEditorActive = false;
                        _activeClassroomTool = null;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, 
              childAspectRatio: 1.0, 
              crossAxisSpacing: 6, 
              mainAxisSpacing: 6,
            ),
            itemCount: pieces.length + 1,
            itemBuilder: (context, index) {
              final isEraser = index == pieces.length;
              final code = isEraser ? 'trash' : pieces[index];
              final isSelected = _selectedPaletteItem == code;
              
              Widget pieceVisual;
              if (isEraser) {
                pieceVisual = const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 24);
              } else {
                final isWhitePiece = code.startsWith('w');
                final typeChar = code.substring(1);
                pieceVisual = Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: theme.buildPiece(context, typeChar, isWhitePiece, false, 0.0),
                );
              }

              return GestureDetector(
                onTap: () {
                  ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                  setState(() {
                    _selectedPaletteItem = code;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? ScholarlyTheme.accentBlue.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.02),
                    border: Border.all(color: isSelected ? ScholarlyTheme.accentBlue : ScholarlyTheme.panelStroke, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: pieceVisual),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Turn:', style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 11)),
              Row(
                children: [
                  ChoiceChip(
                    visualDensity: VisualDensity.compact,
                    label: const Text('White', style: TextStyle(fontSize: 10)),
                    selected: _isWhiteToMove,
                    onSelected: (val) {
                      setState(() {
                        _isWhiteToMove = true;
                        _applyEditorState(silent: true);
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    visualDensity: VisualDensity.compact,
                    label: const Text('Black', style: TextStyle(fontSize: 10)),
                    selected: !_isWhiteToMove,
                    onSelected: (val) {
                      setState(() {
                        _isWhiteToMove = false;
                        _applyEditorState(silent: true);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          Text('Castling Rights:', style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 11)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    visualDensity: VisualDensity.compact,
                    value: _wkCastling,
                    onChanged: (val) {
                      setState(() {
                        _wkCastling = val ?? false;
                        _applyEditorState(silent: true);
                      });
                    },
                  ),
                  Text('W O-O', style: GoogleFonts.inter(fontSize: 10, color: ScholarlyTheme.textPrimary)),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    visualDensity: VisualDensity.compact,
                    value: _wqCastling,
                    onChanged: (val) {
                      setState(() {
                        _wqCastling = val ?? false;
                        _applyEditorState(silent: true);
                      });
                    },
                  ),
                  Text('W O-O-O', style: GoogleFonts.inter(fontSize: 10, color: ScholarlyTheme.textPrimary)),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    visualDensity: VisualDensity.compact,
                    value: _bkCastling,
                    onChanged: (val) {
                      setState(() {
                        _bkCastling = val ?? false;
                        _applyEditorState(silent: true);
                      });
                    },
                  ),
                  Text('B O-O', style: GoogleFonts.inter(fontSize: 10, color: ScholarlyTheme.textPrimary)),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    visualDensity: VisualDensity.compact,
                    value: _bqCastling,
                    onChanged: (val) {
                      setState(() {
                        _bqCastling = val ?? false;
                        _applyEditorState(silent: true);
                      });
                    },
                  ),
                  Text('B O-O-O', style: GoogleFonts.inter(fontSize: 10, color: ScholarlyTheme.textPrimary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _editorFenController,
                  style: GoogleFonts.inter(fontSize: 10, color: ScholarlyTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'FEN String',
                    labelStyle: const TextStyle(fontSize: 9),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ScholarlyTheme.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () {
                  ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                  final fen = _editorFenController.text.trim();
                  if (fen.isNotEmpty) {
                    _initializeEditorState(fen);
                    _applyEditorState(silent: false);
                  }
                },
                child: const Text('Load', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent, 
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  icon: const Icon(Icons.brush_rounded, size: 14),
                  label: const Text('Brush (Clear)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    _clearEditorBoard();
                    _editorFenController.text = _generateEditorFen();
                    setState(() {
                      _isBoardEditorActive = false;
                      _activeClassroomTool = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: const Text('Reset Default', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    _resetEditorToDefault();
                    _editorFenController.text = _generateEditorFen();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInlineClockSettings(StudyLabState studyState, StudyLabNotifier studyNotifier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CHESS CLOCK / TIMER', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: ScholarlyTheme.accentBlue)),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: ScholarlyTheme.textMuted),
                onPressed: () {
                  ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                  setState(() {
                    _activeClassroomTool = null;
                  });
                },
              ),
            ],
          ),
          const Divider(height: 8, color: ScholarlyTheme.panelStroke),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Clock Status:', style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Text(_showTimer ? 'ON' : 'OFF', style: GoogleFonts.inter(color: _showTimer ? Colors.green : ScholarlyTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Switch(
                    value: _showTimer,
                    activeThumbColor: ScholarlyTheme.accentBlue,
                    onChanged: (val) {
                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                      setState(() {
                        _showTimer = val;
                        if (!val) {
                          _isClockRunning = false;
                          _chessClockTimer?.cancel();
                        }
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isClockRunning ? Colors.orangeAccent : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  icon: Icon(_isClockRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 14),
                  label: Text(_isClockRunning ? 'Pause' : 'Start', style: const TextStyle(fontSize: 11)),
                  onPressed: () {
                    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                    setState(() {
                      _isClockRunning = !_isClockRunning;
                      if (_isClockRunning) {
                        _showTimer = true;
                        _startChessClock();
                      } else {
                        _chessClockTimer?.cancel();
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: const Text('Reset', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    _resetTimer();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text('SELECT PRESETS:', style: GoogleFonts.outfit(fontSize: 9, letterSpacing: 0.5, color: ScholarlyTheme.textMuted, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2.2, crossAxisSpacing: 6, mainAxisSpacing: 6),
            children: [
              _buildPresetButton(const Duration(minutes: 1), const Duration(seconds: 0), "1m"),
              _buildPresetButton(const Duration(minutes: 3), const Duration(seconds: 2), "3+2"),
              _buildPresetButton(const Duration(minutes: 5), const Duration(seconds: 0), "5m"),
              _buildPresetButton(const Duration(minutes: 10), const Duration(seconds: 0), "10m"),
              _buildPresetButton(const Duration(minutes: 15), const Duration(seconds: 10), "15+10"),
              _buildPresetButton(const Duration(minutes: 30), const Duration(seconds: 0), "30m"),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
            onPressed: () {
              _showCustomTimerDialog(context);
            },
            child: const Text('Custom Timer...', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton(Duration base, Duration inc, String label) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero, 
        backgroundColor: Colors.black.withValues(alpha: 0.04), 
        foregroundColor: ScholarlyTheme.textPrimary, 
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed: () {
        _setTimerPreset(base, inc, label);
      },
      child: Text(label, style: const TextStyle(fontSize: 10)),
    );
  }

  Widget _buildMoveNavigationPanel(StudyLabState studyState, StudyLabNotifier studyNotifier) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'MOVE NAVIGATION',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: ScholarlyTheme.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: ScholarlyTheme.panelStroke.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ScholarlyTheme.panelStroke.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFlatNavButton(
                      icon: Icons.skip_previous_rounded,
                      tooltip: 'First Move',
                      onPressed: () {
                        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                        studyNotifier.selectNode(0);
                      },
                    ),
                    _buildVerticalDivider(),
                    _buildFlatNavButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      tooltip: 'Previous Move',
                      onPressed: () {
                        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                        studyNotifier.undo();
                      },
                    ),
                    _buildVerticalDivider(),
                    _buildFlatNavButton(
                      icon: _isAutoplayRunning ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                      tooltip: _isAutoplayRunning ? 'Pause Autoplay' : 'Play Autoplay',
                      color: _isAutoplayRunning ? Colors.orangeAccent : Colors.green,
                      size: 26,
                      onPressed: () {
                        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                        if (_isAutoplayRunning) {
                          _stopAutoplay();
                        } else {
                          _startAutoplay(studyState, studyNotifier);
                        }
                      },
                    ),
                    _buildVerticalDivider(),
                    _buildFlatNavButton(
                      icon: Icons.arrow_forward_ios_rounded,
                      tooltip: 'Next Move',
                      onPressed: () {
                        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                        studyNotifier.redo();
                      },
                    ),
                    _buildVerticalDivider(),
                    _buildFlatNavButton(
                      icon: Icons.skip_next_rounded,
                      tooltip: 'Last Move',
                      onPressed: () {
                        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                        int currentIdx = studyState.currentNodeIndex ?? 0;
                        while (true) {
                          final children = studyState.nodes.where((n) => n.parentIndex == currentIdx).toList();
                          if (children.isEmpty) break;
                          currentIdx = children.first.index;
                        }
                        studyNotifier.selectNode(currentIdx);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlatNavButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
    double? size,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Icon(icon, color: color ?? ScholarlyTheme.accentBlue, size: size ?? 22),
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 24,
      color: ScholarlyTheme.panelStroke.withValues(alpha: 0.15),
    );
  }

  Widget _buildPlayerBar({required bool isOpponent, required StudyLabState studyState}) {
    final isFlipped = studyState.isBoardFlipped;
    final bool isWhite = isOpponent ? isFlipped : !isFlipped;
    
    final Duration timeLeft = isWhite ? _whiteTimeLeft : _blackTimeLeft;
    final isWhiteToMove = !studyState.activeFen.contains(' b ');
    final bool isTimerActive = _isClockRunning && (isWhite == isWhiteToMove);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: ScholarlyTheme.panelBase.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ScholarlyTheme.panelStroke.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 10,
                backgroundColor: isWhite ? Colors.white : Colors.black,
                child: Icon(
                  Icons.person_rounded,
                  size: 12,
                  color: isWhite ? Colors.black : Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isWhite ? 'White' : 'Black',
                style: GoogleFonts.outfit(
                  color: ScholarlyTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (_showTimer)
            Row(
              children: [
                Icon(
                  Icons.alarm_rounded,
                  size: 12,
                  color: isTimerActive ? ScholarlyTheme.accentBlue : ScholarlyTheme.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDuration(timeLeft),
                  style: GoogleFonts.jetBrainsMono(
                    color: isTimerActive ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    final tenths = ((d.inMilliseconds % 1000) ~/ 100).toString();
    if (d < const Duration(minutes: 1)) {
      return '$minutes:$seconds.$tenths';
    }
    return '$minutes:$seconds';
  }

  Widget _buildQuickToolsRow(StudyLabState studyState, StudyLabNotifier studyNotifier) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(
              Icons.save_rounded, 
              color: ScholarlyTheme.accentBlue, 
              size: 20,
            ),
            tooltip: 'Save Position',
            onPressed: () {
              _promptSaveStudyName(context, studyNotifier);
            },
          ),
          IconButton(
            icon: Icon(
              _activeClassroomTool == 'editor' ? Icons.check_circle_rounded : Icons.grid_on_rounded,
              color: _activeClassroomTool == 'editor' ? Colors.green : ScholarlyTheme.accentBlue,
              size: 20,
            ),
            tooltip: 'Edit Board',
            onPressed: () {
              ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
              setState(() {
                if (_activeClassroomTool == 'editor') {
                  _isBoardEditorActive = false;
                  _activeClassroomTool = null;
                } else {
                  _activeClassroomTool = 'editor';
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              _activeClassroomTool == 'navigation' ? Icons.play_circle_filled_rounded : Icons.play_circle_outline_rounded,
              color: _activeClassroomTool == 'navigation' ? Colors.green : ScholarlyTheme.accentBlue,
              size: 20,
            ),
            tooltip: 'Move Navigation',
            onPressed: () {
              ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
              setState(() {
                _activeClassroomTool = _activeClassroomTool == 'navigation' ? null : 'navigation';
              });
            },
          ),
          IconButton(
            icon: Icon(
              Icons.alarm_rounded, 
              color: _activeClassroomTool == 'clock' ? Colors.green : ScholarlyTheme.accentBlue, 
              size: 20,
            ),
            tooltip: 'Set Clock',
            onPressed: () {
              ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
              setState(() {
                _activeClassroomTool = _activeClassroomTool == 'clock' ? null : 'clock';
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android_rounded, color: ScholarlyTheme.accentBlue, size: 20),
            tooltip: 'Flip Board',
            onPressed: () {
              ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
              studyNotifier.flipBoard();
            },
          ),
        ],
      ),
    );
  }

  // Obsolete _buildRightPanel removed

  // --- TAB 1: MOVES NOTATION PANE ---
  Widget _buildMovesTab(StudyLabState studyState, StudyLabNotifier studyNotifier) {
    final List<Widget> moveChips = [];
    _buildMoveTreeChips(studyState, studyNotifier, null, moveChips, 0);

    if (moveChips.isEmpty) {
      return Center(
        child: Text(
          'No moves played yet.\nMake a move on the board to start.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Wrap(
        spacing: 4,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: moveChips,
      ),
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
      chips.add(Text(' $moveNumber.', style: GoogleFonts.jetBrainsMono(color: ScholarlyTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)));
    } else if (parentIdx == null) {
      chips.add(Text(' ${math.max(1, moveNumber - 1)}...', style: GoogleFonts.jetBrainsMono(color: ScholarlyTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)));
    }

    final isCurrent = state.currentNodeIndex == mainNode.index;
    final String glyph = _getNAGSymbol(mainNode.annotation);

    chips.add(
      GestureDetector(
        onTap: () {
          ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
          notifier.selectNode(mainNode.index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: isCurrent ? ScholarlyTheme.accentBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${mainNode.san}$glyph',
            style: GoogleFonts.inter(
              color: isCurrent ? Colors.white : ScholarlyTheme.textPrimary,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );

    if (children.length > 1) {
      for (var i = 1; i < children.length; i++) {
        final altNode = children[i];
        final List<Widget> altChips = [];
        _buildMoveTreeChips(state, notifier, altNode.parentIndex, altChips, depth + 1);
        
        chips.add(
          Text(
            ' (',
            style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 11),
          ),
        );
        chips.addAll(altChips);
        chips.add(
          Text(
            ')',
            style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 11),
          ),
        );
      }
    }

    _buildMoveTreeChips(state, notifier, mainNode.index, chips, depth);
  }

  String _getNAGSymbol(MoveAnnotation a) {
    switch (a) {
      case MoveAnnotation.brilliant: return '!!';
      case MoveAnnotation.good: return '!';
      case MoveAnnotation.interesting: return '!?';
      case MoveAnnotation.dubious: return '?!';
      case MoveAnnotation.mistake: return '?';
      case MoveAnnotation.blunder: return '??';
      default: return '';
    }
  }

  int _getMoveNumberFromFen(String fen) {
    final parts = fen.split(' ');
    if (parts.length >= 6) {
      return int.tryParse(parts[5]) ?? 1;
    }
    return 1;
  }

  // --- TAB 2: LIBRARY EXPLORER ---
  Widget _buildLibraryTab(StudyLabState studyState, StudyLabNotifier studyNotifier) {
    _libraryFuture ??= studyNotifier.loadGamesFromLibrary();
    final chessState = ref.watch(chessProvider);
    final cinemaState = ref.watch(historicalCinemaProvider);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLibrarySubTabButton(0, 'Saved Games'),
            _buildLibrarySubTabButton(1, 'Legends'),
            _buildLibrarySubTabButton(2, 'Source'),
          ],
        ),
        if (_librarySubTabIndex != 2)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: TextField(
              style: GoogleFonts.inter(fontSize: 12, color: ScholarlyTheme.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                hintText: _librarySubTabIndex == 0 ? 'Search saved games...' : 'Search legends...',
                hintStyle: const TextStyle(fontSize: 11, color: ScholarlyTheme.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, size: 16, color: ScholarlyTheme.textMuted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) {
                setState(() {
                  _librarySearchQuery = val;
                });
              },
            ),
          ),
        Expanded(
          child: _librarySubTabIndex == 2
              ? _buildLibrarySourceTab(studyNotifier)
              : FutureBuilder<List<rust_pgn.PgnGameRecord>>(
                  future: _libraryFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (_librarySubTabIndex == 1) {
                      // Legends Tab
                      final Map<String, List<ClassroomLibraryItem>> grouped = {};
                      for (final game in cinemaState.games) {
                        final item = ClassroomLibraryItem(
                          id: "cinema_${game.id}",
                          type: ClassroomLibraryItemType.historicalGame,
                          title: "${game.white} vs ${game.black}",
                          details: "${game.event} (${game.year}) | ${game.educationalTheme}",
                          date: DateTime.now(),
                          data: game,
                        );
                        
                        final query = _librarySearchQuery.toLowerCase();
                        if (query.isEmpty || 
                            item.title.toLowerCase().contains(query) || 
                            item.details.toLowerCase().contains(query) || 
                            game.category.toLowerCase().contains(query)) {
                          grouped.putIfAbsent(game.category, () => []).add(item);
                        }
                      }

                      if (grouped.isEmpty) {
                        return Center(
                          child: Text('No legend games found.', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12)),
                        );
                      }

                      // Sort categories in the proper order as defined in the source
                      final sortedCategories = grouped.keys.toList()
                        ..sort((a, b) {
                          const categoryOrder = [
                            'cat_tactical',
                            'cat_positional',
                            'cat_dynamic',
                            'cat_endgame',
                            'cat_sacrifice',
                            'cat_hypermodern',
                            'cat_closed_systems',
                            'cat_sicilian_clashes',
                            'cat_initiative',
                            'cat_pawn_dynamics',
                            'cat_bishop_pair',
                            'cat_defensive_saves',
                          ];
                          int idxA = categoryOrder.indexWhere((key) => a.toLowerCase().contains(key));
                          int idxB = categoryOrder.indexWhere((key) => b.toLowerCase().contains(key));
                          if (idxA == -1) idxA = 999;
                          if (idxB == -1) idxB = 999;
                          return idxA.compareTo(idxB);
                        });

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: sortedCategories.length,
                        itemBuilder: (context, index) {
                          final categoryName = sortedCategories[index];
                          final gamesInCategory = grouped[categoryName]!;
                          final metadata = _getCategoryMetadata(categoryName);
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: ScholarlyTheme.panelStroke.withValues(alpha: 0.05),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ExpansionTile(
                              shape: const Border(),
                              collapsedShape: const Border(),
                              leading: Icon(metadata.icon, color: metadata.color, size: 20),
                              title: Text(
                                metadata.title,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: metadata.color,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    metadata.subtitle,
                                    style: GoogleFonts.inter(fontSize: 9, color: ScholarlyTheme.textMuted),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${gamesInCategory.length} game${gamesInCategory.length > 1 ? "s" : ""}',
                                    style: GoogleFonts.inter(fontSize: 8, color: ScholarlyTheme.textMuted, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              children: gamesInCategory.map((item) {
                                return ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                  title: Text(
                                    item.title,
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11, color: ScholarlyTheme.textPrimary),
                                  ),
                                  subtitle: Text(
                                    item.details,
                                    style: GoogleFonts.inter(fontSize: 9, color: ScholarlyTheme.textMuted),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.play_arrow_rounded, color: ScholarlyTheme.accentBlue, size: 18),
                                    onPressed: () {
                                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                                      final historical = item.data as HistoricalGame;
                                      studyNotifier.importPgn(historical.pgn);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Loaded: ${item.title}'), duration: const Duration(seconds: 1)),
                                      );
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      );
                    }

                    // Saved Games Tab (index == 0)
                    final customRecords = snapshot.data ?? const [];
                    final List<ClassroomLibraryItem> allItems = [];

                    // Combine Studies
                    for (var i = 0; i < customRecords.length; i++) {
                      final record = customRecords[i];
                      final title = record.header.event.isNotEmpty ? record.header.event : "Custom Study #${i + 1}";
                      final moveCount = record.movesPgn.split(" ").where((m) => m.isNotEmpty && !m.contains(".")).length;
                      final details = "${record.header.white} vs ${record.header.black} | Moves: $moveCount";
                      
                      allItems.add(ClassroomLibraryItem(
                        id: "study_${record.index}",
                        type: ClassroomLibraryItemType.customStudy,
                        title: title,
                        details: details,
                        date: DateTime.now(),
                        data: record,
                      ));
                    }

                    // Combine Academy Games
                    for (final game in chessState.savedGames) {
                      if (game.isAcademyActive) {
                        final shortId = game.id.length >= 4 ? game.id.substring(0, 4) : game.id;
                        final title = game.customName != null && game.customName!.isNotEmpty
                            ? game.customName!
                            : 'Academy Game $shortId';
                        final details = '${game.isPlayerWhite ? "White" : "Black"} | Moves: ${game.recentMoves.length}';
                        
                        allItems.add(ClassroomLibraryItem(
                          id: "saved_${game.id}",
                          type: ClassroomLibraryItemType.academyGame,
                          title: title,
                          details: details,
                          date: game.savedAt,
                          data: game,
                        ));
                      }
                    }

                    final query = _librarySearchQuery.toLowerCase();
                    final filtered = allItems.where((item) {
                      return item.title.toLowerCase().contains(query) ||
                          item.details.toLowerCase().contains(query);
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text('No saved games found.', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12)),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isStudy = item.type == ClassroomLibraryItemType.customStudy;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          color: ScholarlyTheme.panelStroke.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isStudy ? ScholarlyTheme.accentBlue.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isStudy ? 'STUDY' : 'ACADEMY',
                                    style: GoogleFonts.inter(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: isStudy ? ScholarlyTheme.accentBlue : Colors.green,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: ScholarlyTheme.textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(item.details, style: GoogleFonts.inter(fontSize: 10, color: ScholarlyTheme.textMuted)),
                            trailing: IconButton(
                              icon: const Icon(Icons.play_arrow_rounded, color: ScholarlyTheme.accentBlue, size: 18),
                              onPressed: () {
                                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                                if (item.type == ClassroomLibraryItemType.customStudy) {
                                  studyNotifier.loadPgnRecord(item.data as rust_pgn.PgnGameRecord, (item.data as rust_pgn.PgnGameRecord).index.toInt());
                                } else if (item.type == ClassroomLibraryItemType.academyGame) {
                                  final savedGame = item.data as SavedGameEntry;
                                  ref.read(chessProvider.notifier).initializeAcademySession(customFen: savedGame.initialFen ?? savedGame.fen);
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Loaded: ${item.title}'), duration: const Duration(seconds: 1)),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLibrarySourceTab(StudyLabNotifier studyNotifier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'IMPORT PGN DATA',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: ScholarlyTheme.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: ScholarlyTheme.panelStroke.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.file_upload_rounded, color: ScholarlyTheme.accentBlue, size: 20),
              title: Text('Import PGN...', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary)),
              subtitle: Text('Load a game from PGN text', style: GoogleFonts.inter(fontSize: 10, color: ScholarlyTheme.textMuted)),
              onTap: () {
                _importPgnFromFile(context, studyNotifier);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibrarySubTabButton(int index, String label) {
    final isActive = _librarySubTabIndex == index;
    return GestureDetector(
      onTap: () {
        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
        setState(() {
          _librarySubTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? ScholarlyTheme.accentBlue : Colors.transparent,
              width: 2.0,
            ),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? ScholarlyTheme.accentBlue : ScholarlyTheme.textMuted,
          ),
        ),
      ),
    );
  }

  // --- TAB 3: STOCKFISH ENGINE ---
  Widget _buildEngineTab(StudyLabState studyState, StudyLabNotifier studyNotifier) {
    final engineState = ref.watch(analysisEngineControllerProvider);
    final engineNotifier = ref.read(analysisEngineControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stockfish Analysis',
                style: GoogleFonts.outfit(color: ScholarlyTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Switch(
                value: engineState.isEngineOn,
                activeThumbColor: ScholarlyTheme.accentBlue,
                onChanged: (val) {
                  ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                  engineNotifier.toggleEngine(val, studyState.activeFen);
                  if (!val) {
                    setState(() {
                      _enginePlayMode = EnginePlayMode.manual;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (engineState.isEngineOn) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Evaluation Score:', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12)),
                  Text(
                    engineState.isMate && engineState.mateIn != null
                        ? 'Mate in ${engineState.mateIn!.abs()}'
                        : '${(engineState.evalScore ?? 0.0) > 0 ? "+" : ""}${engineState.evalScore?.toStringAsFixed(1) ?? "0.0"}',
                    style: GoogleFonts.jetBrainsMono(
                      color: ScholarlyTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Engine Mode:', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12)),
                DropdownButton<EnginePlayMode>(
                  value: _enginePlayMode,
                  dropdownColor: ScholarlyTheme.panelBase,
                  style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                      setState(() {
                        _enginePlayMode = val;
                        _waitingForImmediateMove = true;
                      });
                      _checkAutoEngineMove();
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: EnginePlayMode.manual, child: Text('Manual Mode')),
                    DropdownMenuItem(value: EnginePlayMode.autoWhite, child: Text('Auto White')),
                    DropdownMenuItem(value: EnginePlayMode.autoBlack, child: Text('Auto Black')),
                    DropdownMenuItem(value: EnginePlayMode.engineVsEngine, child: Text('Self-Play (EvE)')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              'RECOMMENDED LINES:',
              style: GoogleFonts.outfit(fontSize: 10, letterSpacing: 0.5, color: ScholarlyTheme.textMuted, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: engineState.topLines.isEmpty
                  ? Center(child: Text('Calculating best moves...', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 11)))
                  : ListView.builder(
                      itemCount: engineState.topLines.length,
                      itemBuilder: (context, index) {
                        final line = engineState.topLines[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '#${index + 1} (${line.eval > 0 ? "+" : ""}${line.eval.toStringAsFixed(1)}): ${line.moves.take(5).join(" ")}',
                            style: GoogleFonts.jetBrainsMono(fontSize: 11, color: ScholarlyTheme.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
            ),
          ] else ...[
            Expanded(
              child: Center(
                child: Text('Engine is inactive.\nTurn on analysis to calculate moves.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }


  // --- TAB 5: CONNECT TAB ---
  Widget _buildConnectTab(ClassroomState state) {
    if (!state.isJoined) {
      return _buildSetupPanel(state);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'CONNECTION DETAILS',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11, color: ScholarlyTheme.textMuted, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ScholarlyTheme.panelStroke.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ScholarlyTheme.panelStroke.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                _buildInfoRow('Status', 'Connected', valueColor: Colors.green),
                const Divider(height: 16, color: ScholarlyTheme.panelStroke),
                _buildInfoRow('Room ID', state.classroomId),
                const Divider(height: 16, color: ScholarlyTheme.panelStroke),
                _buildInfoRow('Role', state.isTeacher ? 'Host / Teacher' : 'Student'),
                const Divider(height: 16, color: ScholarlyTheme.panelStroke),
                _buildInfoRow('Mode', state.connectionMode == ConnectionMode.wifi ? 'Wi-Fi Socket' : 'Google Nearby'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.exit_to_app_rounded, size: 16),
            label: const Text('Leave Session', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () async {
              final confirm = await _handleBackPress();
              if (!confirm) {
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 11)),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: valueColor ?? ScholarlyTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSetupPanel(ClassroomState state) {
    final notifier = ref.read(localClassroomProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Connection Mode:', style: GoogleFonts.outfit(color: ScholarlyTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
              DropdownButton<ConnectionMode>(
                value: state.connectionMode,
                dropdownColor: ScholarlyTheme.panelBase,
                style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                    notifier.setConnectionMode(val);
                  }
                },
                items: const [
                  DropdownMenuItem(value: ConnectionMode.wifi, child: Text('Wi-Fi Network')),
                  DropdownMenuItem(value: ConnectionMode.nearby, child: Text('Google Nearby')),
                ],
              ),
            ],
          ),
          const Divider(color: ScholarlyTheme.panelStroke),

          Text('Host a Classroom', style: GoogleFonts.outfit(color: ScholarlyTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _classIdController,
                  style: GoogleFonts.inter(fontSize: 12, color: ScholarlyTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Classroom Name',
                    hintStyle: const TextStyle(fontSize: 11, color: ScholarlyTheme.textMuted),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ScholarlyTheme.accentBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final name = _classIdController.text.trim();
                  if (name.isNotEmpty) {
                    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                    notifier.createClassroom(name);
                  }
                },
                child: const Text('Host', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(color: ScholarlyTheme.panelStroke),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Join Classroom', style: GoogleFonts.outfit(color: ScholarlyTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
              IconButton(
                icon: Icon(
                  state.isDiscovering ? Icons.stop_circle_rounded : Icons.search_rounded,
                  color: state.isDiscovering ? Colors.redAccent : ScholarlyTheme.accentBlue,
                  size: 20,
                ),
                onPressed: () {
                  ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                  if (state.isDiscovering) {
                    notifier.stopDiscovery();
                  } else {
                    notifier.startDiscovery();
                  }
                },
              ),
            ],
          ),
          if (state.isDiscovering) ...[
            Row(
              children: [
                const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: ScholarlyTheme.accentBlue)),
                const SizedBox(width: 6),
                Text('Scanning for classrooms...', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 6),
          ],

          if (state.discoveredSessions.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              child: Text(
                state.isDiscovering ? 'No active sessions found yet.' : 'Tap search icon to discover classrooms.',
                style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 11),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.discoveredSessions.length,
              itemBuilder: (context, index) {
                final session = state.discoveredSessions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  color: ScholarlyTheme.panelStroke.withValues(alpha: 0.1),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text(session.name, style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                    subtitle: Text(
                      session.mode == ConnectionMode.wifi ? 'Wi-Fi Broadcast' : 'Nearby/Bluetooth',
                      style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 10),
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ScholarlyTheme.accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                        notifier.joinClassroom(session.id);
                      },
                      child: const Text('Join', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSessionPanel(
    ClassroomState state,
    StudyLabState studyState,
    StudyLabNotifier studyNotifier,
  ) {
    final notifier = ref.read(localClassroomProvider.notifier);
    final user = ref.read(authStateChangesProvider).value;
    final currentUid = user?.uid ?? 'guest_uid';

    final spectatedStudent = ref.watch(activeSpectatedStudentProvider);
    final takeoverMode = ref.watch(takeoverModeProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ScholarlyTheme.panelStroke.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ROOM: ${state.classroomId}',
                  style: GoogleFonts.outfit(color: ScholarlyTheme.accentBlue, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  state.isTeacher ? 'Host (Teacher)' : 'Student',
                  style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          if (state.isTeacher) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sync Board to Students', style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 12)),
                Switch(
                  value: state.syncToTeacher,
                  activeThumbColor: ScholarlyTheme.accentBlue,
                  onChanged: (val) {
                    notifier.setSyncToTeacher(val);
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Lock Student Inputs', style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 12)),
                Switch(
                  value: state.boardsLocked,
                  activeThumbColor: ScholarlyTheme.accentBlue,
                  onChanged: (val) {
                    notifier.setBoardsLocked(val);
                  },
                ),
              ],
            ),
            const Divider(color: ScholarlyTheme.panelStroke),

            Text('Google Meet video Link', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: ScholarlyTheme.textPrimary)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _meetUrlController,
                    style: GoogleFonts.inter(fontSize: 11, color: ScholarlyTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Paste Google Meet URL',
                      hintStyle: const TextStyle(fontSize: 10, color: ScholarlyTheme.textMuted),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ScholarlyTheme.accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () {
                    final url = _meetUrlController.text.trim();
                    if (url.isNotEmpty) {
                      notifier.updateMeetLink(url);
                      _launchMeetLink(url);
                    }
                  },
                  child: const Text('Summon', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(color: ScholarlyTheme.panelStroke),

            if (spectatedStudent != null) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        takeoverMode ? 'Takeover Active' : 'Spectating Student',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.amber),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            ref.read(takeoverModeProvider.notifier).update((s) => !s);
                          },
                          child: Text(takeoverMode ? 'Release' : 'Takeover', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
                          onPressed: () {
                            ref.read(activeSpectatedStudentProvider.notifier).state = null;
                            ref.read(takeoverModeProvider.notifier).state = false;
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            Text(
              'STUDENTS IN ROOM (${state.students.length})',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 10, color: ScholarlyTheme.textMuted),
            ),
            const SizedBox(height: 4),
            if (state.students.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(child: Text('Waiting for students...', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 11))),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.students.length,
                itemBuilder: (context, idx) {
                  final student = state.students.values.elementAt(idx);
                  final isSpectated = spectatedStudent == student.uid;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    color: ScholarlyTheme.panelStroke.withValues(alpha: 0.05),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: Row(
                        children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: student.online ? Colors.green : Colors.grey)),
                          const SizedBox(width: 6),
                          Expanded(child: Text(student.displayName, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary))),
                          if (student.raisedHand)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                              child: const Icon(Icons.pan_tool_rounded, color: Colors.amber, size: 8),
                            ),
                        ],
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSpectated ? Colors.amber : ScholarlyTheme.accentBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () {
                          ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                          if (isSpectated) {
                            ref.read(activeSpectatedStudentProvider.notifier).state = null;
                            ref.read(takeoverModeProvider.notifier).state = false;
                          } else {
                            ref.read(activeSpectatedStudentProvider.notifier).state = student.uid;
                            ref.read(takeoverModeProvider.notifier).state = false;
                            studyNotifier.loadPositionSetup(student.boardFen);
                          }
                        },
                        child: Text(isSpectated ? 'Stop' : 'Spectate', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                },
              ),
          ] else ...[
            Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: state.boardsLocked ? Colors.red : Colors.green)),
                const SizedBox(width: 8),
                Text(
                  state.boardsLocked ? 'Board Control: LOCKED' : 'Board Control: UNLOCKED',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: state.boardsLocked ? Colors.redAccent : Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: state.syncToTeacher ? ScholarlyTheme.accentBlue : Colors.grey)),
                const SizedBox(width: 8),
                Text(
                  state.syncToTeacher ? 'Teacher Mirroring: ACTIVE' : 'Teacher Mirroring: INACTIVE',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: state.syncToTeacher ? ScholarlyTheme.accentBlue : ScholarlyTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (state.meetLink != null && state.meetLink!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Google Meet is Active!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
                    const SizedBox(height: 4),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                      icon: const Icon(Icons.video_call_rounded, size: 14),
                      label: const Text('Join Meet', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () => _launchMeetLink(state.meetLink!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                final mySession = state.students[currentUid];
                final raised = mySession?.raisedHand ?? false;
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                notifier.toggleRaiseHand(!raised);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: (state.students[currentUid]?.raisedHand ?? false)
                      ? Colors.amber.withValues(alpha: 0.2)
                      : ScholarlyTheme.panelStroke.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (state.students[currentUid]?.raisedHand ?? false) ? Colors.amber : ScholarlyTheme.panelStroke),
                ),
                child: Column(
                  children: [
                    Icon(Icons.pan_tool_rounded, color: (state.students[currentUid]?.raisedHand ?? false) ? Colors.amber : ScholarlyTheme.textMuted, size: 30),
                    const SizedBox(height: 6),
                    Text(
                      (state.students[currentUid]?.raisedHand ?? false) ? 'HAND RAISED (HELP REQUESTED)' : 'RAISE HAND / REQUEST HELP',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11, color: (state.students[currentUid]?.raisedHand ?? false) ? Colors.amber : ScholarlyTheme.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- MODAL SHEETS REMOVED IN FAVOR OF INLINE PANELS ---

  Future<void> _importPgnFromFile(BuildContext context, StudyLabNotifier notifier) async {
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ScholarlyTheme.panelBase,
        title: Text('Import PGN', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary)),
        content: TextField(
          controller: controller,
          maxLines: 8,
          style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 12),
          decoration: const InputDecoration(
            hintText: 'Paste PGN text here...',
            hintStyle: TextStyle(color: ScholarlyTheme.textMuted),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final pgn = controller.text.trim();
              if (pgn.isNotEmpty) {
                notifier.importPgn(pgn);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PGN imported successfully!')),
                );
              }
            },
            child: const Text('Import', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _promptSaveStudyName(BuildContext context, StudyLabNotifier notifier) async {
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ScholarlyTheme.panelBase,
        title: Text('Save Study', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary)),
        content: TextField(
          controller: controller,
          style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Study Name (e.g. Opening practice)',
            hintStyle: TextStyle(color: ScholarlyTheme.textMuted),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final ok = await notifier.saveCurrentGameToLibrary(name);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ok ? 'Study "$name" saved!' : 'Failed to save study.')),
                  );
                }
                setState(() {
                  _libraryFuture = notifier.loadGamesFromLibrary();
                });
              }
            },
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCustomTimerDialog(BuildContext context) {
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
    final minutesController = TextEditingController(text: _baseTimeDuration.inMinutes.toString());
    final incrementController = TextEditingController(text: _incrementDuration.inSeconds.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ScholarlyTheme.panelBase,
        title: Text('Custom Time Control', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minutesController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'Minutes (Base)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: incrementController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'Seconds (Increment)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final min = int.tryParse(minutesController.text.trim()) ?? 10;
              final inc = int.tryParse(incrementController.text.trim()) ?? 0;
              _setTimerPreset(Duration(minutes: min), Duration(seconds: inc), "$min+$inc");
            },
            child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _CategoryMetadata {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _CategoryMetadata({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

_CategoryMetadata _getCategoryMetadata(String category) {
  final catLower = category.toLowerCase();
  if (catLower.contains("cat_tactical") || catLower.contains("horizons") || catLower.contains("horisons")) {
    return const _CategoryMetadata(
      title: "Open Horizons & Gambits",
      subtitle: "Attacking lines, piece sacrifices, and tactical calculations",
      icon: Icons.grid_on_rounded,
      color: Color(0xFF059669),
    );
  } else if (catLower.contains("cat_positional") || catLower.contains("fortress")) {
    return const _CategoryMetadata(
      title: "The Iron Fortress",
      subtitle: "Prophylaxis, pawn structures, and positional suffocation",
      icon: Icons.security_rounded,
      color: ScholarlyTheme.accentBlue,
    );
  } else if (catLower.contains("cat_dynamic") || catLower.contains("counterstrike")) {
    return const _CategoryMetadata(
      title: "The Counterstrike Collection",
      subtitle: "Sharp defense turning into instant attack and dynamics",
      icon: Icons.bolt_rounded,
      color: Color(0xFF7C3AED),
    );
  } else if (catLower.contains("cat_endgame") || catLower.contains("endgame")) {
    return const _CategoryMetadata(
      title: "The Endgame Squeeze",
      subtitle: "Technical conversions, king activity, and promotion races",
      icon: Icons.workspace_premium_rounded,
      color: ScholarlyTheme.realGold,
    );
  } else if (catLower.contains("cat_sacrifice") || catLower.contains("sacrifice")) {
    return const _CategoryMetadata(
      title: "The Art of the Sacrifice",
      subtitle: "Direct piece sacrifices, king hunts, and mating combinations",
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFE11D48),
    );
  } else if (catLower.contains("cat_hypermodern") || catLower.contains("hypermodern")) {
    return const _CategoryMetadata(
      title: "Hypermodern Masterpieces",
      subtitle: "Flank control, fianchetto setups, and indirect center pressure",
      icon: Icons.radar_rounded,
      color: Color(0xFF0D9488),
    );
  } else if (catLower.contains("cat_closed_systems") || catLower.contains("closed")) {
    return const _CategoryMetadata(
      title: "Queen's Gambit & Closed Stratagems",
      subtitle: "Pawn structures, minority attacks, and tension in closed files",
      icon: Icons.lock_rounded,
      color: Color(0xFF4F46E5),
    );
  } else if (catLower.contains("cat_sicilian") || catLower.contains("sicilian")) {
    return const _CategoryMetadata(
      title: "Razor-Sharp Sicilians",
      subtitle: "Asymmetrical tactical battles and opposite-side castling storms",
      icon: Icons.offline_bolt_rounded,
      color: Color(0xFFEA580C),
    );
  } else if (catLower.contains("cat_initiative") || catLower.contains("initiative")) {
    return const _CategoryMetadata(
      title: "Mastering the Initiative",
      subtitle: "Energetic play, continuous threats, and restricting the defender",
      icon: Icons.trending_up_rounded,
      color: Color(0xFF2563EB),
    );
  } else if (catLower.contains("cat_pawn") || catLower.contains("pawn")) {
    return const _CategoryMetadata(
      title: "Pawn Structure Dynamics",
      subtitle: "Carlsbad pawn chains, isolated pawns, and passed pawn advances",
      icon: Icons.grain_rounded,
      color: Color(0xFF65A30D),
    );
  } else if (catLower.contains("cat_bishop") || catLower.contains("bishop")) {
    return const _CategoryMetadata(
      title: "The Power of the Bishop Pair",
      subtitle: "Long-range domination, knight restriction, and diagonal control",
      icon: Icons.layers_rounded,
      color: Color(0xFF7C3AED),
    );
  } else if (catLower.contains("cat_defensive") || catLower.contains("escape")) {
    return const _CategoryMetadata(
      title: "The Art of the Escape",
      subtitle: "Miraculous swindles, constructing fortresses, and saving the game",
      icon: Icons.shield_rounded,
      color: Color(0xFF475569),
    );
  }
  return const _CategoryMetadata(
    title: "Other Legend Games",
    subtitle: "Historical masterpieces",
    icon: Icons.movie_filter_rounded,
    color: ScholarlyTheme.accentBlue,
  );
}
