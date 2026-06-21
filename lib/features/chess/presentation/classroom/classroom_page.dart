import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/local_classroom_service.dart';
import '../../services/chess_sound_service.dart';
import '../../services/auth_service.dart';
import '../../application/study_lab_provider.dart';
import '../../application/chess_provider.dart';
import '../analysis/analysis_board.dart';
import '../widgets/ambient_scaffold.dart';
import '../scholarly_theme.dart';
import '../mobile_navigation_shell.dart';

class ClassroomPage extends ConsumerStatefulWidget {
  const ClassroomPage({super.key});

  @override
  ConsumerState<ClassroomPage> createState() => _ClassroomPageState();
}

class _ClassroomPageState extends ConsumerState<ClassroomPage> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _classIdController = TextEditingController();
  final TextEditingController _meetUrlController = TextEditingController();
  
  bool _showEvalBar = true;
  
  // Sparring Selection state
  String? _sparringStudentA;
  String? _sparringStudentB;

  @override
  void initState() {
    super.initState();
    
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

  @override
  void dispose() {
    _classIdController.dispose();
    _meetUrlController.dispose();
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

  Future<void> _sharePgnFile(String pgnContent) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/classroom_study.pgn');
      await tempFile.writeAsString(pgnContent);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempFile.path)],
          subject: 'Export PGN',
        ),
      );
    } catch (e) {
      debugPrint("Error exporting PGN: $e");
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(localClassroomProvider);
    final studyState = ref.watch(studyLabProvider);
    final studyNotifier = ref.read(studyLabProvider.notifier);

    // Sync board FEN to student when teacher makes move
    ref.listen<String>(studyLabProvider.select((s) => s.activeFen), (previous, next) {
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isLandscape = constraints.maxWidth > constraints.maxHeight;
                    if (isLandscape) {
                      return _buildLandscape(state, studyState, studyNotifier, constraints);
                    }
                    return _buildPortrait(state, studyState, studyNotifier, constraints);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ClassroomState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ScholarlyTheme.panelStroke)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: ScholarlyTheme.textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          const SizedBox(width: 8),
          Text(
            'CLASSROOM',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ScholarlyTheme.textPrimary,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          if (state.isJoined)
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

  Widget _buildLandscape(
    ClassroomState state,
    StudyLabState studyState,
    StudyLabNotifier studyNotifier,
    BoxConstraints constraints,
  ) {
    final boardSize = math.min(constraints.maxWidth * 0.55, constraints.maxHeight - 20);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: boardSize,
              height: boardSize,
              child: StudyLabChessBoard(
                state: studyState,
                notifier: studyNotifier,
                boardSize: boardSize,
                showEvalBar: _showEvalBar,
              ),
            ),
            const SizedBox(height: 8),
            _buildBoardControls(studyState, studyNotifier),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildRightPanel(state, studyState, studyNotifier),
        ),
      ],
    );
  }

  Widget _buildPortrait(
    ClassroomState state,
    StudyLabState studyState,
    StudyLabNotifier studyNotifier,
    BoxConstraints constraints,
  ) {
    final boardSize = constraints.maxWidth;
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            width: boardSize,
            height: boardSize,
            child: StudyLabChessBoard(
              state: studyState,
              notifier: studyNotifier,
              boardSize: boardSize,
              showEvalBar: _showEvalBar,
            ),
          ),
          const SizedBox(height: 8),
          _buildBoardControls(studyState, studyNotifier),
          const SizedBox(height: 12),
          _buildRightPanel(state, studyState, studyNotifier),
        ],
      ),
    );
  }

  Widget _buildBoardControls(StudyLabState state, StudyLabNotifier notifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: ScholarlyTheme.textPrimary, size: 20),
          onPressed: () {
            ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
            notifier.undo();
          },
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.restart_alt_rounded, color: ScholarlyTheme.textPrimary, size: 20),
          onPressed: () {
            ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
            notifier.selectNode(null);
          },
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.share_rounded, color: ScholarlyTheme.textPrimary, size: 20),
          onPressed: () {
            ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
            _sharePgnFile(notifier.exportToPgn());
          },
        ),
        const SizedBox(width: 16),
        Text(
          'Eval Bar',
          style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12),
        ),
        Switch(
          value: _showEvalBar,
          activeThumbColor: ScholarlyTheme.accentBlue,
          onChanged: (val) {
            setState(() {
              _showEvalBar = val;
            });
          },
        ),
      ],
    );
  }

  Widget _buildRightPanel(
    ClassroomState state,
    StudyLabState studyState,
    StudyLabNotifier studyNotifier,
  ) {
    if (!state.isJoined) {
      return _buildSetupPanel(state);
    }
    return _buildSessionPanel(state, studyState, studyNotifier);
  }

  Widget _buildSetupPanel(ClassroomState state) {
    final notifier = ref.read(localClassroomProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: ScholarlyTheme.panelBase,
        border: Border.all(color: ScholarlyTheme.panelStroke),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Connection Mode Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Connection Mode:',
                style: GoogleFonts.outfit(color: ScholarlyTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              DropdownButton<ConnectionMode>(
                value: state.connectionMode,
                dropdownColor: ScholarlyTheme.panelBase,
                style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontWeight: FontWeight.w600),
                onChanged: (val) {
                  if (val != null) {
                    notifier.setConnectionMode(val);
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: ConnectionMode.wifi,
                    child: Text('Wi-Fi Network'),
                  ),
                  DropdownMenuItem(
                    value: ConnectionMode.nearby,
                    child: Text('Nearby / Bluetooth'),
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: ScholarlyTheme.panelStroke, height: 24),

          // TEACHER SECTION
          Text(
            'Host a Classroom',
            style: GoogleFonts.outfit(color: ScholarlyTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _classIdController,
            style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter Classroom Name',
              hintStyle: const TextStyle(color: ScholarlyTheme.textMuted),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ScholarlyTheme.accentBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () {
              final name = _classIdController.text.trim();
              if (name.isNotEmpty) {
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                notifier.createClassroom(name);
              }
            },
            child: Text('Start as Teacher', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),

          const Divider(color: ScholarlyTheme.panelStroke, height: 32),

          // STUDENT SECTION
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Join Classroom',
                style: GoogleFonts.outfit(color: ScholarlyTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: Icon(
                  state.isDiscovering ? Icons.stop_circle_rounded : Icons.search_rounded,
                  color: state.isDiscovering ? Colors.redAccent : ScholarlyTheme.accentBlue,
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
          const SizedBox(height: 8),
          if (state.isDiscovering)
            Row(
              children: [
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: ScholarlyTheme.accentBlue)),
                const SizedBox(width: 8),
                Text('Scanning for classrooms...', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12)),
              ],
            ),
          const SizedBox(height: 8),
          if (state.discoveredSessions.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: Text(
                state.isDiscovering ? 'No active sessions found yet.' : 'Tap search icon to discover classrooms.',
                style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 13),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.discoveredSessions.length,
              itemBuilder: (context, index) {
                final session = state.discoveredSessions[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(session.name, style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      session.mode == ConnectionMode.wifi ? 'Wi-Fi Broadcast' : 'Nearby/Bluetooth',
                      style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 11),
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ScholarlyTheme.accentBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                        notifier.joinClassroom(session.id);
                      },
                      child: const Text('Join'),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Role & Info Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ScholarlyTheme.accentBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(state.isTeacher ? Icons.admin_panel_settings_rounded : Icons.school_rounded, color: ScholarlyTheme.accentBlue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    state.isTeacher ? 'TEACHER MODE' : 'STUDENT MODE',
                    style: GoogleFonts.outfit(color: ScholarlyTheme.accentBlue, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (state.isTeacher) ...[
                Text('Class: ${state.classroomId}', style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                if (state.connectionMode == ConnectionMode.wifi && state.localIp != null)
                  Text('Local IP: ${state.localIp}:${ClassroomNotifier.wifiPort}', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 11))
                else
                  Text('Advertising via Bluetooth/Nearby', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 11)),
              ] else ...[
                Text('Room: Connected', style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(state.boardsLocked ? Icons.lock_rounded : Icons.lock_open_rounded, size: 14, color: state.boardsLocked ? Colors.redAccent : Colors.green),
                    const SizedBox(width: 4),
                    Text(state.boardsLocked ? 'Board Locked' : 'Board Editable', style: GoogleFonts.inter(fontSize: 11, color: ScholarlyTheme.textMuted)),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // TEACHER CONTROLS AND STUDENT LIST
        if (state.isTeacher) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ScholarlyTheme.panelBase,
              border: Border.all(color: ScholarlyTheme.panelStroke),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Classroom Sync Control', style: GoogleFonts.outfit(color: ScholarlyTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text('Sync Board to Students', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12)),
                    ),
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
                  children: [
                    Expanded(
                      child: Text('Lock Student Inputs', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12)),
                    ),
                    Switch(
                      value: state.boardsLocked,
                      activeThumbColor: ScholarlyTheme.accentBlue,
                      onChanged: (val) {
                        notifier.setBoardsLocked(val);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Google Meet Launcher Control
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ScholarlyTheme.panelBase,
              border: Border.all(color: ScholarlyTheme.panelStroke),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Google Meet Integration', style: GoogleFonts.outfit(color: ScholarlyTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _meetUrlController,
                  style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'https://meet.google.com/abc-defg-hij',
                    hintStyle: const TextStyle(color: ScholarlyTheme.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.04),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ScholarlyTheme.accentBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.video_call_rounded, size: 16),
                        label: const Text('Set & Open'),
                        onPressed: () {
                          final url = _meetUrlController.text.trim();
                          if (url.isNotEmpty) {
                            notifier.updateMeetLink(url);
                            _launchMeetLink(url);
                          }
                        },
                      ),
                    ),
                    if (state.meetLink != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.redAccent),
                        onPressed: () {
                          notifier.updateMeetLink(null);
                          _meetUrlController.clear();
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Connected Students list
          Text(
            'Connected Students (${state.students.length})',
            style: GoogleFonts.outfit(color: ScholarlyTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          if (state.students.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Text('No students connected yet.', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 13)),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.students.length,
              itemBuilder: (context, index) {
                final studentUid = state.students.keys.elementAt(index);
                final student = state.students[studentUid]!;
                
                final isSelectedA = _sparringStudentA == studentUid;
                final isSelectedB = _sparringStudentB == studentUid;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: ScholarlyTheme.panelBase,
                    border: Border.all(color: student.raisedHand ? Colors.orangeAccent : ScholarlyTheme.panelStroke),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Hand raise indicator
                      if (student.raisedHand)
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Icon(Icons.back_hand_rounded, color: Colors.orangeAccent, size: 18),
                        ),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(student.displayName, style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontWeight: FontWeight.bold)),
                            Text('Board FEN: ${student.boardFen.substring(0, 15)}...', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 10)),
                          ],
                        ),
                      ),

                      // Spectate Student Board
                      IconButton(
                        icon: const Icon(Icons.visibility_rounded, color: ScholarlyTheme.accentBlue, size: 18),
                        tooltip: 'Spectate Board',
                        onPressed: () {
                          ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                          studyNotifier.loadPositionSetup(student.boardFen);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Loaded ${student.displayName}\'s board.')),
                          );
                        },
                      ),

                      // Takeover Control
                      IconButton(
                        icon: const Icon(Icons.settings_remote_rounded, color: Colors.orangeAccent, size: 18),
                        tooltip: 'Takeover Board (Write)',
                        onPressed: () {
                          ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                          notifier.updateStudentBoardFenByTeacher(studentUid, studyState.activeFen);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Pushed FEN to ${student.displayName}.')),
                          );
                        },
                      ),

                      // Sparring checklist selection
                      Checkbox(
                        value: isSelectedA || isSelectedB,
                        activeColor: ScholarlyTheme.accentBlue,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              if (_sparringStudentA == null) {
                                _sparringStudentA = studentUid;
                              } else if (_sparringStudentB == null && _sparringStudentA != studentUid) {
                                _sparringStudentB = studentUid;
                              }
                            } else {
                              if (_sparringStudentA == studentUid) {
                                _sparringStudentA = null;
                              } else if (_sparringStudentB == studentUid) {
                                _sparringStudentB = null;
                              }
                            }
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),

          // Sparring Trigger Panel
          if (_sparringStudentA != null || _sparringStudentB != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.1),
                border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sparring Match Broker',
                    style: GoogleFonts.outfit(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Student A: ${_sparringStudentA != null ? state.students[_sparringStudentA]?.displayName : "Select Student"}\n'
                    'Student B: ${_sparringStudentB != null ? state.students[_sparringStudentB]?.displayName : "Select Student"}',
                    style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: (_sparringStudentA != null && _sparringStudentB != null)
                        ? () {
                            ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                            notifier.pairStudentsForSparring(_sparringStudentA!, _sparringStudentB!);
                            setState(() {
                              _sparringStudentA = null;
                              _sparringStudentB = null;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sparring match paired!')),
                            );
                          }
                        : null,
                    child: const Text('Pair & Start Sparring'),
                  ),
                ],
              ),
            ),
          ],
        ] else ...[
          // STUDENT CONTROLS
          Container(
            padding: const EdgeInsets.all(16.0),
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
                    Text('Need Help?', style: GoogleFonts.outfit(color: ScholarlyTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (state.students[currentUid]?.raisedHand ?? false)
                            ? Colors.orangeAccent
                            : ScholarlyTheme.accentBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.back_hand_rounded, size: 16),
                      label: Text((state.students[currentUid]?.raisedHand ?? false) ? 'Hand Raised' : 'Raise Hand'),
                      onPressed: () {
                        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                        final isRaised = state.students[currentUid]?.raisedHand ?? false;
                        notifier.toggleRaiseHand(!isRaised);
                      },
                    ),
                  ],
                ),
                if (state.meetLink != null) ...[
                  const Divider(color: ScholarlyTheme.panelStroke, height: 24),
                  Text('Video Lecture Link Active:', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12)),
                  const SizedBox(height: 6),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.video_call_rounded),
                    label: const Text('Join Google Meet'),
                    onPressed: () {
                      _launchMeetLink(state.meetLink!);
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
