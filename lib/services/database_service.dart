import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(
      databasePath,
      'adhunik_01.db',
    );

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE employees (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            punchingId TEXT NOT NULL UNIQUE,
            name TEXT NOT NULL,
            workerType TEXT NOT NULL,
            designation TEXT NOT NULL,
            department TEXT NOT NULL,
            mobile TEXT NOT NULL,
            joiningDate TEXT NOT NULL,
            shift TEXT NOT NULL,
            photoPath TEXT,
            faceData TEXT,
            isActive INTEGER NOT NULL DEFAULT 1,
            createdAt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE punches (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            punchId TEXT NOT NULL UNIQUE,
            employeePunchingId TEXT NOT NULL,
            employeeName TEXT NOT NULL,
            punchType TEXT NOT NULL,
            punchTime TEXT NOT NULL,
            latitude REAL,
            longitude REAL,
            photoPath TEXT,
            synced INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE attendance (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            employeePunchingId TEXT NOT NULL,
            date TEXT NOT NULL,
            punchIn TEXT,
            punchOut TEXT,
            workingMinutes INTEGER NOT NULL DEFAULT 0,
            overtimeMinutes INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL,
            UNIQUE(employeePunchingId, date)
          )
        ''');

        await db.execute('''
          CREATE TABLE sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            recordType TEXT NOT NULL,
            recordId TEXT NOT NULL,
            data TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  // ------------------------------------------------------------
  // EMPLOYEE
  // ------------------------------------------------------------

  static Future<int> addEmployee(
    Map<String, dynamic> employee,
  ) async {
    final db = await database;

    return db.insert(
      'employees',
      employee,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getEmployees({
    bool activeOnly = false,
  }) async {
    final db = await database;

    if (activeOnly) {
      return db.query(
        'employees',
        where: 'isActive = ?',
        whereArgs: [1],
        orderBy: 'name ASC',
      );
    }

    return db.query(
      'employees',
      orderBy: 'name ASC',
    );
  }

  static Future<Map<String, dynamic>?> getEmployeeByPunchingId(
    String punchingId,
  ) async {
    final db = await database;

    final result = await db.query(
      'employees',
      where: 'punchingId = ?',
      whereArgs: [punchingId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  static Future<int> updateEmployee(
    String punchingId,
    Map<String, dynamic> employee,
  ) async {
    final db = await database;

    return db.update(
      'employees',
      employee,
      where: 'punchingId = ?',
      whereArgs: [punchingId],
    );
  }

  static Future<int> deactivateEmployee(
    String punchingId,
  ) async {
    final db = await database;

    return db.update(
      'employees',
      {
        'isActive': 0,
      },
      where: 'punchingId = ?',
      whereArgs: [punchingId],
    );
  }

  // ------------------------------------------------------------
  // PUNCH
  // ------------------------------------------------------------

  static Future<int> addPunch(
    Map<String, dynamic> punch,
  ) async {
    final db = await database;

    return db.insert(
      'punches',
      punch,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<List<Map<String, dynamic>>> getPunches({
    String? employeePunchingId,
    String? date,
  }) async {
    final db = await database;

    final conditions = <String>[];
    final arguments = <dynamic>[];

    if (employeePunchingId != null) {
      conditions.add('employeePunchingId = ?');
      arguments.add(employeePunchingId);
    }

    if (date != null) {
      conditions.add('substr(punchTime, 1, 10) = ?');
      arguments.add(date);
    }

    return db.query(
      'punches',
      where: conditions.isEmpty
          ? null
          : conditions.join(' AND '),
      whereArgs: arguments.isEmpty ? null : arguments,
      orderBy: 'punchTime DESC',
    );
  }

  static Future<List<Map<String, dynamic>>> getUnsyncedPunches() async {
    final db = await database;

    return db.query(
      'punches',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'createdAt ASC',
    );
  }

  static Future<int> markPunchSynced(
    String punchId,
  ) async {
    final db = await database;

    return db.update(
      'punches',
      {
        'synced': 1,
      },
      where: 'punchId = ?',
      whereArgs: [punchId],
    );
  }

  // ------------------------------------------------------------
  // ATTENDANCE
  // ------------------------------------------------------------

  static Future<int> saveAttendance(
    Map<String, dynamic> attendance,
  ) async {
    final db = await database;

    return db.insert(
      'attendance',
      attendance,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Map<String, dynamic>?> getAttendance(
    String employeePunchingId,
    String date,
  ) async {
    final db = await database;

    final result = await db.query(
      'attendance',
      where: 'employeePunchingId = ? AND date = ?',
      whereArgs: [
        employeePunchingId,
        date,
      ],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  static Future<List<Map<String, dynamic>>> getAttendanceHistory({
    String? employeePunchingId,
    String? fromDate,
    String? toDate,
  }) async {
    final db = await database;

    final conditions = <String>[];
    final arguments = <dynamic>[];

    if (employeePunchingId != null) {
      conditions.add('employeePunchingId = ?');
      arguments.add(employeePunchingId);
    }

    if (fromDate != null) {
      conditions.add('date >= ?');
      arguments.add(fromDate);
    }

    if (toDate != null) {
      conditions.add('date <= ?');
      arguments.add(toDate);
    }

    return db.query(
      'attendance',
      where: conditions.isEmpty
          ? null
          : conditions.join(' AND '),
      whereArgs: arguments.isEmpty ? null : arguments,
      orderBy: 'date DESC',
    );
  }

  // ------------------------------------------------------------
  // OFFLINE SYNC QUEUE
  // ------------------------------------------------------------

  static Future<int> addToSyncQueue({
    required String recordType,
    required String recordId,
    required String data,
  }) async {
    final db = await database;

    return db.insert(
      'sync_queue',
      {
        'recordType': recordType,
        'recordId': recordId,
        'data': data,
        'createdAt': DateTime.now().toIso8601String(),
        'synced': 0,
      },
    );
  }

  static Future<List<Map<String, dynamic>>> getPendingSyncQueue() async {
    final db = await database;

    return db.query(
      'sync_queue',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'createdAt ASC',
    );
  }

  static Future<int> markSyncQueueItemSynced(
    int id,
  ) async {
    final db = await database;

    return db.update(
      'sync_queue',
      {
        'synced': 1,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ------------------------------------------------------------
  // DATABASE CLOSE
  // ------------------------------------------------------------

  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
