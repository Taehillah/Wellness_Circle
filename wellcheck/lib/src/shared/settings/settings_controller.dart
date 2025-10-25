import 'package:riverpod/riverpod.dart';

import '../services/preferences_service.dart';

const _kLocationEnabledKey = 'wellcheck.settings.location_enabled';
const _kTimerHoursKey = 'wellcheck.settings.timer_hours';

class LocationEnabledController extends Notifier<bool> {
  late final PreferencesService _prefs;

  @override
  bool build() {
    _prefs = ref.read(preferencesServiceProvider);
    final saved = _prefs.getString(_kLocationEnabledKey);
    if (saved == null) return true; // default on
    return saved == 'true';
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    await _prefs.setString(_kLocationEnabledKey, value ? 'true' : 'false');
  }
}

final locationEnabledProvider =
    NotifierProvider<LocationEnabledController, bool>(LocationEnabledController.new);

class TimerHoursController extends Notifier<int> {
  late final PreferencesService _prefs;

  @override
  int build() {
    _prefs = ref.read(preferencesServiceProvider);
    final saved = _prefs.getString(_kTimerHoursKey);
    final parsed = int.tryParse(saved ?? '');
    return (parsed != null && parsed >= 1 && parsed <= 24) ? parsed : 5;
  }

  Future<void> setHours(int hours) async {
    if (hours < 1) hours = 1;
    if (hours > 24) hours = 24;
    state = hours;
    await _prefs.setString(_kTimerHoursKey, hours.toString());
  }
}

final timerHoursProvider =
    NotifierProvider<TimerHoursController, int>(TimerHoursController.new);

