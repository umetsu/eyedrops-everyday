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
  print('[DEBUG] ===== バックグラウンド通知アクション開始 =====');
  print('[DEBUG] Payload: ${notificationResponse.payload}');
  print('[DEBUG] ActionID: ${notificationResponse.actionId}');
  print('[DEBUG] ID: ${notificationResponse.id}');
  
  try {
    await NotificationService().handleActionResponse(notificationResponse, isBackground: true);
    print('[DEBUG] ===== バックグラウンド通知アクション完了 =====');
  } catch (e, stackTrace) {
    print('[DEBUG] ===== バックグラウンド通知アクションエラー =====');
    print('[DEBUG] エラー: $e');
    print('[DEBUG] スタックトレース: $stackTrace');
  }
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
    print('[DEBUG] ===== フォアグラウンド通知タップ =====');
    print('[DEBUG] Payload: ${notificationResponse.payload}');
    print('[DEBUG] ActionID: ${notificationResponse.actionId}');
    print('[DEBUG] ID: ${notificationResponse.id}');
    
    await handleActionResponse(notificationResponse, isBackground: false);
  }

  Future<void> handleActionResponse(NotificationResponse notificationResponse, {bool isBackground = false}) async {
    print('[DEBUG] handleActionResponse開始 (isBackground: $isBackground)');
    
    try {
      print('[DEBUG] ActionID確認: ${notificationResponse.actionId}');
      
      if (notificationResponse.actionId == 'mark_completed') {
        print('[DEBUG] mark_completedアクション検出');
        
        final String targetDate = notificationResponse.payload ?? AppDateUtils.formatDate(DateTime.now());
        print('[DEBUG] 対象日付: $targetDate');
        
        print('[DEBUG] _markDateAsCompleted呼び出し前');
        await _markDateAsCompleted(targetDate);
        print('[DEBUG] _markDateAsCompleted呼び出し後');

        print('[DEBUG] 通知削除処理開始');
        final androidImpl = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

        final active = await androidImpl?.getActiveNotifications();
        print('[DEBUG] アクティブ通知数: ${active?.length ?? 0}');
        
        final int? responseId = notificationResponse.id;
        if (responseId != null) {
          print('[DEBUG] 通知ID ${responseId} をキャンセル');
          await _flutterLocalNotificationsPlugin.cancel(responseId);
        } else if (active != null && active.isNotEmpty) {
          print('[DEBUG] アクティブ通知からキャンセル');
          for (final n in active) {
            if (n.id != null && (n.id == _dailyNotificationId || n.id == _missedNotificationId)) {
              print('[DEBUG] 通知ID ${n.id} をキャンセル');
              await _flutterLocalNotificationsPlugin.cancel(n.id!);
            }
          }
        }

        print('[DEBUG] 通知再スケジュール開始');
        await scheduleDailyReminder();
        await checkAndScheduleMissedNotification();
        print('[DEBUG] 通知再スケジュール完了');
      } else {
        print('[DEBUG] 未知のアクションID: ${notificationResponse.actionId}');
      }
    } catch (e, stackTrace) {
      print('[DEBUG] handleActionResponseエラー: $e');
      print('[DEBUG] スタックトレース: $stackTrace');
    }
    
    print('[DEBUG] handleActionResponse完了');
  }

  Future<void> _markDateAsCompleted(String date) async {
    print('[DEBUG] _markDateAsCompleted開始 (date: $date)');
    
    try {
      print('[DEBUG] DatabaseHelper初期化');
      final databaseHelper = DatabaseHelper();
      
      print('[DEBUG] 既存レコード取得開始');
      final existingRecord = await databaseHelper.getEyedropRecordByDate(date);
      print('[DEBUG] 既存レコード: ${existingRecord != null ? "存在" : "なし"}');
      
      final now = DateTime.now();
      print('[DEBUG] 現在時刻: $now');
      
      if (existingRecord != null) {
        print('[DEBUG] 既存レコード更新処理');
        print('[DEBUG] 既存レコードの完了状態: ${existingRecord.completed}');
        
        if (!existingRecord.completed) {
          print('[DEBUG] 未完了レコードを完了に更新');
          final updatedRecord = existingRecord.copyWith(
            completed: true,
            completedAt: AppDateUtils.formatDateTime(now),
            updatedAt: AppDateUtils.formatDateTime(now),
          );
          print('[DEBUG] データベース更新実行');
          await databaseHelper.updateEyedropRecord(updatedRecord);
          print('[DEBUG] データベース更新完了');
        } else {
          print('[DEBUG] 既に完了済みのため更新スキップ');
        }
      } else {
        print('[DEBUG] 新規レコード作成処理');
        final newRecord = EyedropRecord(
          date: date,
          completed: true,
          completedAt: AppDateUtils.formatDateTime(now),
          createdAt: AppDateUtils.formatDateTime(now),
          updatedAt: AppDateUtils.formatDateTime(now),
        );
        print('[DEBUG] データベース挿入実行');
        await databaseHelper.insertEyedropRecord(newRecord);
        print('[DEBUG] データベース挿入完了');
      }
      
      print('[DEBUG] 忘れ通知チェック開始');
      await checkAndScheduleMissedNotification();
      print('[DEBUG] 忘れ通知チェック完了');
    } catch (e, stackTrace) {
      print('[DEBUG] _markDateAsCompletedエラー: $e');
      print('[DEBUG] スタックトレース: $stackTrace');
    }
    
    print('[DEBUG] _markDateAsCompleted完了');
  }
}
