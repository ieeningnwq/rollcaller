import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../configs/strings.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDb();
    return _database!;
  }

  Future<Database> initDb() async {
    final String databasesPath = join(
      await getDatabasesPath(),
      KString.databaseName,
    );
    return await openDatabase(databasesPath, version: 1, onCreate: _createDb);
  }

  void _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${KString.studentClassTableName} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_name TEXT NOT NULL UNIQUE,
        student_quantity INTEGER NOT NULL,
        teacher_name TEXT,
        notes TEXT,
        created TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE ${KString.studentTableName} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_number TEXT NOT NULL UNIQUE,
        student_name TEXT NOT NULL,
        class_name TEXT,
        created TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE ${KString.randomCallerTableName} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        random_caller_name TEXT NOT NULL,
        is_duplicate INTEGER NOT NULL DEFAULT 0,
        class_id INTEGER NOT NULL,
        notes TEXT,
        created TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE ${KString.randomCallerRecordTableName} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        random_caller_id INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        score INTEGER NOT NULL,
        created TEXT NOT NULL
      )
    ''');
  }
}
