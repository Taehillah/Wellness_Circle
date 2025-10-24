import 'package:riverpod/riverpod.dart';

import '../../contacts/application/contacts_controller.dart';
import '../../history/application/check_in_controller.dart';
import '../../history/data/models/check_in_entry.dart';
import '../data/models/dashboard_metrics.dart';

final dashboardMetricsProvider = Provider<DashboardMetrics?>((ref) {
  final checkIns = ref.watch(checkInControllerProvider);
  final contacts = ref.watch(contactsControllerProvider);

  if (checkIns.status != CheckInStatus.ready ||
      contacts.status != ContactsStatus.ready) {
    return null;
  }

  final weeklyActivity = _calculateWeeklyActivity(checkIns.history);
  return DashboardMetrics(
    stats: checkIns.stats,
    contacts: contacts.contacts,
    weeklyActivity: weeklyActivity,
  );
});

List<WeeklyActivityDay> _calculateWeeklyActivity(List<CheckInEntry> history) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final counts = <DateTime, int>{};

  for (final entry in history) {
    final date =
        DateTime(entry.timestamp.year, entry.timestamp.month, entry.timestamp.day);
    final difference = today.difference(date).inDays;
    if (difference >= 0 && difference < 7) {
      counts[date] = (counts[date] ?? 0) + 1;
    }
  }

  return List.generate(7, (index) {
    final date = today.subtract(Duration(days: 6 - index));
    return WeeklyActivityDay(
      date: date,
      count: counts[date] ?? 0,
    );
  });
}
