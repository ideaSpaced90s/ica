import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationServiceProvider = Provider((ref) => NotificationService(ref));

class NotificationService {
  final Ref ref;
  
  // Singleton instance of Flutter Local Notifications (Android)
  final FlutterLocalNotificationsPlugin _androidNotifications = FlutterLocalNotificationsPlugin();
  
  // Callback when a notification is clicked by the user
  static void Function(int index)? onNotificationClicked;

  NotificationService(this.ref);

  /// Initialise notifications for the current platform
  Future<void> initialize() async {
    if (Platform.isAndroid) {
      tz.initializeTimeZones();
      
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
          
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _androidNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (onNotificationClicked != null) {
            onNotificationClicked!(11); // Route to Assignment (11)
          }
        },
      );
    } else if (Platform.isWindows) {
      await localNotifier.setup(
        appName: 'IdeaSpace Chess Academy',
        shortcutPolicy: ShortcutPolicy.requireCreate,
      );
    }
  }

  /// Show an immediate notification (works on Android and Windows)
  Future<void> showImmediateNotification(String title, String body) async {
    if (Platform.isAndroid) {
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
    } else if (Platform.isWindows) {
      final notification = LocalNotification(
        title: title,
        body: body,
      );
      notification.onClick = () {
        if (onNotificationClicked != null) {
          onNotificationClicked!(11);
        }
      };
      await notification.show();
    }
  }

  /// Cancel all scheduled alarms
  Future<void> cancelAllNotifications() async {
    if (Platform.isAndroid) {
      await _androidNotifications.cancelAll();
    }
  }

  /// Schedule the daily briefing at a specific time (Android only)
  Future<void> scheduleDailyBriefing(String timeStr) async {
    if (!Platform.isAndroid) return;

    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) return;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final scheduledTime = _nextInstanceOfTime(hour, minute);

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
  Future<void> scheduleStreakProtection(int hoursBeforeReset) async {
    if (!Platform.isAndroid) return;

    try {
      final hour = 24 - hoursBeforeReset;
      if (hour < 0 || hour >= 24) return;

      final scheduledTime = _nextInstanceOfTime(hour, 0);

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
