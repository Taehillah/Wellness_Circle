import 'package:riverpod/riverpod.dart';

import '../services/preferences_service.dart';
import '../../features/auth/application/auth_controller.dart';

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

// Preferred contact per user. Stores the selected contact id for quick dial.
class PreferredContactController extends Notifier<String?> {
  late final PreferencesService _prefs;

  String _keyFor(int? userId) =>
      userId == null ? 'wellcheck.user.anon.preferred_contact' : 'wellcheck.user.$userId.preferred_contact';

  @override
  String? build() {
    _prefs = ref.read(preferencesServiceProvider);
    final userId = ref.read(authSessionProvider)?.user.id;
    return _prefs.getString(_keyFor(userId));
  }

  Future<void> setPreferred(String? contactId) async {
    final userId = ref.read(authSessionProvider)?.user.id;
    final key = _keyFor(userId);
    if (contactId == null || contactId.isEmpty) {
      await _prefs.remove(key);
      state = null;
    } else {
      await _prefs.setString(key, contactId);
      state = contactId;
    }
  }
}

final preferredContactProvider =
    NotifierProvider<PreferredContactController, String?>(PreferredContactController.new);
