import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';

class SettingsProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  
  String _dailyReminderTime = '21:00';
  String _forgetReminderTime = '07:00';
  bool _notificationEnabled = true;
  bool _isLoading = false;

  String get dailyReminderTime => _dailyReminderTime;
  String get forgetReminderTime => _forgetReminderTime;
  bool get notificationEnabled => _notificationEnabled;
  bool get isLoading => _isLoading;

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _dailyReminderTime = await _notificationService.getDailyReminderTime();
      _forgetReminderTime = await _notificationService.getForgetReminderTime();
      _notificationEnabled = await _notificationService.isNotificationEnabled();
    } catch (e) {
      debugPrint('設定読み込みエラー: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setDailyReminderTime(String time) async {
    try {
      await _notificationService.setDailyReminderTime(time);
      _dailyReminderTime = time;
      notifyListeners();
    } catch (e) {
      debugPrint('定時通知時刻設定エラー: $e');
    }
  }

  Future<void> setForgetReminderTime(String time) async {
    try {
      await _notificationService.setForgetReminderTime(time);
      _forgetReminderTime = time;
      notifyListeners();
    } catch (e) {
      debugPrint('点眼忘れ通知時刻設定エラー: $e');
    }
  }

  Future<void> setNotificationEnabled(bool enabled) async {
    try {
      await _notificationService.setNotificationEnabled(enabled);
      _notificationEnabled = enabled;
      notifyListeners();
    } catch (e) {
      debugPrint('通知有効/無効設定エラー: $e');
    }
  }
}
