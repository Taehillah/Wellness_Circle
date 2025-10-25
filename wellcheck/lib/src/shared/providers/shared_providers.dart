import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../services/notifications_service.dart';
import '../services/app_database.dart';
import '../services/biometric_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'SharedPreferences has not been initialized. Did you forget to override sharedPreferencesProvider in bootstrap?',
  );
});

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.auto();
});

final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  throw UnimplementedError(
    'NotificationsService has not been initialized. Did you forget to override notificationsServiceProvider in bootstrap?',
  );
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'AppDatabase has not been initialized. Did you forget to override appDatabaseProvider in bootstrap?',
  );
});

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});
