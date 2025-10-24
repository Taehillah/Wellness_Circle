import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'SharedPreferences has not been initialized. Did you forget to override sharedPreferencesProvider in bootstrap?',
  );
});

final appConfigProvider = Provider<AppConfig>((ref) {
  return const AppConfig.fromEnvironment();
});
