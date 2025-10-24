import 'package:intl/intl.dart';

class DateFormatting {
  static final _fullFormatter = DateFormat('MMM d, yyyy • h:mm a');
  static final _shortFormatter = DateFormat('MMM d, yyyy');
  static final _timeFormatter = DateFormat('h:mm a');
  static final _weekdayFormatter = DateFormat.E();

  static String full(DateTime dateTime) => _fullFormatter.format(dateTime);

  static String short(DateTime dateTime) => _shortFormatter.format(dateTime);

  static String time(DateTime dateTime) => _timeFormatter.format(dateTime);

  static String weekday(DateTime dateTime) => _weekdayFormatter.format(dateTime);

  static String relative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} d ago';
    }
    return short(dateTime);
  }
}
