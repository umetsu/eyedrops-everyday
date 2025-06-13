import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _dailyReminderHourKey = 'daily_reminder_hour';
  static const String _dailyReminderMinuteKey = 'daily_reminder_minute';
  static const String _missedReminderHourKey = 'missed_reminder_hour';
  static const String _missedReminderMinuteKey = 'missed_reminder_minute';
  static const String _notificationsEnabledKey = 'notifications_enabled';

  static const int _defaultDailyHour = 21;
  static const int _defaultDailyMinute = 0;
  static const int _defaultMissedHour = 7;
  static const int _defaultMissedMinute = 0;

  Future<DateTime> getDailyReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_dailyReminderHourKey) ?? _defaultDailyHour;
    final minute = prefs.getInt(_dailyReminderMinuteKey) ?? _defaultDailyMinute;
    
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  Future<void> setDailyReminderTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyReminderHourKey, time.hour);
    await prefs.setInt(_dailyReminderMinuteKey, time.minute);
  }

  Future<DateTime> getMissedReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_missedReminderHourKey) ?? _defaultMissedHour;
    final minute = prefs.getInt(_missedReminderMinuteKey) ?? _defaultMissedMinute;
    
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  Future<void> setMissedReminderTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_missedReminderHourKey, time.hour);
    await prefs.setInt(_missedReminderMinuteKey, time.minute);
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }
}
