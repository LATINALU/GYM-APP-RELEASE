import 'package:intl/intl.dart';

/// Date formatting and manipulation utilities
class DateUtils {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy', 'es');
  static final DateFormat _dayMonthFormat = DateFormat('d MMM', 'es');

  /// Format date as dd/MM/yyyy
  static String formatDate(DateTime date) => _dateFormat.format(date);

  /// Format datetime as dd/MM/yyyy HH:mm
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);

  /// Format time as HH:mm
  static String formatTime(DateTime date) => _timeFormat.format(date);

  /// Format as month and year (e.g., "Enero 2024")
  static String formatMonthYear(DateTime date) => _monthYearFormat.format(date);

  /// Format as day and month (e.g., "15 Ene")
  static String formatDayMonth(DateTime date) => _dayMonthFormat.format(date);

  /// Get start of day
  static DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

  /// Get end of day
  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  /// Get start of week (Monday)
  static DateTime startOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return startOfDay(date.subtract(Duration(days: daysFromMonday)));
  }

  /// Get end of week (Sunday)
  static DateTime endOfWeek(DateTime date) {
    final daysUntilSunday = 7 - date.weekday;
    return endOfDay(date.add(Duration(days: daysUntilSunday)));
  }

  /// Get start of month
  static DateTime startOfMonth(DateTime date) => DateTime(date.year, date.month, 1);

  /// Get end of month
  static DateTime endOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);

  /// Check if two dates are the same day
  static bool isSameDay(DateTime date1, DateTime date2) =>
      date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;

  /// Get relative time string (e.g., "hace 5 minutos")
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return formatDate(date);
    } else if (difference.inDays > 0) {
      return 'hace ${difference.inDays} día${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inHours > 0) {
      return 'hace ${difference.inHours} hora${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inMinutes > 0) {
      return 'hace ${difference.inMinutes} minuto${difference.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'ahora';
    }
  }
}
