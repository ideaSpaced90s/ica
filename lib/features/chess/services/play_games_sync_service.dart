import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../application/chess_provider.dart';

/// Sync statuses for UI integration.
enum PlayGamesSyncStatus { idle, syncing, success, error }

/// Represents the state of the Cloud Sync process.
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

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

/// StateNotifier to manage sync triggers, automatic debounce, and progress states.
class PlayGamesSyncNotifier extends StateNotifier<PlayGamesSyncState> {
  final Ref _ref;
  DateTime? _lastBackupRequestTime;

  PlayGamesSyncNotifier(this._ref) : super(PlayGamesSyncState());

  /// Triggers backup of local settings and progress files to Google Drive appDataFolder.
  Future<bool> backup({bool silent = false}) async {
    final authService = _ref.read(authServiceProvider);
    
    // Skip if user is not signed in
    if (authService.currentUser == null) {
      debugPrint("Google Drive Sync: User not signed in, skipping automatic backup");
      return false;
    }

    // Debounce checks for rapid successive changes
    final now = DateTime.now();
    if (_lastBackupRequestTime != null && now.difference(_lastBackupRequestTime!).inSeconds < 2) {
      debugPrint("Google Drive Sync: Debounced backup request");
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

      final googleUser = authService.googleSignIn.currentUser ?? 
          await authService.googleSignIn.signInSilently();
      if (googleUser == null) {
        throw Exception("Failed to get Google Sign-In user for Drive Sync");
      }
      
      final authHeaders = await googleUser.authHeaders;
      final client = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(client);

      final fileList = await driveApi.files.list(
        q: "name = 'kingslayer_chess_save.json' and 'appDataFolder' in parents and trashed = false",
        spaces: 'appDataFolder',
      );

      final media = drive.Media(
        Stream.value(utf8.encode(jsonString)),
        jsonString.length,
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        final fileId = fileList.files!.first.id!;
        await driveApi.files.update(
          drive.File(),
          fileId,
          uploadMedia: media,
        );
        debugPrint("Google Drive Sync: Successfully updated existing backup");
      } else {
        final driveFile = drive.File()
          ..name = 'kingslayer_chess_save.json'
          ..parents = ['appDataFolder'];
        await driveApi.files.create(
          driveFile,
          uploadMedia: media,
        );
        debugPrint("Google Drive Sync: Successfully created new backup");
      }

      state = state.copyWith(
        status: PlayGamesSyncStatus.success,
        lastSyncedAt: DateTime.now(),
      );
      return true;
    } catch (e) {
      debugPrint("Google Drive Sync Backup Error: $e");
      state = state.copyWith(
        status: PlayGamesSyncStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Triggers restore of settings and progress files from Google Drive appDataFolder.
  Future<bool> restore() async {
    final authService = _ref.read(authServiceProvider);
    
    if (authService.currentUser == null) {
      debugPrint("Google Drive Sync: User not signed in, skipping restore");
      return false;
    }

    state = state.copyWith(status: PlayGamesSyncStatus.syncing);

    try {
      String? data;
      final googleUser = authService.googleSignIn.currentUser ?? 
          await authService.googleSignIn.signInSilently();
      if (googleUser == null) {
        throw Exception("Failed to get Google Sign-In user for Drive Sync");
      }

      final authHeaders = await googleUser.authHeaders;
      final client = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(client);

      final fileList = await driveApi.files.list(
        q: "name = 'kingslayer_chess_save.json' and 'appDataFolder' in parents and trashed = false",
        spaces: 'appDataFolder',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        final fileId = fileList.files!.first.id!;
        final media = await driveApi.files.get(
          fileId,
          downloadOptions: drive.DownloadOptions.fullMedia,
        ) as drive.Media;

        final List<int> bytes = [];
        await for (final chunk in media.stream) {
          bytes.addAll(chunk);
        }
        data = utf8.decode(bytes);
        debugPrint("Google Drive Sync: Successfully loaded backup from Drive");
      }
      
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
      debugPrint("Google Drive Sync Restore Error: $e");
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
