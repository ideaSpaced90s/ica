import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class UpdateService {
  static const String _configUrl = "https://raw.githubusercontent.com/ideaSpaced90s/ica-updates/main/version.json";

  static final UpdateService instance = UpdateService._internal();
  UpdateService._internal();

  /// Checks if an update is available.
  /// On Android, queries Google Play Services.
  /// On iOS/fallback, queries a remote JSON configuration.
  Future<Map<String, dynamic>> checkUpdateStatus() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final int currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
    final String currentVersion = packageInfo.version;

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final updateInfo = await InAppUpdate.checkForUpdate();
        final bool isAvailable = updateInfo.updateAvailability == UpdateAvailability.updateAvailable;
        return {
          'hasUpdate': isAvailable,
          'latestVersion': updateInfo.availableVersionCode?.toString() ?? '',
          'isImmediate': updateInfo.immediateUpdateAllowed,
          'isFlexible': updateInfo.flexibleUpdateAllowed,
          'storeUrl': null,
        };
      } catch (e) {
        debugPrint('Android native in-app update check failed, falling back: $e');
      }
    }

    // iOS and Fallback Check
    try {
      final response = await http.get(Uri.parse(_configUrl)).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final int remoteBuildNumber = data['latest_version_code'] ?? 0;
        final String remoteVersionName = data['latest_version_name'] ?? currentVersion;
        final String storeUrl = Platform.isIOS ? (data['store_url_ios'] ?? '') : (data['store_url_android'] ?? '');

        final bool hasUpdate = remoteBuildNumber > currentBuildNumber;
        return {
          'hasUpdate': hasUpdate,
          'latestVersion': remoteVersionName,
          'isImmediate': false,
          'isFlexible': true,
          'storeUrl': storeUrl,
        };
      }
    } catch (e) {
      debugPrint('Update check fallback HTTP request failed: $e');
    }

    return {
      'hasUpdate': false,
      'latestVersion': currentVersion,
      'isImmediate': false,
      'isFlexible': false,
      'storeUrl': null,
    };
  }

  /// Starts a flexible update. Only supported on Android.
  Future<void> startFlexibleUpdate() async {
    if (!kIsWeb && Platform.isAndroid) {
      await InAppUpdate.startFlexibleUpdate();
    } else {
      throw UnsupportedError('In-app background download is only supported on Android.');
    }
  }

  /// Completes a flexible update by restarting the app. Only supported on Android.
  Future<void> completeFlexibleUpdate() async {
    if (!kIsWeb && Platform.isAndroid) {
      await InAppUpdate.completeFlexibleUpdate();
    } else {
      throw UnsupportedError('Restarting to update is only supported on Android.');
    }
  }

  /// Launches the App Store page.
  Future<void> launchStore(String storeUrl) async {
    final uri = Uri.parse(storeUrl);
    if (kIsWeb || await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch store URL: $storeUrl';
    }
  }
}
