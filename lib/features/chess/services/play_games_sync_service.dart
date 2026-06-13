import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:games_services/games_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';
import '../application/chess_provider.dart';

/// Sync statuses for Play Games UI integration.
enum PlayGamesSyncStatus { idle, syncing, success, error }

/// Represents the state of the Play Games Cloud Sync process.
class PlayGamesSyncState {
  final PlayGamesSyncStatus status;
  final String? errorMessage;
  final DateTime? lastSyncedAt;

  PlayGamesSyncState({
    this.status = PlayGamesSyncStatus.idle,
    this.errorMessage,
    this.lastSyncedAt,
  });

  PlayGamesSyncState copyWith({
    PlayGamesSyncStatus? status,
    String? errorMessage,
    DateTime? lastSyncedAt,
  }) {
    return PlayGamesSyncState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

/// StateNotifier to manage sync triggers, automatic debounce, and progress states.
class PlayGamesSyncNotifier extends StateNotifier<PlayGamesSyncState> {
  final Ref _ref;
  DateTime? _lastBackupRequestTime;

  PlayGamesSyncNotifier(this._ref) : super(PlayGamesSyncState());

  /// Triggers backup of local settings and progress files to Play Games Cloud Save (Saved Games).
  /// If [silent] is true, errors and states are updated, but it won't force UI loading indicators.
  Future<bool> backup({bool silent = false}) async {
    final authService = _ref.read(authServiceProvider);
    
    // Skip if user is not signed in
    if (authService.currentUser == null) {
      debugPrint("Play Games Sync: User not signed in, skipping automatic backup");
      return false;
    }

    // Debounce checks for rapid successive changes (e.g. within 2 seconds)
    final now = DateTime.now();
    if (_lastBackupRequestTime != null && now.difference(_lastBackupRequestTime!).inSeconds < 2) {
      debugPrint("Play Games Sync: Debounced backup request");
      return false;
    }
    _lastBackupRequestTime = now;

    if (!silent) {
      state = state.copyWith(status: PlayGamesSyncStatus.syncing);
    }

    try {
      final supportDir = await getApplicationSupportDirectory();
      final docDir = await getApplicationDocumentsDirectory();

      final filesToSync = {
        'app_settings': p.join(supportDir.path, 'app_settings.json'),
        'assignment_settings': p.join(supportDir.path, 'assignment_settings.json'),
        'saved_games': p.join(docDir.path, 'saved_games.json'),
        'performance_ledger': p.join(docDir.path, 'performance_ledger.json'),
      };

      final Map<String, String> payload = {};
      for (final entry in filesToSync.entries) {
        final file = File(entry.value);
        if (await file.exists()) {
          payload[entry.key] = await file.readAsString();
        }
      }

      final String jsonString = jsonEncode(payload);

      // Save to Play Games cloud save slot
      await SaveGame.saveGame(
        data: jsonString,
        name: 'kingslayer_chess_save',
      );

      state = state.copyWith(
        status: PlayGamesSyncStatus.success,
        lastSyncedAt: DateTime.now(),
      );
      return true;
    } catch (e) {
      debugPrint("Play Games Sync Backup Error: $e");
      state = state.copyWith(
        status: PlayGamesSyncStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Triggers restore of settings and progress files from Play Games Cloud Save.
  Future<bool> restore() async {
    final authService = _ref.read(authServiceProvider);
    
    if (authService.currentUser == null) {
      debugPrint("Play Games Sync: User not signed in, skipping restore");
      return false;
    }

    state = state.copyWith(status: PlayGamesSyncStatus.syncing);

    try {
      final String? data = await SaveGame.loadGame(name: 'kingslayer_chess_save');
      
      if (data != null && data.isNotEmpty) {
        final Map<String, dynamic> payload = jsonDecode(data);
        final supportDir = await getApplicationSupportDirectory();
        final docDir = await getApplicationDocumentsDirectory();

        final filesToSync = {
          'app_settings': p.join(supportDir.path, 'app_settings.json'),
          'assignment_settings': p.join(supportDir.path, 'assignment_settings.json'),
          'saved_games': p.join(docDir.path, 'saved_games.json'),
          'performance_ledger': p.join(docDir.path, 'performance_ledger.json'),
        };

        for (final entry in filesToSync.entries) {
          if (payload.containsKey(entry.key)) {
            final file = File(entry.value);
            await file.parent.create(recursive: true);
            await file.writeAsString(payload[entry.key]!);
          }
        }

        // Reload settings provider so the UI shows the restored settings immediately
        await _ref.read(chessProvider.notifier).reloadSettings();
      }

      state = state.copyWith(
        status: PlayGamesSyncStatus.success,
        lastSyncedAt: DateTime.now(),
      );
      return true;
    } catch (e) {
      debugPrint("Play Games Sync Restore Error: $e");
      state = state.copyWith(
        status: PlayGamesSyncStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

/// Global StateNotifierProvider for PlayGamesSync State.
final playGamesSyncProvider =
    StateNotifierProvider<PlayGamesSyncNotifier, PlayGamesSyncState>((ref) {
  return PlayGamesSyncNotifier(ref);
});

// Alias to avoid breaking googleDriveSyncProvider references initially (can be removed later)
final googleDriveSyncProvider = playGamesSyncProvider;
typedef GoogleDriveSyncStatus = PlayGamesSyncStatus;
typedef GoogleDriveSyncState = PlayGamesSyncState;
typedef GoogleDriveSyncNotifier = PlayGamesSyncNotifier;
