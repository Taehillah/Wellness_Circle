import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../firebase_options.dart';
import 'notifications_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('Background message received: ${message.messageId}');
}

class MessagingService {
  MessagingService(this._notifications);

  final NotificationsService _notifications;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    final messaging = FirebaseMessaging.instance;
    await messaging.setAutoInitEnabled(true);
    await _requestPermission(messaging);

    try {
      final token = await messaging.getToken();
      debugPrint('Firebase Messaging token: $token');
    } catch (error) {
      debugPrint('Unable to fetch FCM token: $error');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _notifications.showAlertNotification(
          title: notification.title ?? 'Wellness Circle',
          body: notification.body,
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification tapped: ${message.messageId}');
    });

    _initialized = true;
  }

  Future<void> _requestPermission(FirebaseMessaging messaging) async {
    if (kIsWeb) {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return;
    }
    if (Platform.isIOS || Platform.isAndroid) {
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('Notification permission status: ${settings.authorizationStatus}');
    }
  }
}
