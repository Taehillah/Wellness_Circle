import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';

import '../services/preferences_service.dart';

const _themeModeKey = 'wellcheck.theme.mode';

class ThemeController extends Notifier<ThemeMode> {
  late final PreferencesService _preferences;

  @override
  ThemeMode build() {
    _preferences = ref.read(preferencesServiceProvider);
    final saved = _preferences.getString(_themeModeKey);
    switch (saved) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _preferences.setString(_themeModeKey, value);
  }

  Future<void> toggleLightDark() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }
}

final themeModeProvider = NotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);

