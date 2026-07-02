import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import '../application/navigation_provider.dart';

final notificationServiceProvider = Provider((ref) => NotificationService(ref));

class NotificationService {
  final Ref ref;
  
  // Singleton instance of Flutter Local Notifications (Android)
  final FlutterLocalNotificationsPlugin _androidNotifications = FlutterLocalNotificationsPlugin();

  NotificationService(this.ref);

  /// Initialise notifications for the current platform
  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    try {
      final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Failed to initialize local timezone, falling back to UTC: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _androidNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        ref.read(mobileNavIndexProvider.notifier).state = 0; // Route to Dashboard (0)
      },
    );
  }

  /// Show an immediate notification (works on Android and Windows)
  Future<void> showImmediateNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'immediate_alerts',
      'Immediate Alerts',
      channelDescription: 'Real-time achievement and lesson notifications',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    
    await _androidNotifications.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  /// Cancel all scheduled alarms
  Future<void> cancelAllNotifications() async {
    await _androidNotifications.cancelAll();
  }

  /// Schedule the daily briefing at a specific time (Android only)
  Future<void> scheduleDailyBriefing(
    String timeStr, {
    required bool quietHoursEnabled,
    required String quietHoursStart,
    required String quietHoursEnd,
  }) async {

    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) return;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      var scheduledTime = _nextInstanceOfTime(hour, minute);
      scheduledTime = _applyQuietHours(
        scheduledTime,
        quietHoursEnabled,
        quietHoursStart,
        quietHoursEnd,
      );

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'daily_briefings',
        'Daily Briefings',
        channelDescription: 'Scheduled morning assignments reminders',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      await _androidNotifications.zonedSchedule(
        1001, // Daily Brief ID
        'Today\'s Chess Assignments',
        'Your daily chess training schedule from GM Chanakya is ready. Tap to view your desk.',
        scheduledTime,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Failed to schedule daily briefing notification: $e');
    }
  }

  /// Schedule the evening streak protection reminder (Android only)
  /// Calculates alert time based on warning hours before midnight (e.g. 4 hours = 8:00 PM)
  Future<void> scheduleStreakProtection(
    int hoursBeforeReset, {
    required bool quietHoursEnabled,
    required String quietHoursStart,
    required String quietHoursEnd,
  }) async {

    try {
      final hour = 24 - hoursBeforeReset;
      if (hour < 0 || hour >= 24) return;

      var scheduledTime = _nextInstanceOfTime(hour, 0);
      scheduledTime = _applyQuietHours(
        scheduledTime,
        quietHoursEnabled,
        quietHoursStart,
        quietHoursEnd,
      );

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'streak_protection',
        'Streak Protection',
        channelDescription: 'Warning alerts for pending daily assignments',
        importance: Importance.high,
        priority: Priority.high,
      );

      await _androidNotifications.zonedSchedule(
        1002, // Streak Protection ID
        'Streak Alert! ⏳',
        'Don\'t let your training streak fade. You have uncompleted daily tasks remaining.',
        scheduledTime,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Failed to schedule streak protection notification: $e');
    }
  }

  /// Schedule the weekly diagnostic briefing on Sundays at 9:00 AM (Android only)
  Future<void> scheduleWeeklyDiagnostics({
    required bool quietHoursEnabled,
    required String quietHoursStart,
    required String quietHoursEnd,
  }) async {
    try {
      var scheduledTime = _nextInstanceOfSundayNineAM();
      scheduledTime = _applyQuietHours(
        scheduledTime,
        quietHoursEnabled,
        quietHoursStart,
        quietHoursEnd,
      );

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'weekly_diagnostics',
        'Weekly Diagnostics',
        channelDescription: 'GM Chanakya\'s weekly diagnostic analysis briefings',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      await _androidNotifications.zonedSchedule(
        1003, // Weekly Diagnostics ID
        'Weekly Diagnostics Report',
        'GM Chanakya has finished analyzing your games. Tap to view your diagnostic report.',
        scheduledTime,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      debugPrint('Failed to schedule weekly diagnostics notification: $e');
    }
  }

  /// Show an immediate milestone notification (works on Android and Windows)
  Future<void> showMilestoneNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'milestones',
      'Milestones & Triumphs',
      channelDescription: 'Real-time rating milestones and island landfall notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    
    await _androidNotifications.show(
      1004, // Milestone ID
      title,
      body,
      platformChannelSpecifics,
    );
  }

  /// Helper to calculate the next occurrence of Sunday 9:00 AM in local timezone
  tz.TZDateTime _nextInstanceOfSundayNineAM() {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(9, 0);
    while (scheduledDate.weekday != DateTime.sunday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Checks if a time is within quiet hours and shifts it forward to the end of quiet hours if it is.
  tz.TZDateTime _applyQuietHours(
    tz.TZDateTime scheduledTime,
    bool quietHoursEnabled,
    String quietHoursStart,
    String quietHoursEnd,
  ) {
    if (!quietHoursEnabled) return scheduledTime;

    try {
      final startParts = quietHoursStart.split(':');
      final endParts = quietHoursEnd.split(':');
      if (startParts.length != 2 || endParts.length != 2) return scheduledTime;

      final startHour = int.parse(startParts[0]);
      final startMin = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMin = int.parse(endParts[1]);


      tz.TZDateTime qEnd = tz.TZDateTime(
        tz.local,
        scheduledTime.year,
        scheduledTime.month,
        scheduledTime.day,
        endHour,
        endMin,
      );

      bool isInside = false;
      final schedMinOfDay = scheduledTime.hour * 60 + scheduledTime.minute;
      final startMinOfDay = startHour * 60 + startMin;
      final endMinOfDay = endHour * 60 + endMin;

      if (startMinOfDay > endMinOfDay) {
        isInside = (schedMinOfDay >= startMinOfDay || schedMinOfDay <= endMinOfDay);
      } else {
        isInside = (schedMinOfDay >= startMinOfDay && schedMinOfDay <= endMinOfDay);
      }

      if (isInside) {
        if (schedMinOfDay >= startMinOfDay) {
          qEnd = qEnd.add(const Duration(days: 1));
        }
        return qEnd;
      }
    } catch (e) {
      debugPrint('Error applying quiet hours adjustment: $e');
    }
    return scheduledTime;
  }

  /// Schedule alert 5 minutes before batch start
  Future<void> scheduleBatchStartAlert(String batchId, String batchName, String startTimeStr) async {
    try {
      final parts = startTimeStr.split(':');
      if (parts.length != 2) return;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      tz.TZDateTime batchStart = _nextInstanceOfTime(hour, minute);
      tz.TZDateTime alertTime = batchStart.subtract(const Duration(minutes: 5));

      final now = tz.TZDateTime.now(tz.local);
      if (alertTime.isBefore(now)) {
        alertTime = alertTime.add(const Duration(days: 1));
      }

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'batch_alerts',
        'Batch Start Alerts',
        channelDescription: 'Alerts reminding you 5 minutes before a class starts',
        importance: Importance.high,
        priority: Priority.high,
      );

      final int alertId = batchId.hashCode;

      await _androidNotifications.zonedSchedule(
        alertId,
        'GM Chanakya is here! 🎓',
        'GM Chanakya has arrived in class. Wake up and join "$batchName" now!',
        alertTime,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('Scheduled alert for batch $batchName ($batchId) at $alertTime');
    } catch (e) {
      debugPrint('Failed to schedule batch start alert: $e');
    }
  }

  /// Cancel batch start alert
  Future<void> cancelBatchAlert(String batchId) async {
    try {
      final int alertId = batchId.hashCode;
      await _androidNotifications.cancel(alertId);
      debugPrint('Cancelled alert for batch $batchId');
    } catch (e) {
      debugPrint('Failed to cancel batch alert: $e');
    }
  }

  /// Helper to calculate the next occurrence of a time in local timezone
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
