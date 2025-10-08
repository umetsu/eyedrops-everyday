import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../database/database_helper.dart';
import '../database/models/eyedrop_record.dart';
import '../utils/date_utils.dart';
import 'settings_service.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  if (kDebugMode) {
    print('バックグラウンド通知アクション受信: ${notificationResponse.payload}');
    print('バックグラウンドアクションID: ${notificationResponse.actionId}');
  }
  await NotificationService().handleActionResponse(notificationResponse, isBackground: true);
}

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
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await _createNotificationChannels();
    await requestPermissionsIfNeeded();
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

  Future<bool> requestPermissionsIfNeeded() async {
    final settingsService = SettingsService();
    final alreadyRequested = await settingsService.getNotificationPermissionRequested();
    
    if (alreadyRequested) {
      return true;
    }
    
    final granted = await requestPermissions();
    if (granted) {
      await settingsService.setNotificationPermissionRequested(true);
    }
    
    return granted;
  }

  Future<void> scheduleDailyReminder() async {
    try {
      final settingsService = SettingsService();
      final reminderTime = await settingsService.getDailyReminderTime();
      final targetDate = _nextInstanceOfTime(reminderTime.hour, reminderTime.minute);
      final targetDateString = AppDateUtils.formatDate(targetDate);

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        _dailyNotificationId,
        '点眼の時間です',
        '今日の点眼を忘れずに行いましょう',
        targetDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _dailyReminderChannelId,
            '点眼リマインダー',
            channelDescription: '毎日の点眼を促す通知',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            actions: const <AndroidNotificationAction>[
              AndroidNotificationAction(
                'mark_completed',
                '点眼した',
                showsUserInterface: false,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: targetDateString,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      // エラーが発生した場合は静かに失敗する
    }
  }

  Future<void> scheduleMissedReminder() async {
    try {
      final settingsService = SettingsService();
      final missedTime = await settingsService.getMissedReminderTime();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayString = AppDateUtils.formatDate(yesterday);

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        _missedNotificationId,
        '点眼を忘れていませんか？',
        '昨日の点眼が記録されていません。忘れずに点眼を行いましょう',
        _nextInstanceOfTime(missedTime.hour, missedTime.minute),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _missedReminderChannelId,
            '点眼忘れ通知',
            channelDescription: '前日の点眼を忘れた場合の通知',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            actions: const <AndroidNotificationAction>[
              AndroidNotificationAction(
                'mark_completed',
                '点眼した',
                showsUserInterface: false,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: yesterdayString,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      // エラーが発生した場合は静かに失敗する
    }
  }

  Future<void> checkAndScheduleMissedNotification() async {
    final settingsService = SettingsService();
    final notificationsEnabled = await settingsService.getNotificationsEnabled();
    
    if (!notificationsEnabled) {
      return;
    }
    
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

  void _onNotificationTapped(NotificationResponse notificationResponse) async {
    if (kDebugMode) {
      print('通知がタップされました: ${notificationResponse.payload}');
      print('アクションID: ${notificationResponse.actionId}');
    }
    await handleActionResponse(notificationResponse, isBackground: false);
  }

  Future<void> handleActionResponse(NotificationResponse notificationResponse, {bool isBackground = false}) async {
    try {
      if (notificationResponse.actionId == 'mark_completed') {
        final String targetDate = notificationResponse.payload ?? AppDateUtils.formatDate(DateTime.now());
        await _markDateAsCompleted(targetDate);

        final androidImpl = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

        final active = await androidImpl?.getActiveNotifications();
        final int? responseId = notificationResponse.id;
        if (responseId != null) {
          await _flutterLocalNotificationsPlugin.cancel(responseId);
        } else if (active != null && active.isNotEmpty) {
          for (final n in active) {
            if (n.id != null && (n.id == _dailyNotificationId || n.id == _missedNotificationId)) {
              await _flutterLocalNotificationsPlugin.cancel(n.id!);
            }
          }
        }

        await scheduleDailyReminder();
        await checkAndScheduleMissedNotification();
      }
    } catch (e) {
      if (kDebugMode) {
        print('通知アクション処理エラー: $e');
      }
    }
  }

  Future<void> _markDateAsCompleted(String date) async {
    try {
      final databaseHelper = DatabaseHelper();
      final existingRecord = await databaseHelper.getEyedropRecordByDate(date);
      final now = DateTime.now();
      
      if (existingRecord != null) {
        if (!existingRecord.completed) {
          final updatedRecord = existingRecord.copyWith(
            completed: true,
            completedAt: AppDateUtils.formatDateTime(now),
            updatedAt: AppDateUtils.formatDateTime(now),
          );
          await databaseHelper.updateEyedropRecord(updatedRecord);
        }
      } else {
        final newRecord = EyedropRecord(
          date: date,
          completed: true,
          completedAt: AppDateUtils.formatDateTime(now),
          createdAt: AppDateUtils.formatDateTime(now),
          updatedAt: AppDateUtils.formatDateTime(now),
        );
        await databaseHelper.insertEyedropRecord(newRecord);
      }
      
      await checkAndScheduleMissedNotification();
    } catch (e) {
      if (kDebugMode) {
        print('通知アクションでの点眼記録エラー: $e');
      }
    }
  }
}
