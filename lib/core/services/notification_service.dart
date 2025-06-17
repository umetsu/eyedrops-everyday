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
    final permissionGranted = await requestPermissions();
    
    if (kDebugMode) {
      print('通知サービス初期化完了: 権限取得=${permissionGranted ? "成功" : "失敗"}');
    }
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
    try {
      final settingsService = SettingsService();
      final reminderTime = await settingsService.getDailyReminderTime();
      final scheduledDateTime = _nextInstanceOfTime(reminderTime.hour, reminderTime.minute);
      
      if (kDebugMode) {
        print('日次リマインダーをスケジュール: ${reminderTime.hour}:${reminderTime.minute} -> $scheduledDateTime');
      }

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        _dailyNotificationId,
        '点眼の時間です',
        '今日の点眼を忘れずに行いましょう',
        scheduledDateTime,
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
      
      if (kDebugMode) {
        print('日次リマインダーのスケジュールが完了しました');
      }
    } catch (e) {
      if (kDebugMode) {
        print('日次リマインダーのスケジュールでエラーが発生しました: $e');
      }
    }
  }

  Future<void> scheduleMissedReminder() async {
    try {
      final settingsService = SettingsService();
      final missedTime = await settingsService.getMissedReminderTime();
      final scheduledDateTime = _nextInstanceOfTime(missedTime.hour, missedTime.minute);
      
      if (kDebugMode) {
        print('忘れ通知をスケジュール: ${missedTime.hour}:${missedTime.minute} -> $scheduledDateTime');
      }

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        _missedNotificationId,
        '点眼を忘れていませんか？',
        '昨日の点眼が記録されていません。忘れずに点眼を行いましょう',
        scheduledDateTime,
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
      
      if (kDebugMode) {
        print('忘れ通知のスケジュールが完了しました');
      }
    } catch (e) {
      if (kDebugMode) {
        print('忘れ通知のスケジュールでエラーが発生しました: $e');
      }
    }
  }

  Future<void> checkAndScheduleMissedNotification() async {
    final settingsService = SettingsService();
    final notificationsEnabled = await settingsService.getNotificationsEnabled();
    
    if (!notificationsEnabled) {
      if (kDebugMode) {
        print('通知が無効のため、忘れ通知をスキップします');
      }
      return;
    }
    
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayString = AppDateUtils.formatDate(yesterday);
    
    if (kDebugMode) {
      print('忘れ通知チェック開始: 前日=$yesterdayString');
    }
    
    final dbHelper = DatabaseHelper();
    final record = await dbHelper.getEyedropRecordByDate(yesterdayString);
    
    if (record == null || !record.completed) {
      if (kDebugMode) {
        print('前日の点眼記録が未完了のため、忘れ通知をスケジュールします');
      }
      await scheduleMissedReminder();
    } else {
      if (kDebugMode) {
        print('前日の点眼記録が完了済みのため、忘れ通知をキャンセルします');
      }
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
