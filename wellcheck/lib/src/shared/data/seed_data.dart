import 'dart:math';

class SeedData {
  static const demoUserEmail = 'margaret@example.com';
  static const adminEmail = 'admin@wellcheck.com';

  static bool shouldSeed(String email) {
    final normalized = email.toLowerCase();
    return normalized == demoUserEmail || normalized == adminEmail;
  }

  static List<DateTime> seededCheckIns(String email) {
    if (!shouldSeed(email)) {
      return const [];
    }
    final now = DateTime.now();
    final random = Random(42);
    final entries = <DateTime>[];
    for (int i = 0; i < 18; i++) {
      entries.add(now.subtract(Duration(days: i, hours: random.nextInt(12) + 6)));
    }
    return entries;
  }

  static List<Map<String, String>> seededContacts(String email) {
    final normalized = email.toLowerCase();
    if (normalized == demoUserEmail) {
      return const [
        {'name': 'Lisa Carter', 'phone': '(217) 555-0192'},
        {'name': 'Dr. Ahmed Patel', 'phone': '(312) 555-8814'},
        {'name': 'Nurse Line', 'phone': '(800) 234-1212'},
      ];
    }
    if (normalized == adminEmail) {
      return const [
        {'name': 'WellCheck Ops', 'phone': '(312) 555-1100'},
        {'name': 'Community Support', 'phone': '(872) 555-9981'},
      ];
    }
    return const [];
  }
}
