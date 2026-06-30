import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/update_service.dart';

enum UpdateCheckStatus { idle, checking, upToDate, updateAvailable, downloading, downloadCompleted, error }

class UpdateState {
  final UpdateCheckStatus status;
  final bool hasUpdateBadge;
  final String currentVersion;
  final String latestVersion;
  final String? storeUrl;
  final double downloadProgress; // Value between 0.0 and 1.0

  const UpdateState({
    this.status = UpdateCheckStatus.idle,
    this.hasUpdateBadge = false,
    this.currentVersion = '',
    this.latestVersion = '',
    this.storeUrl,
    this.downloadProgress = 0.0,
  });

  UpdateState copyWith({
    UpdateCheckStatus? status,
    bool? hasUpdateBadge,
    String? currentVersion,
    String? latestVersion,
    String? storeUrl,
    double? downloadProgress,
  }) {
    return UpdateState(
      status: status ?? this.status,
      hasUpdateBadge: hasUpdateBadge ?? this.hasUpdateBadge,
      currentVersion: currentVersion ?? this.currentVersion,
      latestVersion: latestVersion ?? this.latestVersion,
      storeUrl: storeUrl ?? this.storeUrl,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }
}

class UpdateNotifier extends Notifier<UpdateState> {
  @override
  UpdateState build() {
    Future.microtask(() => checkSilentUpdate());
    return const UpdateState();
  }

  /// Runs a silent check in the background on app start.
  /// If an update is available, sets [hasUpdateBadge] to true.
  Future<void> checkSilentUpdate() async {
    try {
      final statusMap = await UpdateService.instance.checkUpdateStatus();
      final packageInfo = await PackageInfo.fromPlatform();

      state = state.copyWith(
        currentVersion: packageInfo.version,
        latestVersion: statusMap['latestVersion'] ?? '',
        hasUpdateBadge: statusMap['hasUpdate'] ?? false,
        storeUrl: statusMap['storeUrl'],
      );
    } catch (e) {
      debugPrint('Silent update check error: $e');
    }
  }

  /// Triggered manually by clicking the "Check for Updates" button.
  /// Simulates a 1.5s premium loading delay before resolving.
  Future<void> triggerManualCheck() async {
    if (state.status == UpdateCheckStatus.checking) return;

    state = state.copyWith(status: UpdateCheckStatus.checking);

    // Premium interactive animation delay
    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      final statusMap = await UpdateService.instance.checkUpdateStatus();
      final packageInfo = await PackageInfo.fromPlatform();
      final bool hasUpdate = statusMap['hasUpdate'] ?? false;

      state = state.copyWith(
        status: hasUpdate ? UpdateCheckStatus.updateAvailable : UpdateCheckStatus.upToDate,
        hasUpdateBadge: hasUpdate,
        currentVersion: packageInfo.version,
        latestVersion: statusMap['latestVersion'] ?? '',
        storeUrl: statusMap['storeUrl'],
      );
    } catch (e) {
      state = state.copyWith(status: UpdateCheckStatus.error);
    }
  }

  /// Launches in-app download on Android or launches store on iOS.
  Future<void> startInAppDownload() async {
    // If not Android or running web, we redirect via URL
    if (kIsWeb || !Platform.isAndroid) {
      if (state.storeUrl != null) {
        await UpdateService.instance.launchStore(state.storeUrl!);
      } else {
        // Fallback store redirect
        final fallbackUrl = Platform.isIOS 
            ? 'https://apps.apple.com/app/idYOUR_APP_ID'
            : 'https://play.google.com/store/apps/details?id=com.kingslayer.chess';
        await UpdateService.instance.launchStore(fallbackUrl);
      }
      return;
    }

    // Android: run native flexible in-app update
    state = state.copyWith(
      status: UpdateCheckStatus.downloading,
      downloadProgress: 0.0,
    );

    Timer? progressTimer;
    try {
      // Simulate progress bar movement while Google Play Core is downloading in the background
      double progress = 0.0;
      progressTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
        progress += 0.04;
        if (progress >= 0.96) {
          progress = 0.96; // Wait for Play Core to complete
          timer.cancel();
        }
        state = state.copyWith(downloadProgress: progress);
      });

      await UpdateService.instance.startFlexibleUpdate();

      progressTimer.cancel();
      state = state.copyWith(
        status: UpdateCheckStatus.downloadCompleted,
        downloadProgress: 1.0,
      );
    } catch (e) {
      progressTimer?.cancel();
      state = state.copyWith(status: UpdateCheckStatus.error);
      debugPrint('Flexible update failed: $e');
    }
  }

  /// Completes the flexible update and restarts the app to apply.
  Future<void> completeFlexibleUpdate() async {
    try {
      await UpdateService.instance.completeFlexibleUpdate();
    } catch (e) {
      debugPrint('Restart to install update failed: $e');
    }
  }

  /// Mocks a successful check for updates (useful for verification and UI demo).
  void debugMockUpdateAvailable(String version, String storeUrl) {
    state = state.copyWith(
      status: UpdateCheckStatus.updateAvailable,
      hasUpdateBadge: true,
      latestVersion: version,
      storeUrl: storeUrl,
    );
  }
}

final updateProvider = NotifierProvider<UpdateNotifier, UpdateState>(UpdateNotifier.new);
