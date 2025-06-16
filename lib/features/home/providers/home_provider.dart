import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/eyedrop_record.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/services/notification_service.dart';

class HomeProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  List<EyedropRecord> _records = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isTestMode = false;

  List<EyedropRecord> get records => _records;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  bool get isTestMode => _isTestMode;

  EyedropRecord? get todayRecord {
    final today = AppDateUtils.formatDate(DateTime.now());
    return _records.firstWhere(
      (record) => record.date == today,
      orElse: () => EyedropRecord(
        date: today,
        completed: false,
        createdAt: AppDateUtils.formatDateTime(DateTime.now()),
        updatedAt: AppDateUtils.formatDateTime(DateTime.now()),
      ),
    );
  }

  bool isDateCompleted(DateTime date) {
    final dateString = AppDateUtils.formatDate(date);
    try {
      final record = _records.firstWhere(
        (record) => record.date == dateString,
      );
      return record.completed;
    } catch (e) {
      return false;
    }
  }

  Future<void> loadRecords() async {
    _isLoading = true;
    notifyListeners();

    try {
      _records = await _databaseHelper.getEyedropRecords();
    } catch (e) {
      debugPrint('レコード読み込みエラー: $e');
      _records = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRecordsForMonth(DateTime month) async {
    _isLoading = true;
    notifyListeners();

    try {
      final startDate = AppDateUtils.formatDate(AppDateUtils.getStartOfMonth(month));
      final endDate = AppDateUtils.formatDate(AppDateUtils.getEndOfMonth(month));
      _records = await _databaseHelper.getEyedropRecordsByDateRange(startDate, endDate);
    } catch (e) {
      debugPrint('月間レコード読み込みエラー: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleEyedropStatus(String date) async {
    try {
      final existingRecord = await _databaseHelper.getEyedropRecordByDate(date);
      final now = DateTime.now();
      
      if (existingRecord != null) {
        final updatedRecord = existingRecord.copyWith(
          completed: !existingRecord.completed,
          completedAt: !existingRecord.completed ? AppDateUtils.formatDateTime(now) : null,
          updatedAt: AppDateUtils.formatDateTime(now),
        );
        await _databaseHelper.updateEyedropRecord(updatedRecord);
        
        final index = _records.indexWhere((record) => record.date == date);
        if (index != -1) {
          _records[index] = updatedRecord;
        } else {
          _records.add(updatedRecord);
        }
      } else {
        final newRecord = EyedropRecord(
          date: date,
          completed: true,
          completedAt: AppDateUtils.formatDateTime(now),
          createdAt: AppDateUtils.formatDateTime(now),
          updatedAt: AppDateUtils.formatDateTime(now),
        );
        await _databaseHelper.insertEyedropRecord(newRecord);
        _records.add(newRecord);
      }
      
      notifyListeners();
      
      final notificationService = NotificationService();
      await notificationService.checkAndScheduleMissedNotification();
    } catch (e) {
      debugPrint('点眼状態切替エラー: $e');
    }
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setTestMode() {
    _isTestMode = true;
    _isLoading = false;
    _records = [];
    _selectedDate = DateTime.now();
    notifyListeners();
  }

  void forceNotLoading() {
    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleEyedropStatusForTest(String date) async {
    final existingRecordIndex = _records.indexWhere((record) => record.date == date);
    final now = DateTime.now();
    
    if (existingRecordIndex != -1) {
      final existingRecord = _records[existingRecordIndex];
      final updatedRecord = existingRecord.copyWith(
        completed: !existingRecord.completed,
        completedAt: !existingRecord.completed ? AppDateUtils.formatDateTime(now) : null,
        updatedAt: AppDateUtils.formatDateTime(now),
      );
      _records[existingRecordIndex] = updatedRecord;
    } else {
      final newRecord = EyedropRecord(
        date: date,
        completed: true,
        completedAt: AppDateUtils.formatDateTime(now),
        createdAt: AppDateUtils.formatDateTime(now),
        updatedAt: AppDateUtils.formatDateTime(now),
      );
      _records.add(newRecord);
    }
    
    notifyListeners();
  }
}
