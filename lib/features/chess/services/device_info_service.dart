import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DeviceInfoService {
  static const _channel = MethodChannel('com.dsamok.ideaspacechess/device_info');

  /// Determines whether the app should lock to portrait mode.
  /// True for standard mobile devices (phones/tablets), false for desktop environments
  /// including Google Play Games on PC, Web, and desktop native platforms.
  static Future<bool> shouldLockPortrait() async {
    if (kIsWeb) return false;
    
    // Desktop native (Windows/macOS/Linux) shouldn't be locked to portrait
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return false;
    }

    if (Platform.isAndroid) {
      try {
        final bool isPlayGamesPC = await _channel.invokeMethod('isPlayGamesPC');
        // If it is running on Google Play Games on PC, do NOT lock portrait
        return !isPlayGamesPC;
      } catch (e) {
        // Fallback: Default to locking portrait on Android mobile
        return true;
      }
    }

    // Lock portrait on iOS mobile/tablet by default
    if (Platform.isIOS) {
      return true;
    }

    return false;
  }
}
