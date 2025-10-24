import 'check_in_entry.dart';

class CheckInStats {
  const CheckInStats({
    required this.total,
    required this.currentStreak,
    required this.thisWeek,
    required this.lastCheckIn,
    required this.hasCheckedInToday,
  });

  final int total;
  final int currentStreak;
  final int thisWeek;
  final CheckInEntry? lastCheckIn;
  final bool hasCheckedInToday;

  CheckInStats copyWith({
    int? total,
    int? currentStreak,
    int? thisWeek,
    CheckInEntry? lastCheckIn,
    bool? hasCheckedInToday,
  }) {
    return CheckInStats(
      total: total ?? this.total,
      currentStreak: currentStreak ?? this.currentStreak,
      thisWeek: thisWeek ?? this.thisWeek,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      hasCheckedInToday: hasCheckedInToday ?? this.hasCheckedInToday,
    );
  }

  static CheckInStats fromHistory(List<CheckInEntry> history) {
    if (history.isEmpty) {
      return const CheckInStats(
        total: 0,
        currentStreak: 0,
        thisWeek: 0,
        lastCheckIn: null,
        hasCheckedInToday: false,
      );
    }

    final sorted = [...history]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int streak = 0;
    DateTime? cursor = today;

    for (final entry in sorted) {
      final date = DateTime(entry.timestamp.year, entry.timestamp.month, entry.timestamp.day);
      if (streak == 0 && date.isAtSameMomentAs(today)) {
        streak++;
        cursor = today.subtract(const Duration(days: 1));
        continue;
      }
      if (cursor != null && date.isAtSameMomentAs(cursor)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }
      if (cursor != null && date.isBefore(cursor)) {
        break;
      }
    }

    final weekAgo = today.subtract(const Duration(days: 6));
    final thisWeekCount = history
        .where((entry) => entry.timestamp.isAfter(weekAgo.subtract(const Duration(seconds: 1))))
        .length;

    final hasCheckedToday = sorted.first.timestamp.year == now.year &&
        sorted.first.timestamp.month == now.month &&
        sorted.first.timestamp.day == now.day;

    return CheckInStats(
      total: history.length,
      currentStreak: streak,
      thisWeek: thisWeekCount,
      lastCheckIn: sorted.first,
      hasCheckedInToday: hasCheckedToday,
    );
  }
}
