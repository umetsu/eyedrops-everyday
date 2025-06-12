import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/eyedrop_record.dart';

class DatabaseHelper {
  static Database? _database;
  static const String _databaseName = 'eyedrops_everyday.db';
  static const int _databaseVersion = 1;

  static const String _tableEyedropRecords = 'eyedrop_records';

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
}
