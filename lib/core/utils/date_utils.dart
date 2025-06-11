import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  static DateTime parseDate(String dateString) {
    return DateTime.parse(dateString);
  }

  static String formatDisplayDate(DateTime date) {
    return DateFormat('yyyy年MM月dd日').format(date);
  }

  static String formatDisplayTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime getEndOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }
}
