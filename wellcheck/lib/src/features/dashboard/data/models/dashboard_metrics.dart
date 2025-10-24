import '../../../contacts/data/models/contact.dart';
import '../../../history/data/models/check_in_stats.dart';

class WeeklyActivityDay {
  WeeklyActivityDay({
    required this.date,
    required this.count,
  });

  final DateTime date;
  final int count;

  String get label => _weekdayLabels[date.weekday] ?? 'Day';
  static const _weekdayLabels = {
    DateTime.monday: 'Mon',
    DateTime.tuesday: 'Tue',
    DateTime.wednesday: 'Wed',
    DateTime.thursday: 'Thu',
    DateTime.friday: 'Fri',
    DateTime.saturday: 'Sat',
    DateTime.sunday: 'Sun',
  };
}

class DashboardMetrics {
  DashboardMetrics({
    required this.stats,
    required this.contacts,
    required this.weeklyActivity,
  });

  final CheckInStats stats;
  final List<Contact> contacts;
  final List<WeeklyActivityDay> weeklyActivity;

  int get totalContacts => contacts.length;
  List<Contact> get topContacts => contacts.take(3).toList();
}
