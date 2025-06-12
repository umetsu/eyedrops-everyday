import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/notification_service.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _notificationEnabledKey = 'notification_enabled';
  static const String _notificationHourKey = 'notification_hour';
  static const String _notificationMinuteKey = 'notification_minute';

  bool _notificationEnabled = true;
  int _notificationHour = 21;
  int _notificationMinute = 0;
  bool _isLoading = false;

  bool get notificationEnabled => _notificationEnabled;
  int get notificationHour => _notificationHour;
  int get notificationMinute => _notificationMinute;
  bool get isLoading => _isLoading;

  TimeOfDay get notificationTime => TimeOfDay(hour: _notificationHour, minute: _notificationMinute);

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationEnabled = prefs.getBool(_notificationEnabledKey) ?? true;
      _notificationHour = prefs.getInt(_notificationHourKey) ?? 21;
      _notificationMinute = prefs.getInt(_notificationMinuteKey) ?? 0;

      if (_notificationEnabled) {
        await _scheduleNotification();
      }
    } catch (e) {
      debugPrint('設定の読み込みに失敗しました: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setNotificationEnabled(bool enabled) async {
    _notificationEnabled = enabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationEnabledKey, enabled);

      if (enabled) {
        await _scheduleNotification();
      } else {
        await NotificationService().cancelAllNotifications();
      }
    } catch (e) {
      debugPrint('通知設定の保存に失敗しました: $e');
    }
  }

  Future<void> setNotificationTime(TimeOfDay time) async {
    _notificationHour = time.hour;
    _notificationMinute = time.minute;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_notificationHourKey, time.hour);
      await prefs.setInt(_notificationMinuteKey, time.minute);

      if (_notificationEnabled) {
        await _scheduleNotification();
      }
    } catch (e) {
      debugPrint('通知時刻の保存に失敗しました: $e');
    }
  }

  Future<void> _scheduleNotification() async {
    try {
      await NotificationService().scheduleDailyNotification(
        hour: _notificationHour,
        minute: _notificationMinute,
      );
    } catch (e) {
      debugPrint('通知のスケジュールに失敗しました: $e');
    }
  }

  String getFormattedNotificationTime() {
    final hour = _notificationHour.toString().padLeft(2, '0');
    final minute = _notificationMinute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
