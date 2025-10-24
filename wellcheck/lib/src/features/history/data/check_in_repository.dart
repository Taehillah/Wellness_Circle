import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/services/preferences_service.dart';
import 'models/check_in_entry.dart';

class CheckInRepository {
  CheckInRepository(this._preferences);

  final PreferencesService _preferences;
  final _uuid = const Uuid();

  String _key(int userId) => 'wellcheck.user.$userId.checkins';

  Future<List<CheckInEntry>> loadHistory({
    required int userId,
    List<CheckInEntry> seeded = const [],
  }) async {
    final raw = _preferences.getString(_key(userId));
    if (raw == null) {
      if (seeded.isNotEmpty) {
        await saveHistory(userId: userId, history: seeded);
        return seeded;
      }
      return const [];
    }
    final parsed = (jsonDecode(raw) as List<dynamic>)
        .map((item) => CheckInEntry.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    return parsed;
  }

  Future<void> saveHistory({
    required int userId,
    required List<CheckInEntry> history,
  }) async {
    final payload = jsonEncode(history.map((entry) => entry.toJson()).toList());
    await _preferences.setString(_key(userId), payload);
  }

  Future<CheckInEntry> addCheckIn({
    required int userId,
    required List<CheckInEntry> currentHistory,
  }) async {
    final entry = CheckInEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
    );
    final updated = [...currentHistory, entry];
    await saveHistory(userId: userId, history: updated);
    return entry;
  }

  Future<void> clearHistory(int userId) async {
    await _preferences.remove(_key(userId));
  }
}

final checkInRepositoryProvider = Provider<CheckInRepository>((ref) {
  final preferences = ref.watch(preferencesServiceProvider);
  return CheckInRepository(preferences);
});
