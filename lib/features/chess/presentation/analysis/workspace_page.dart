import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kingslayer_chess/src/rust/api/pgn_db.dart' as rust_pgn;
import 'package:archive/archive.dart';

import '../widgets/ambient_scaffold.dart';
import '../scholarly_theme.dart';
import '../../application/study_lab_provider.dart';
import '../../application/chess_provider.dart';
import '../../services/chess_sound_service.dart';
import '../../application/analysis_engine_controller.dart';
import '../../application/practice_lab_provider.dart';
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





  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studyLabProvider);
    final notifier = ref.read(studyLabProvider.notifier);

    String title = 'WORKSPACE';
    Widget overlayBody = const SizedBox.shrink();

    switch (_workspaceTabIndex) {
      case 0:
        title = 'IMPORT / EXPORT';
        overlayBody = _buildImpoExpoOverlayTab(context, state, notifier);
        break;
      case 1:
        title = 'GAME LIBRARY';
        overlayBody = _buildGameLibraryOverlayTab(context, state, notifier);
        break;
      case 2:
        title = 'SPARRING';
        overlayBody = const PracticeModePanel();
        break;
      case 3:
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
            if (_workspaceTabIndex == 2) {
              final practiceState = ref.read(practiceLabProvider);
              if (practiceState.isSessionActive) {
                final studyState = ref.read(studyLabProvider);
                ref.read(practiceLabProvider.notifier).endSession(studyState.activeFen);
                return;
              }
            }
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
        actions: _workspaceTabIndex == 3
            ? [
                Builder(
                  builder: (context) {
                    final engineState = ref.watch(analysisEngineControllerProvider);
                    final hasReport = engineState.classifications.isNotEmpty;
                    if (!hasReport || engineState.isAnalyzing) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: ScholarlyTheme.panelStroke),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.analytics_outlined,
                          color: ScholarlyTheme.textPrimary,
                          size: 20,
                        ),
                        tooltip: 'Re-Analyze Game',
                        onPressed: () {
                          final studyLabState = ref.read(studyLabProvider);
                          ref.read(analysisEngineControllerProvider.notifier).classifyFullGame(
                                studyLabState.nodes,
                                studyLabState.startFen,
                              );
                        },
                      ),
                    );
                  },
                ),
              ]
            : null,
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



  Widget _buildImpoExpoOverlayTab(
    BuildContext context,
    StudyLabState state,
    StudyLabNotifier notifier,
  ) {
    final chessState = ref.watch(chessProvider);
    final eligibleGames = chessState.savedGames.where((s) => s.recentMoves.isNotEmpty && s.isFavorite).toList();
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
                  onTap: () => _showExportSelectionDialog(context, notifier),
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
                    const Icon(Icons.favorite_rounded, size: 14, color: ScholarlyTheme.accentBlue),
                    const SizedBox(width: 4),
                    Text(
                      'GAMES TO PULL (${availableGames.length})',
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite_border_rounded,
                              size: 32,
                              color: ScholarlyTheme.textMuted.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Transfer few games to favorites to pull the game for analysis.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: ScholarlyTheme.textMuted,
                              ),
                            ),
                          ],
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
                              onPressed: () async {
                                notifier.loadGameEntry(g);
                                setState(() {
                                  _pulledGameIds.add(g.id);
                                });
                                final gameName = g.customName != null && g.customName!.isNotEmpty
                                    ? g.customName!
                                    : 'Saved Game #${g.id.substring(0, 4)}';
                                await notifier.saveCurrentGameToLibrary(gameName);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Game loaded into study workspace and library!'), backgroundColor: Colors.green),
                                  );
                                }
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

      final state = ref.read(studyLabProvider);
      final eventName = state.metadata.event.isNotEmpty 
          ? state.metadata.event 
          : 'Imported PGN Game';
      await notifier.saveCurrentGameToLibrary(eventName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PGN Imported and Saved to Library!'), backgroundColor: Colors.green),
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

  Future<void> _showExportSelectionDialog(BuildContext context, StudyLabNotifier notifier) async {
    final records = await notifier.loadGamesFromLibrary();
    if (records.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No saved studies in library to export! Please save a study first.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    final selectedIndices = <int>{};

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: ScholarlyTheme.panelBase,
              title: Text(
                'Select Studies to Export',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: ScholarlyTheme.textPrimary,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ListView.separated(
                  itemCount: records.length,
                  separatorBuilder: (c, idx) => const Divider(color: ScholarlyTheme.panelStroke, height: 1),
                  itemBuilder: (c, idx) {
                    final r = records[idx];
                    final isChecked = selectedIndices.contains(idx);
                    return CheckboxListTile(
                      activeColor: ScholarlyTheme.accentBlue,
                      title: Text(
                        r.header.event,
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: Text(
                        'ECO: ${r.header.eco} | White: ${r.header.white} | Black: ${r.header.black}',
                        style: GoogleFonts.inter(fontSize: 10, color: ScholarlyTheme.textMuted),
                      ),
                      value: isChecked,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            selectedIndices.add(idx);
                          } else {
                            selectedIndices.remove(idx);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ScholarlyTheme.accentBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: selectedIndices.isEmpty
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          final chosenRecords = selectedIndices.map((i) => records[i]).toList();
                          _performExport(context, chosenRecords);
                        },
                  child: Text(
                    'Export (${selectedIndices.length})',
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _performExport(BuildContext context, List<rust_pgn.PgnGameRecord> games) async {
    try {
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

      if (games.length == 1) {
        final record = games.first;
        final pgnText = rust_pgn.exportPgnWithHeaders(
          header: record.header,
          annotatedPgn: record.movesPgn,
        );

        final fileName = '${record.header.event.replaceAll(RegExp(r"[^\w\s\-]"), '_')}_$timestamp.pgn';
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(pgnText);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PGN exported to: ${file.path}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final archive = Archive();

        for (final record in games) {
          final pgnText = rust_pgn.exportPgnWithHeaders(
            header: record.header,
            annotatedPgn: record.movesPgn,
          );
          final pgnBytes = utf8.encode(pgnText);
          final safeName = '${record.header.event.replaceAll(RegExp(r"[^\w\s\-]"), '_')}.pgn';
          
          archive.addFile(
            ArchiveFile(
              safeName,
              pgnBytes.length,
              pgnBytes,
            ),
          );
        }

        final zipBytes = ZipEncoder().encode(archive);

        final zipFileName = 'kingslayer_export_$timestamp.zip';
        final file = File('${directory.path}/$zipFileName');
        await file.writeAsBytes(zipBytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exported ZIP containing ${games.length} PGNs to: ${file.path}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Export failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.redAccent),
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
                              return GameLibraryCardWidget(
                                record: record,
                                index: index,
                                notifier: notifier,
                                onRefresh: () => setState(() {}),
                                onEdit: _promptEditStudyHeaders,
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

  void _promptEditStudyHeaders(BuildContext context, StudyLabNotifier notifier, int index, rust_pgn.PgnGameRecord record) {
    final eventController = TextEditingController(text: record.header.event);
    final siteController = TextEditingController(text: record.header.site);
    final dateController = TextEditingController(text: record.header.date);
    final whiteController = TextEditingController(text: record.header.white);
    final blackController = TextEditingController(text: record.header.black);
    final whiteEloController = TextEditingController(text: record.header.whiteElo?.toString() ?? '');
    final blackEloController = TextEditingController(text: record.header.blackElo?.toString() ?? '');
    final resultController = TextEditingController(text: record.header.result);

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
            'Edit PGN Headers',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: ScholarlyTheme.textPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogField(eventController, 'Event / Name'),
                _buildDialogField(siteController, 'Site'),
                _buildDialogField(dateController, 'Date (YYYY.MM.DD)'),
                _buildDialogField(whiteController, 'White Player'),
                _buildDialogField(whiteEloController, 'White Elo', isNumeric: true),
                _buildDialogField(blackController, 'Black Player'),
                _buildDialogField(blackEloController, 'Black Elo', isNumeric: true),
                _buildDialogField(resultController, 'Result (*, 1-0, 0-1, 1/2-1/2)'),
              ],
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
              onPressed: () async {
                final newHeader = rust_pgn.PgnGameHeader(
                  event: eventController.text.trim().isEmpty ? 'Study' : eventController.text.trim(),
                  site: siteController.text.trim(),
                  date: dateController.text.trim(),
                  white: whiteController.text.trim(),
                  black: blackController.text.trim(),
                  whiteElo: int.tryParse(whiteEloController.text.trim()),
                  blackElo: int.tryParse(blackEloController.text.trim()),
                  result: resultController.text.trim(),
                  eco: record.header.eco,
                  opening: record.header.opening,
                );

                await notifier.updateStudyHeadersInLibrary(index, newHeader);
                if (context.mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PGN headers updated successfully!'), backgroundColor: Colors.green),
                  );
                }
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

  Widget _buildDialogField(TextEditingController controller, String label, {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(color: ScholarlyTheme.textMuted),
          filled: true,
          fillColor: ScholarlyTheme.panelBase,
          border: const OutlineInputBorder(),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: ScholarlyTheme.panelStroke),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: ScholarlyTheme.accentBlue),
          ),
        ),
      ),
    );
  }
}

class GameLibraryCardWidget extends StatefulWidget {
  final rust_pgn.PgnGameRecord record;
  final int index;
  final StudyLabNotifier notifier;
  final VoidCallback onRefresh;
  final void Function(BuildContext, StudyLabNotifier, int, rust_pgn.PgnGameRecord) onEdit;

  const GameLibraryCardWidget({
    super.key,
    required this.record,
    required this.index,
    required this.notifier,
    required this.onRefresh,
    required this.onEdit,
  });

  @override
  State<GameLibraryCardWidget> createState() => _GameLibraryCardWidgetState();
}

class _GameLibraryCardWidgetState extends State<GameLibraryCardWidget>
    with SingleTickerProviderStateMixin {
  bool _showDeleteBin = false;
  late AnimationController _animController;
  late Animation<double> _flipAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _flipAnimation = Tween<double>(begin: -math.pi / 2, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleDeleteBin() {
    setState(() {
      _showDeleteBin = !_showDeleteBin;
      if (_showDeleteBin) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  String _buildDetailsText() {
    final hasWhite = widget.record.header.white.isNotEmpty && widget.record.header.white != '?';
    final hasBlack = widget.record.header.black.isNotEmpty && widget.record.header.black != '?';
    final moveCount = widget.record.movesPgn.split(' ').where((m) => m.isNotEmpty && !m.contains('.')).length;
    
    String details = '';
    if (hasWhite || hasBlack) {
      final wName = hasWhite ? widget.record.header.white : 'Unknown';
      final bName = hasBlack ? widget.record.header.black : 'Unknown';
      details += '$wName vs $bName';
      if (widget.record.header.result.isNotEmpty && widget.record.header.result != '?') {
        details += ' (${widget.record.header.result})';
      }
      details += ' | ';
    }
    
    details += 'Moves: $moveCount';
    
    if (widget.record.header.eco.isNotEmpty && widget.record.header.eco != '?') {
      details += ' | ECO: ${widget.record.header.eco}';
    }
    if (widget.record.header.date.isNotEmpty && widget.record.header.date != '?') {
      details += ' | ${widget.record.header.date}';
    }
    return details;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background track (revealed during swipe)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3), width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Release to delete...',
                  style: GoogleFonts.inter(
                    color: Colors.redAccent, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // The swipable card
        Dismissible(
          key: ValueKey('library-game-${widget.record.index}-${widget.index}'),
          direction: _showDeleteBin ? DismissDirection.startToEnd : DismissDirection.none,
          onDismissed: (_) async {
            // Handled in confirmDismiss
          },
          confirmDismiss: (direction) async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: ScholarlyTheme.panelBase,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: ScholarlyTheme.panelStroke, width: 1.5),
                ),
                title: Text(
                  'Delete Study?',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary),
                ),
                content: Text(
                  'Are you sure you want to delete "${widget.record.header.event}" from your library? This cannot be undone.',
                  style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 13),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('Cancel', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted)),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                    child: Text('Delete', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              final ok = await widget.notifier.deleteStudyFromLibrary(widget.index);
              if (ok) {
                widget.onRefresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Study deleted successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                return true;
              }
            }
            
            // Cancel swipe and hide bin
            setState(() {
              _showDeleteBin = false;
              _animController.reverse();
            });
            return false;
          },
          child: GestureDetector(
            onLongPress: _toggleDeleteBin,
            onTap: () {
              if (!_showDeleteBin) {
                widget.notifier.loadPgnRecord(widget.record);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Study "${widget.record.header.event}" loaded!', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                }
              } else {
                _toggleDeleteBin();
              }
            },
            child: JuicyGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              borderRadius: 12,
              borderColor: _showDeleteBin 
                  ? Colors.redAccent.withValues(alpha: 0.5) 
                  : ScholarlyTheme.panelStroke.withValues(alpha: 0.3),
              child: Row(
                children: [
                  if (_showDeleteBin) ...[
                    const Icon(Icons.arrow_forward_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Flip right to delete',
                      style: GoogleFonts.inter(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ] else ...[
                    // Metadata Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.record.header.event,
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
                            _buildDetailsText(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: ScholarlyTheme.textMuted,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Action buttons: Open & Edit (Always clean and premium)
                    IconButton(
                      icon: const Icon(Icons.folder_open_rounded, color: ScholarlyTheme.accentBlue, size: 20),
                      tooltip: 'Open Study',
                      onPressed: () {
                        widget.notifier.loadPgnRecord(widget.record);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Study "${widget.record.header.event}" loaded!', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.teal, size: 20),
                      tooltip: 'Edit Headers',
                      onPressed: () => widget.onEdit(context, widget.notifier, widget.index, widget.record),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Flip-right trash bin overlay (anchored to the right)
        if (_showDeleteBin)
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                // Y-rotation flip animation: -pi/2 (90deg, flat/orthogonal) to 0 (0deg, facing forward)
                final angle = _flipAnimation.value;
                // Fade in based on slide animation
                final opacity = _slideAnimation.value;
                // Scale effect
                final scale = 0.5 + (0.5 * _slideAnimation.value);

                return Opacity(
                  opacity: opacity,
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.002) // Perspective depth
                      ..rotateY(angle)
                      ..scaleByDouble(scale, scale, 1.0, 1.0),
                    alignment: Alignment.centerRight,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.redAccent, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.2),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.delete_forever_rounded,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

