import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../database/database_helper.dart';
import '../utils/date_utils.dart';
import 'settings_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _dailyReminderChannelId = 'daily_reminder';
  static const String _missedReminderChannelId = 'missed_reminder';
  static const int _dailyNotificationId = 1;
  static const int _missedNotificationId = 2;

  Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _createNotificationChannels();
    await requestPermissions();
  }

  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel dailyChannel = AndroidNotificationChannel(
      _dailyReminderChannelId,
      '点眼リマインダー',
      description: '毎日の点眼を促す通知',
      importance: Importance.high,
      enableVibration: true,
    );

    const AndroidNotificationChannel missedChannel = AndroidNotificationChannel(
      _missedReminderChannelId,
      '点眼忘れ通知',
      description: '前日の点眼を忘れた場合の通知',
      importance: Importance.high,
      enableVibration: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(dailyChannel);

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(missedChannel);
  }

  Future<bool> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? granted = await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
      return granted ?? false;
    }

    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      final bool? granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  Future<void> scheduleDailyReminder() async {
    final settingsService = SettingsService();
    final reminderTime = await settingsService.getDailyReminderTime();

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      _dailyNotificationId,
      '点眼の時間です',
      '今日の点眼を忘れずに行いましょう',
      _nextInstanceOfTime(reminderTime.hour, reminderTime.minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyReminderChannelId,
          '点眼リマインダー',
          channelDescription: '毎日の点眼を促す通知',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleMissedReminder() async {
    final settingsService = SettingsService();
    final missedTime = await settingsService.getMissedReminderTime();

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      _missedNotificationId,
      '点眼を忘れていませんか？',
      '昨日の点眼が記録されていません。忘れずに点眼を行いましょう',
      _nextInstanceOfTime(missedTime.hour, missedTime.minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _missedReminderChannelId,
          '点眼忘れ通知',
          channelDescription: '前日の点眼を忘れた場合の通知',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> checkAndScheduleMissedNotification() async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayString = AppDateUtils.formatDate(yesterday);
    
    final dbHelper = DatabaseHelper();
    final record = await dbHelper.getEyedropRecordByDate(yesterdayString);
    
    if (record == null || !record.completed) {
      await scheduleMissedReminder();
    } else {
      await cancelMissedNotification();
    }
  }

  Future<void> cancelDailyReminder() async {
    await _flutterLocalNotificationsPlugin.cancel(_dailyNotificationId);
  }

  Future<void> cancelMissedNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(_missedNotificationId);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> rescheduleNotifications() async {
    await cancelAllNotifications();
    await scheduleDailyReminder();
    await checkAndScheduleMissedNotification();
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    if (kDebugMode) {
      print('通知がタップされました: ${notificationResponse.payload}');
    }
  }
}
