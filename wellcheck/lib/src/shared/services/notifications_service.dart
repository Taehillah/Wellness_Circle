import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsService {
  static const int _reminderId = 1001;
  static const int _alertId = 2001;
  static const String _reminderChannelId = 'wellcheck_reminders';
  static const String _alertChannelId = 'wellcheck_alerts';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    // Only initialize on Android for now to avoid blank screens on iOS/Web
    // due to missing platform configuration.
    if (kIsWeb || !Platform.isAndroid) {
      _initialized = true;
      return;
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _reminderChannelId,
        'Wellness Circle Reminders',
        description: 'Wellness Circle reminders to check in',
        importance: Importance.high,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _alertChannelId,
        'Wellness Circle Alerts',
        description: 'Wellness Circle emergency and circle alerts',
        importance: Importance.high,
      ),
    );
    _initialized = true;
  }

  Future<void> startMinuteReminder({String? title, String? body}) async {
    await init();
    if (kIsWeb || !Platform.isAndroid) return;
    const androidDetails = AndroidNotificationDetails(
      _reminderChannelId,
      'Wellness Circle Reminders',
      channelDescription: 'Wellness Circle reminders to check in',
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
    if (!_initialized) return;
    if (kIsWeb || !Platform.isAndroid) return;
    await _plugin.cancel(_reminderId);
  }

  Future<void> showAlertNotification({
    required String title,
    String? body,
  }) async {
    await init();
    if (kIsWeb || !Platform.isAndroid) return;
    const androidDetails = AndroidNotificationDetails(
      _alertChannelId,
      'Wellness Circle Alerts',
      channelDescription: 'Wellness Circle emergency and circle alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(_alertId, title, body, details);
  }
}
