import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../database/database_helper.dart';
import '../utils/date_utils.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _dailyReminderKey = 'daily_reminder_time';
  static const String _forgetReminderKey = 'forget_reminder_time';
  static const String _notificationEnabledKey = 'notification_enabled';

  static const int _dailyReminderId = 1;
  static const int _forgetReminderId = 2;
  static const int _snoozeBaseId = 100;

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _createNotificationChannel();
    await _requestPermissions();
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'eyedrops_reminder',
      '点眼リマインダー',
      description: '毎日の点眼を忘れないためのリマインダー通知',
      importance: Importance.high,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _requestPermissions() async {
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();
  }

  void _onNotificationTap(NotificationResponse response) {
    if (response.actionId == 'snooze') {
      _scheduleSnoozeNotification(response.id ?? 0);
    }
  }

  Future<void> scheduleDailyReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_notificationEnabledKey) ?? true;
    
    if (!isEnabled) return;

    final timeString = prefs.getString(_dailyReminderKey) ?? '21:00';
    final timeParts = timeString.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      _dailyReminderId,
      '点眼の時間です',
      '今日の点眼を忘れずに行いましょう',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'eyedrops_reminder',
          '点眼リマインダー',
          channelDescription: '毎日の点眼を忘れないためのリマインダー通知',
          importance: Importance.high,
          priority: Priority.high,
          actions: [
            AndroidNotificationAction(
              'snooze',
              'スヌーズ',
              showsUserInterface: false,
            ),
            AndroidNotificationAction(
              'done',
              '完了',
              showsUserInterface: true,
            ),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleForgetReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_notificationEnabledKey) ?? true;
    
    if (!isEnabled) return;

    final timeString = prefs.getString(_forgetReminderKey) ?? '07:00';
    final timeParts = timeString.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayString = AppDateUtils.formatDate(yesterday);

    final databaseHelper = DatabaseHelper();
    final record = await databaseHelper.getEyedropRecordByDate(yesterdayString);

    if (record == null || !record.completed) {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        _forgetReminderId,
        '点眼忘れのお知らせ',
        '昨日の点眼が記録されていません。忘れていませんか？',
        _nextInstanceOfTime(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'eyedrops_reminder',
            '点眼リマインダー',
            channelDescription: '毎日の点眼を忘れないためのリマインダー通知',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> _scheduleSnoozeNotification(int originalId) async {
    final snoozeMinutes = [30, 15, 10, 5];
    final prefs = await SharedPreferences.getInstance();
    final snoozeCount = prefs.getInt('snooze_count_$originalId') ?? 0;

    if (snoozeCount < snoozeMinutes.length) {
      final snoozeTime = DateTime.now().add(Duration(minutes: snoozeMinutes[snoozeCount]));
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        _snoozeBaseId + originalId + snoozeCount,
        '点眼の時間です（リマインダー）',
        '点眼を忘れずに行いましょう',
        tz.TZDateTime.from(snoozeTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'eyedrops_reminder',
            '点眼リマインダー',
            channelDescription: '毎日の点眼を忘れないためのリマインダー通知',
            importance: Importance.high,
            priority: Priority.high,
            actions: [
              AndroidNotificationAction(
                'snooze',
                'スヌーズ',
                showsUserInterface: false,
              ),
              AndroidNotificationAction(
                'done',
                '完了',
                showsUserInterface: true,
              ),
            ],
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      await prefs.setInt('snooze_count_$originalId', snoozeCount + 1);
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> updateNotificationSchedule() async {
    await cancelAllNotifications();
    await scheduleDailyReminder();
    await scheduleForgetReminder();
  }

  Future<String> getDailyReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dailyReminderKey) ?? '21:00';
  }

  Future<void> setDailyReminderTime(String time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dailyReminderKey, time);
    await updateNotificationSchedule();
  }

  Future<String> getForgetReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_forgetReminderKey) ?? '07:00';
  }

  Future<void> setForgetReminderTime(String time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_forgetReminderKey, time);
    await updateNotificationSchedule();
  }

  Future<bool> isNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationEnabledKey) ?? true;
  }

  Future<void> setNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationEnabledKey, enabled);
    
    if (enabled) {
      await updateNotificationSchedule();
    } else {
      await cancelAllNotifications();
    }
  }
}
