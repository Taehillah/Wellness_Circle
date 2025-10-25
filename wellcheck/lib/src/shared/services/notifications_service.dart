import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsService {
  static const int _reminderId = 1001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);

    // Request permissions on supported platforms.
    if (!kIsWeb) {
      if (Platform.isAndroid) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();
        await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
          'wellcheck_reminders',
          'WellCheck Reminders',
          description: 'Reminders to check in',
          importance: Importance.high,
        ));
      }
      // iOS permission request handled via Darwin plugin if needed in future.
    }
    _initialized = true;
  }

  Future<void> startMinuteReminder({String? title, String? body}) async {
    await init();
    const androidDetails = AndroidNotificationDetails(
      'wellcheck_reminders',
      'WellCheck Reminders',
      channelDescription: 'Reminders to check in',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    // Show immediately, then repeat every minute (Android only).
    await _plugin.periodicallyShow(
      _reminderId,
      title ?? 'Time to check in',
      body ?? 'Tap to confirm: I am doing Great!',
      RepeatInterval.everyMinute,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelReminders() async {
    await _plugin.cancel(_reminderId);
  }
}

