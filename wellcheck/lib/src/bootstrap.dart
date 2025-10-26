import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import '../firebase_options.dart';
import 'shared/providers/shared_providers.dart';
import 'shared/services/notifications_service.dart';
import 'shared/services/app_database.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const bool useEmulator =
      bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);
  if (useEmulator) {
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
      );
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    } catch (_) {
      // Emulator setup is best effort; fall back silently if not available.
    }
  }

  final prefs = await SharedPreferences.getInstance();
  final notifications = NotificationsService();
  await notifications.init();
  final database = AppDatabase();
  await database.init();

  if (kIsWeb) {
    // No-op placeholder for potential web-specific bootstrap steps.
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationsServiceProvider.overrideWithValue(notifications),
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: const App(),
    ),
  );
}
