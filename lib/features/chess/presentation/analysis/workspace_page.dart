import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kingslayer_chess/src/rust/api/pgn_db.dart' as rust_pgn;

import '../widgets/ambient_scaffold.dart';
import '../scholarly_theme.dart';
import '../../application/study_lab_provider.dart';
import '../../application/chess_provider.dart';
import '../../services/chess_sound_service.dart';
import 'widgets/game_report_panel.dart';
import 'widgets/practice_mode_panel.dart';

class WorkspacePage extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const WorkspacePage({
    super.key,
    required this.initialTabIndex,
  });

  @override
  ConsumerState<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends ConsumerState<WorkspacePage> {
  late int _workspaceTabIndex;
  final Set<String> _pulledGameIds = {};

  @override
  void initState() {
    super.initState();
    _workspaceTabIndex = widget.initialTabIndex;
  }

  int _getMoveNumberFromFen(String fen) {
    final parts = fen.split(' ');
    if (parts.length >= 6) {
      return int.tryParse(parts[5]) ?? 1;
    }
    return 1;
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



  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studyLabProvider);
    final notifier = ref.read(studyLabProvider.notifier);

    String title = 'WORKSPACE';
    Widget overlayBody = const SizedBox.shrink();

    switch (_workspaceTabIndex) {
      case 0:
        title = 'MOVE TREE';
        overlayBody = _buildMoveTreeOverlayTab(context, state, notifier);
        break;
      case 1:
        title = 'IMPORT / EXPORT';
        overlayBody = _buildImpoExpoOverlayTab(context, state, notifier);
        break;
      case 2:
        title = 'GAME LIBRARY';
        overlayBody = _buildGameLibraryOverlayTab(context, state, notifier);
        break;
      case 3:
        title = 'PRACTICE LAB';
        overlayBody = const PracticeModePanel();
        break;
      case 4:
        title = 'GAME REPORT';
        overlayBody = const GameReportPanel();
        break;
    }

    return Scaffold(
      backgroundColor: ScholarlyTheme.backgroundStart,
      appBar: AppBar(
        backgroundColor: ScholarlyTheme.backgroundStart,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: ScholarlyTheme.textPrimary,
            size: 20,
          ),
          onPressed: () {
            ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
            Navigator.pop(context);
          },
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: ScholarlyTheme.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            Expanded(
              child: overlayBody,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoveTreeOverlayTab(
    BuildContext context,
    StudyLabState state,
    StudyLabNotifier notifier,
  ) {
    final List<Widget> moveChips = [];
    _buildMoveTreeChips(state, notifier, null, moveChips, 0);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: JuicyGlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schema_rounded, size: 16, color: ScholarlyTheme.accentBlue),
                const SizedBox(width: 6),
                Text(
                  'STUDY LAB FLOW',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: ScholarlyTheme.accentBlue,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                if (state.commentary != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: ScholarlyTheme.accentBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.25)),
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
            ),
            const SizedBox(height: 12),
            moveChips.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: Text(
                      'No moves played yet. Play some moves on the board to build a variation tree!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: ScholarlyTheme.textMuted,
                      ),
                    ),
                  )
                : Wrap(
                    spacing: 6.0,
                    runSpacing: 10.0,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: moveChips,
                  ),
          ],
        ),
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
      chips.add(Text(' $moveNumber.', style: GoogleFonts.jetBrainsMono(color: ScholarlyTheme.textMuted, fontSize: 13, fontWeight: FontWeight.bold)));
    } else if (parentIdx == null) {
      chips.add(Text(' ${moveNumber - 1}...', style: GoogleFonts.jetBrainsMono(color: ScholarlyTheme.textMuted, fontSize: 13, fontWeight: FontWeight.bold)));
    }

    final isCurrent = state.currentNodeIndex == mainNode.index;
    final String glyph = _getNAGSymbol(mainNode.annotation);

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
          child: Text(
            '${mainNode.san}$glyph',
            style: GoogleFonts.inter(
              color: isCurrent ? Colors.white : ScholarlyTheme.textPrimary,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );

    for (int i = 1; i < children.length; i++) {
      final sideNode = children[i];
      chips.add(Text(' (', style: GoogleFonts.inter(color: ScholarlyTheme.textSubtle, fontSize: 13)));

      final isSideCurrent = state.currentNodeIndex == sideNode.index;
      final String sideGlyph = _getNAGSymbol(sideNode.annotation);

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
            child: Text(
              '${sideNode.san}$sideGlyph',
              style: GoogleFonts.inter(
                color: isSideCurrent ? Colors.white : ScholarlyTheme.textPrimary,
                fontWeight: isSideCurrent ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );

      _buildMoveTreeChips(state, notifier, sideNode.index, chips, depth + 1);
      chips.add(Text(')', style: GoogleFonts.inter(color: ScholarlyTheme.textSubtle, fontSize: 13)));
    }

    _buildMoveTreeChips(state, notifier, mainNode.index, chips, depth);
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
                leading: const Icon(Icons.comment_outlined, color: Colors.teal),
                title: Text('Edit Comment', style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _showCommentEditDialog(context, node, notifier);
                },
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
                notifier.updateComment(controller.text);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImpoExpoOverlayTab(
    BuildContext context,
    StudyLabState state,
    StudyLabNotifier notifier,
  ) {
    final chessState = ref.watch(chessProvider);
    final eligibleGames = chessState.savedGames.where((s) => s.recentMoves.isNotEmpty).toList();
    final availableGames = eligibleGames.where((g) => !_pulledGameIds.contains(g.id)).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionTile(
                  title: 'IMPORT PGN',
                  subtitle: 'Select PGN File',
                  icon: Icons.file_upload_rounded,
                  color: ScholarlyTheme.accentBlue,
                  onTap: () => _importPgnFromFile(context, notifier),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionTile(
                  title: 'EXPORT PGN',
                  subtitle: 'Save to Downloads',
                  icon: Icons.file_download_rounded,
                  color: Colors.teal,
                  onTap: () => _exportPgnToDownloads(context, notifier),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          JuicyGlassCard(
            padding: const EdgeInsets.all(12),
            borderRadius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.library_books_rounded, size: 14, color: ScholarlyTheme.accentBlue),
                    const SizedBox(width: 4),
                    Text(
                      'AVAILABLE SAVED GAMES (${availableGames.length})',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: ScholarlyTheme.accentBlue,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                availableGames.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        child: Text(
                          'No available saved games to pull.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: ScholarlyTheme.textMuted,
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: availableGames.length,
                        separatorBuilder: (context, index) => Divider(
                          color: ScholarlyTheme.panelStroke.withValues(alpha: 0.4),
                          height: 16,
                        ),
                        itemBuilder: (context, index) {
                          final g = availableGames[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              g.customName != null && g.customName!.isNotEmpty ? g.customName! : 'Saved Game #${g.id.substring(0, 4)}',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary),
                            ),
                            subtitle: Text(
                              'Moves: ${g.recentMoves.length} | FEN: ${g.fen.substring(0, 15)}...',
                              style: GoogleFonts.inter(fontSize: 10, color: ScholarlyTheme.textMuted),
                            ),
                            trailing: TextButton.icon(
                              icon: const Icon(Icons.download_rounded, size: 14),
                              label: const Text('Pull'),
                              onPressed: () {
                                notifier.loadGameEntry(g);
                                setState(() {
                                  _pulledGameIds.add(g.id);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Game loaded into study workspace!'), backgroundColor: Colors.green),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: JuicyGlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        borderRadius: 16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(fontSize: 10, color: ScholarlyTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importPgnFromFile(BuildContext context, StudyLabNotifier notifier) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pgn'],
      );
      if (result == null || result.files.single.path == null) return;

      final path = result.files.single.path!;
      final file = File(path);
      final pgnText = await file.readAsString();

      notifier.importPgn(pgnText);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PGN Imported Successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('PGN Import failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PGN Import failed: $e', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _exportPgnToDownloads(BuildContext context, StudyLabNotifier notifier) async {
    try {
      final pgnText = notifier.exportToPgn();
      if (pgnText.isEmpty || pgnText == '[]') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No moves to export!'), backgroundColor: Colors.orangeAccent),
        );
        return;
      }

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getDownloadsDirectory();
      }
      directory ??= await getApplicationDocumentsDirectory();

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final path = '${directory.path}/kingslayer_study_$timestamp.pgn';
      final file = File(path);
      await file.writeAsString(pgnText);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PGN exported to: $path', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('PGN Export failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PGN Export failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Widget _buildGameLibraryOverlayTab(
    BuildContext context,
    StudyLabState state,
    StudyLabNotifier notifier,
  ) {
    return FutureBuilder<List<rust_pgn.PgnGameRecord>>(
      future: notifier.loadGamesFromLibrary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data ?? const [];

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              JuicyGlassCard(
                padding: const EdgeInsets.all(12),
                borderRadius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SAVED STUDIES (${records.length})',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: ScholarlyTheme.accentBlue,
                            letterSpacing: 0.5,
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.save_outlined, size: 14),
                          label: const Text('Save Current'),
                          onPressed: () => _promptSaveStudyName(context, notifier),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    records.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(24),
                            alignment: Alignment.center,
                            child: Text(
                              'No studies saved yet. Tap "Save Current" to persist to SQLite database.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: ScholarlyTheme.textMuted,
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: records.length,
                            separatorBuilder: (context, index) => Divider(
                              color: ScholarlyTheme.panelStroke.withValues(alpha: 0.4),
                              height: 16,
                            ),
                            itemBuilder: (context, index) {
                              final record = records[index];
                              return Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: ScholarlyTheme.accentBlue.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.bookmark_added, color: ScholarlyTheme.accentBlue, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          record.header.event,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: ScholarlyTheme.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'ECO: ${record.header.eco} | Moves: ${record.movesPgn.split(' ').where((m) => m.isNotEmpty && !m.contains('.')).length}',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: ScholarlyTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.folder_open_rounded, color: ScholarlyTheme.accentBlue, size: 20),
                                    onPressed: () {
                                      notifier.loadPgnRecord(record);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Study "${record.header.event}" loaded!', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () async {
                                      // Note: Individual record deletion is not supported by the Rust bridge.
                                      // For now, show a confirmation to clear ALL studies.
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: ScholarlyTheme.panelBase,
                                          title: Text('Clear Library?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary)),
                                          content: Text('This will remove ALL saved studies from the library. Individual deletion is not yet supported.', style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 13)),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted))),
                                            FilledButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                                              child: Text('Clear All', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true) {
                                        await notifier.clearLibrary();
                                        setState(() {});
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Library cleared.'), backgroundColor: Colors.orangeAccent),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _promptSaveStudyName(BuildContext context, StudyLabNotifier notifier) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ScholarlyTheme.panelBase,
          title: Text('Save Current Study', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary)),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter study name (e.g. Ruy Lopez Study)',
              hintStyle: GoogleFonts.inter(color: ScholarlyTheme.textMuted),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ScholarlyTheme.accentBlue),
              onPressed: () async {
                if (controller.text.trim().isEmpty) return;
                await notifier.saveCurrentGameToLibrary(controller.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Study saved successfully!'), backgroundColor: Colors.green),
                  );
                }
              },
              child: Text('Save', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
