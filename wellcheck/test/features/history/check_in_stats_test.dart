import 'package:flutter_test/flutter_test.dart';

import 'package:wellcheck/src/features/history/data/models/check_in_entry.dart';
import 'package:wellcheck/src/features/history/data/models/check_in_stats.dart';

void main() {
  test('calculates streak and weekly totals correctly', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 10);
    final entries = [
      CheckInEntry(id: 'today', timestamp: today),
      CheckInEntry(id: 'yesterday', timestamp: today.subtract(const Duration(days: 1))),
      CheckInEntry(id: 'three-days', timestamp: today.subtract(const Duration(days: 3))),
      CheckInEntry(id: 'ten-days', timestamp: today.subtract(const Duration(days: 10))),
    ];

    final stats = CheckInStats.fromHistory(entries);

    expect(stats.total, entries.length);
    expect(stats.hasCheckedInToday, isTrue);
    expect(stats.currentStreak, 2);
    expect(stats.thisWeek, 3);
    expect(stats.lastCheckIn?.id, 'today');
  });
}
