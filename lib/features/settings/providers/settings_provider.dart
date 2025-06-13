import 'package:flutter/foundation.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/notification_service.dart';

class SettingsProvider with ChangeNotifier {
  final SettingsService _settingsService = SettingsService();
  final NotificationService _notificationService = NotificationService();

  DateTime _dailyReminderTime = DateTime(2024, 1, 1, 21, 0);
  DateTime _missedReminderTime = DateTime(2024, 1, 1, 7, 0);
  bool _notificationsEnabled = true;
  bool _isLoading = false;

  DateTime get dailyReminderTime => _dailyReminderTime;
  DateTime get missedReminderTime => _missedReminderTime;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isLoading => _isLoading;

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _dailyReminderTime = await _settingsService.getDailyReminderTime();
      _missedReminderTime = await _settingsService.getMissedReminderTime();
      _notificationsEnabled = await _settingsService.getNotificationsEnabled();
    } catch (e) {
      if (kDebugMode) {
        print('設定の読み込みでエラーが発生しました: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setDailyReminderTime(DateTime time) async {
    try {
      await _settingsService.setDailyReminderTime(time);
      _dailyReminderTime = time;
      notifyListeners();
      
      if (_notificationsEnabled) {
        await _notificationService.rescheduleNotifications();
      }
    } catch (e) {
      if (kDebugMode) {
        print('定時通知時刻の設定でエラーが発生しました: $e');
      }
    }
  }

  Future<void> setMissedReminderTime(DateTime time) async {
    try {
      await _settingsService.setMissedReminderTime(time);
      _missedReminderTime = time;
      notifyListeners();
      
      if (_notificationsEnabled) {
        await _notificationService.rescheduleNotifications();
      }
    } catch (e) {
      if (kDebugMode) {
        print('忘れ通知時刻の設定でエラーが発生しました: $e');
      }
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      await _settingsService.setNotificationsEnabled(enabled);
      _notificationsEnabled = enabled;
      notifyListeners();
      
      if (enabled) {
        await _notificationService.rescheduleNotifications();
      } else {
        await _notificationService.cancelAllNotifications();
      }
    } catch (e) {
      if (kDebugMode) {
        print('通知設定の変更でエラーが発生しました: $e');
      }
    }
  }
}
