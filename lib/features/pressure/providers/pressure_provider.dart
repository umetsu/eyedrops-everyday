import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/pressure_record.dart';
import '../../../core/utils/date_utils.dart';

class PressureProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  List<PressureRecord> _records = [];
  bool _isLoading = false;
  String _selectedPeriod = '1ヶ月';
  bool _testMode = false;

  PressureProvider({bool testMode = false}) {
    _testMode = testMode;
    if (!_testMode) {
      loadRecordsForPeriod(_selectedPeriod);
    } else {
      _isLoading = false;
    }
  }

  List<PressureRecord> get records => _records;
  bool get isLoading => _isLoading;
  String get selectedPeriod => _selectedPeriod;

  List<String> get availablePeriods => ['1ヶ月', '3ヶ月', '6ヶ月', '1年'];

  Future<void> loadRecords() async {
    _isLoading = true;
    notifyListeners();

    try {
      _records = await _databaseHelper.getPressureRecords();
    } catch (e) {
      debugPrint('眼圧レコード読み込みエラー: $e');
      _records = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRecordsForPeriod(String period) async {
    _selectedPeriod = period;
    
    // Skip database operations in test mode
    if (_testMode) {
      return;
    }
    
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      DateTime startDate;
      
      switch (period) {
        case '1ヶ月':
          startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case '3ヶ月':
          startDate = DateTime(now.year, now.month - 3, now.day);
          break;
        case '6ヶ月':
          startDate = DateTime(now.year, now.month - 6, now.day);
          break;
        case '1年':
          startDate = DateTime(now.year - 1, now.month, now.day);
          break;
        default:
          startDate = DateTime(now.year, now.month - 1, now.day);
      }

      final startDateString = AppDateUtils.formatDate(startDate);
      final endDateString = AppDateUtils.formatDate(now);
      
      _records = await _databaseHelper.getPressureRecordsByDateRange(
        startDateString, 
        endDateString
      );
    } catch (e) {
      debugPrint('期間別眼圧レコード読み込みエラー: $e');
      _records = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPressureRecord({
    required DateTime date,
    required double leftPressure,
    required double rightPressure,
  }) async {
    try {
      final now = DateTime.now();
      final dateString = AppDateUtils.formatDate(date);
      final measuredAtString = AppDateUtils.formatDateTime(now);

      if (leftPressure > 0) {
        final leftRecord = PressureRecord(
          date: dateString,
          pressureValue: leftPressure,
          eyeType: 'left',
          measuredAt: measuredAtString,
          createdAt: measuredAtString,
          updatedAt: measuredAtString,
        );
        await _databaseHelper.insertPressureRecord(leftRecord);
      }

      if (rightPressure > 0) {
        final rightRecord = PressureRecord(
          date: dateString,
          pressureValue: rightPressure,
          eyeType: 'right',
          measuredAt: measuredAtString,
          createdAt: measuredAtString,
          updatedAt: measuredAtString,
        );
        await _databaseHelper.insertPressureRecord(rightRecord);
      }

      await loadRecordsForPeriod(_selectedPeriod);
    } catch (e) {
      debugPrint('眼圧レコード追加エラー: $e');
    }
  }

  List<PressureRecord> getRecordsForEye(String eyeType) {
    return _records.where((record) => record.eyeType == eyeType).toList();
  }

  void setTestMode() {
    _testMode = true;
    _isLoading = false;
    _records = [];
    _selectedPeriod = '1ヶ月';
    notifyListeners();
  }
}
