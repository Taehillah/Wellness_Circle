import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../firebase_options.dart';
import '../../features/auth/data/models/auth_session.dart';
import 'notifications_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background message received: ${message.messageId}');
}

class MessagingService {
  MessagingService(this._notifications, this._firestore, this._auth);

  final NotificationsService _notifications;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  bool _initialized = false;
  StreamSubscription<String>? _tokenRefreshSub;
  String? _lastRegisteredToken;

  Future<void> init() async {
    if (_initialized) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    final messaging = FirebaseMessaging.instance;
    await messaging.setAutoInitEnabled(true);
    await _requestPermission(messaging);

    try {
      final token = await messaging.getToken();
      debugPrint('Firebase Messaging token: $token');
      _lastRegisteredToken = token;
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
      await messaging.requestPermission(alert: true, badge: true, sound: true);
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
      debugPrint(
        'Notification permission status: ${settings.authorizationStatus}',
      );
    }
  }

  Future<void> configureForSession(AuthSession session) async {
    await init();
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _persistToken(session: session, token: token);
        _lastRegisteredToken = token;
      }
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = messaging.onTokenRefresh.listen((newToken) async {
        _lastRegisteredToken = newToken;
        await _persistToken(session: session, token: newToken);
      });
    } catch (error) {
      debugPrint('Failed to register FCM token: $error');
    }
  }

  Future<void> clearTokenForCurrentUser() async {
    await init();
    try {
      final messaging = FirebaseMessaging.instance;
      final token = _lastRegisteredToken ?? await messaging.getToken();
      if (token == null || token.isEmpty) {
        return;
      }
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('fcmTokens')
            .doc(token)
            .delete()
            .catchError((_) {});
      }
    } catch (error) {
      debugPrint('Failed to remove FCM token: $error');
    } finally {
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = null;
      _lastRegisteredToken = null;
    }
  }

  Future<void> _persistToken({
    required AuthSession session,
    required String token,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint('Cannot persist FCM token: no authenticated Firebase user');
      return;
    }
    if (token.isEmpty) return;
    final circleId = session.user.circleId ?? 'circle-${session.user.id}';
    final now = DateTime.now();
    final platformLabel = _platformLabel();
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .doc(token)
        .set({
          'token': token,
          'memberId': session.user.id,
          'memberEmail': session.user.email,
          'circleId': circleId,
          'platform': platformLabel,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedAtLocal': now.toIso8601String(),
        }, SetOptions(merge: true));

    await _firestore.collection('users').doc(uid).set({
      'circleId': circleId,
      'lastFcmToken': token,
      'lastFcmTokenAt': FieldValue.serverTimestamp(),
      'lastFcmTokenAtLocal': now.toIso8601String(),
    }, SetOptions(merge: true));
  }

  String _platformLabel() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }
}
