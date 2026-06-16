import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'auth_service.dart';
import '../application/chess_provider.dart';

/// Sync statuses for UI integration.
enum CloudSyncStatus { idle, syncing, success, error }

/// Represents the state of the Cloud Sync process.
class CloudSyncState {
  final CloudSyncStatus status;
  final String? errorMessage;
  final DateTime? lastSyncedAt;

  CloudSyncState({
    this.status = CloudSyncStatus.idle,
    this.errorMessage,
    this.lastSyncedAt,
  });

  CloudSyncState copyWith({
    CloudSyncStatus? status,
    String? errorMessage,
    DateTime? lastSyncedAt,
  }) {
    return CloudSyncState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

/// StateNotifier to manage sync triggers, automatic debounce, and progress states.
class CloudSyncNotifier extends StateNotifier<CloudSyncState> {
  final Ref _ref;
  DateTime? _lastBackupRequestTime;

  CloudSyncNotifier(this._ref) : super(CloudSyncState());

  /// Triggers backup of local settings and progress files to Firebase Storage.
  Future<bool> backup({bool silent = false}) async {
    final authService = _ref.read(authServiceProvider);
    
    // Skip if user is not signed in
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      debugPrint("Cloud Sync: User not signed in, skipping automatic backup");
      return false;
    }

    // Debounce checks for rapid successive changes
    final now = DateTime.now();
    if (_lastBackupRequestTime != null && now.difference(_lastBackupRequestTime!).inSeconds < 2) {
      debugPrint("Cloud Sync: Debounced backup request");
      return false;
    }
    _lastBackupRequestTime = now;

    if (!silent) {
      state = state.copyWith(status: CloudSyncStatus.syncing);
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

      final storageRef = FirebaseStorage.instance.ref();
      final userSaveRef = storageRef.child("users/${currentUser.uid}/kingslayer_chess_save.json");

      // Upload payload as string
      await userSaveRef.putString(
        jsonString,
        format: PutStringFormat.raw,
        metadata: SettableMetadata(contentType: 'application/json'),
      );

      debugPrint("Cloud Sync: Successfully backed up data to Firebase Storage");

      state = state.copyWith(
        status: CloudSyncStatus.success,
        lastSyncedAt: DateTime.now(),
      );
      return true;
    } catch (e) {
      debugPrint("Cloud Sync Backup Error: $e");
      state = state.copyWith(
        status: CloudSyncStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Triggers restore of settings and progress files from Firebase Storage.
  Future<bool> restore() async {
    final authService = _ref.read(authServiceProvider);
    
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      debugPrint("Cloud Sync: User not signed in, skipping restore");
      return false;
    }

    state = state.copyWith(status: CloudSyncStatus.syncing);

    try {
      final storageRef = FirebaseStorage.instance.ref();
      final userSaveRef = storageRef.child("users/${currentUser.uid}/kingslayer_chess_save.json");

      String? data;
      try {
        final Uint8List? bytes = await userSaveRef.getData();
        if (bytes != null) {
          data = utf8.decode(bytes);
          debugPrint("Cloud Sync: Successfully loaded backup from Firebase Storage");
        }
      } on FirebaseException catch (e) {
        // If the file does not exist, treat it as a successful restore of nothing (clean install)
        if (e.code == 'object-not-found') {
          debugPrint("Cloud Sync Restore: No backup file found for user, skipping restore steps.");
          state = state.copyWith(
            status: CloudSyncStatus.success,
            lastSyncedAt: DateTime.now(),
          );
          return true;
        }
        rethrow;
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
        status: CloudSyncStatus.success,
        lastSyncedAt: DateTime.now(),
      );
      return true;
    } catch (e) {
      debugPrint("Cloud Sync Restore Error: $e");
      state = state.copyWith(
        status: CloudSyncStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

/// Global StateNotifierProvider for CloudSync State.
final cloudSyncProvider =
    StateNotifierProvider<CloudSyncNotifier, CloudSyncState>((ref) {
  return CloudSyncNotifier(ref);
});

// Alias to avoid breaking googleDriveSyncProvider references initially (can be removed later)
final googleDriveSyncProvider = cloudSyncProvider;
typedef GoogleDriveSyncStatus = CloudSyncStatus;
typedef GoogleDriveSyncState = CloudSyncState;
typedef GoogleDriveSyncNotifier = CloudSyncNotifier;
