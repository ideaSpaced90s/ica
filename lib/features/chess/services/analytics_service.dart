import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Logs a screen view to Firebase Analytics.
  Future<void> logScreenView({required String screenName, String? screenClass}) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
      debugPrint('Analytics: Screen View logged: $screenName');
    } catch (e, stack) {
      debugPrint('Analytics Error logScreenView: $e\n$stack');
    }
  }

  /// Logs a custom event to Firebase Analytics.
  Future<void> logEvent({required String name, Map<String, Object>? parameters}) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
      debugPrint('Analytics: Event logged: $name with parameters: $parameters');
    } catch (e, stack) {
      debugPrint('Analytics Error logEvent: $e\n$stack');
    }
  }

  /// Logs how much time (in seconds) the user spent in a particular section.
  Future<void> logTimeSpent({required String sectionName, required int durationSeconds}) async {
    await logEvent(
      name: 'time_spent_in_section',
      parameters: {
        'section_name': sectionName,
        'duration_seconds': durationSeconds,
      },
    );
  }

  /// Sets a persistent user property.
  Future<void> setUserProperty({required String name, required String? value}) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      debugPrint('Analytics: User Property set: $name = $value');
    } catch (e, stack) {
      debugPrint('Analytics Error setUserProperty: $e\n$stack');
    }
  }
}

final analyticsServiceProvider = Provider((ref) => AnalyticsService());
