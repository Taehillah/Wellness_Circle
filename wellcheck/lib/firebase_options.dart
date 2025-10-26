// ignore_for_file: constant_identifier_names

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] used to initialise Firebase across platforms.
///
/// Replace the placeholder values with the real configuration generated via the
/// FlutterFire CLI (`flutterfire configure`) before shipping.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'TODO_WEB_API_KEY',
    appId: 'TODO_WEB_APP_ID',
    messagingSenderId: 'TODO_SENDER_ID',
    projectId: 'TODO_PROJECT_ID',
    authDomain: 'TODO_AUTH_DOMAIN',
    databaseURL: 'https://TODO_PROJECT_ID.firebaseio.com',
    storageBucket: 'TODO_PROJECT_ID.appspot.com',
    measurementId: 'TODO_MEASUREMENT_ID',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'TODO_ANDROID_API_KEY',
    appId: '1:TODO_ANDROID:android:TODO',
    messagingSenderId: 'TODO_SENDER_ID',
    projectId: 'TODO_PROJECT_ID',
    databaseURL: 'https://TODO_PROJECT_ID.firebaseio.com',
    storageBucket: 'TODO_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'TODO_IOS_API_KEY',
    appId: '1:TODO_IOS:ios:TODO',
    messagingSenderId: 'TODO_SENDER_ID',
    projectId: 'TODO_PROJECT_ID',
    databaseURL: 'https://TODO_PROJECT_ID.firebaseio.com',
    storageBucket: 'TODO_PROJECT_ID.appspot.com',
    iosClientId: 'TODO_IOS_CLIENT_ID',
    iosBundleId: 'com.example.wellcheck',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'TODO_MACOS_API_KEY',
    appId: '1:TODO_MACOS:ios:TODO',
    messagingSenderId: 'TODO_SENDER_ID',
    projectId: 'TODO_PROJECT_ID',
    databaseURL: 'https://TODO_PROJECT_ID.firebaseio.com',
    storageBucket: 'TODO_PROJECT_ID.appspot.com',
    iosClientId: 'TODO_MACOS_CLIENT_ID',
    iosBundleId: 'com.example.wellcheck',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'TODO_WINDOWS_API_KEY',
    appId: '1:TODO_WINDOWS:web:TODO',
    messagingSenderId: 'TODO_SENDER_ID',
    projectId: 'TODO_PROJECT_ID',
    databaseURL: 'https://TODO_PROJECT_ID.firebaseio.com',
    storageBucket: 'TODO_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'TODO_LINUX_API_KEY',
    appId: '1:TODO_LINUX:web:TODO',
    messagingSenderId: 'TODO_SENDER_ID',
    projectId: 'TODO_PROJECT_ID',
    databaseURL: 'https://TODO_PROJECT_ID.firebaseio.com',
    storageBucket: 'TODO_PROJECT_ID.appspot.com',
  );
}
