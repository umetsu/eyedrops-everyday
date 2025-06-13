import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/eyedrop_record.dart';
import 'models/pressure_record.dart';

class DatabaseHelper {
  static Database? _database;
  static const String _databaseName = 'eyedrops_everyday.db';
  static const int _databaseVersion = 2;

  static const String _tableEyedropRecords = 'eyedrop_records';
  static const String _tablePressureRecords = 'pressure_records';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableEyedropRecords (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        completed BOOLEAN NOT NULL DEFAULT 0,
        completed_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_eyedrop_records_date ON $_tableEyedropRecords(date)
    ''');

    if (version >= 2) {
      await _createPressureTable(db);
    }
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createPressureTable(db);
    }
  }

  static Future<void> _createPressureTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_tablePressureRecords (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        pressure_value REAL NOT NULL,
        eye_type TEXT NOT NULL,
        measured_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_pressure_records_date ON $_tablePressureRecords(date)
    ''');

    await db.execute('''
      CREATE INDEX idx_pressure_records_measured_at ON $_tablePressureRecords(measured_at)
    ''');
  }

  Future<int> insertEyedropRecord(EyedropRecord record) async {
    final db = await database;
    return await db.insert(_tableEyedropRecords, record.toMap());
  }

  Future<List<EyedropRecord>> getEyedropRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableEyedropRecords,
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return EyedropRecord.fromMap(maps[i]);
    });
  }

  Future<EyedropRecord?> getEyedropRecordByDate(String date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableEyedropRecords,
      where: 'date = ?',
      whereArgs: [date],
    );
    if (maps.isNotEmpty) {
      return EyedropRecord.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateEyedropRecord(EyedropRecord record) async {
    final db = await database;
    return await db.update(
      _tableEyedropRecords,
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteEyedropRecord(int id) async {
    final db = await database;
    return await db.delete(
      _tableEyedropRecords,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<EyedropRecord>> getEyedropRecordsByDateRange(
      String startDate, String endDate) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableEyedropRecords,
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
    return List.generate(maps.length, (i) {
      return EyedropRecord.fromMap(maps[i]);
    });
  }

  Future<int> insertPressureRecord(PressureRecord record) async {
    final db = await database;
    return await db.insert(_tablePressureRecords, record.toMap());
  }

  Future<List<PressureRecord>> getPressureRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tablePressureRecords,
      orderBy: 'measured_at DESC',
    );
    return List.generate(maps.length, (i) {
      return PressureRecord.fromMap(maps[i]);
    });
  }

  Future<List<PressureRecord>> getPressureRecordsByDateRange(
      String startDate, String endDate) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tablePressureRecords,
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'measured_at ASC',
    );
    return List.generate(maps.length, (i) {
      return PressureRecord.fromMap(maps[i]);
    });
  }

  Future<int> updatePressureRecord(PressureRecord record) async {
    final db = await database;
    return await db.update(
      _tablePressureRecords,
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deletePressureRecord(int id) async {
    final db = await database;
    return await db.delete(
      _tablePressureRecords,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
