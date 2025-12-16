import 'dart:io' show Platform, Directory;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
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
    String databasesPath;

    // 根据平台类型选择不同的数据库路径和初始化方式
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Windows平台使用sqflite_common_ffi
      sqfliteFfiInit();
      // 使用getDatabasesPath可能在Windows上返回空路径，需要处理
      databasesPath = await databaseFactoryFfi.getDatabasesPath();
      if (databasesPath.isEmpty) {
        // 如果路径为空，使用当前目录或文档目录
        databasesPath = Directory.current.path;
      }
      databasesPath = join(databasesPath, KString.databaseName);
      return await databaseFactoryFfi.openDatabase(
        databasesPath,
        options: OpenDatabaseOptions(version: 1, onCreate: _createDb),
      );
    } else {
      // 移动端使用原生sqflite
      databasesPath = join(await getDatabasesPath(), KString.databaseName);
      return await openDatabase(databasesPath, version: 1, onCreate: _createDb);
    }
  }

  void _createDb(Database db, int version) async {
    // 学生班级表格
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
    // 学生表格
    await db.execute('''
      CREATE TABLE ${KString.studentTableName} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_number TEXT NOT NULL UNIQUE,
        student_name TEXT NOT NULL,
        created TEXT NOT NULL
      )
    ''');
    // 学生班级关系表格
    await db.execute('''
      CREATE TABLE ${KString.studentClassRelationTableName} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        class_id INTEGER NOT NULL
      )
    ''');
    // 随机点名表格
    await db.execute('''
      CREATE TABLE ${KString.randomCallerTableName} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        random_caller_name TEXT NOT NULL UNIQUE,
        is_duplicate INTEGER NOT NULL DEFAULT 0,
        class_id INTEGER NOT NULL,
        is_archive INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        created TEXT NOT NULL
      )
    ''');
    // 随机点名记录表格
    await db.execute('''
      CREATE TABLE ${KString.randomCallerRecordTableName} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        random_caller_id INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        score INTEGER NOT NULL,
        notes TEXT,
        created TEXT NOT NULL
      )
    ''');
    // 出勤点名表格
    await db.execute('''
      CREATE TABLE ${KString.attendanceCallerTableName} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        attendance_caller_name TEXT NOT NULL UNIQUE,
        class_id INTEGER NOT NULL,
        is_archive INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        created TEXT NOT NULL
      )
    ''');
    // 出勤点名记录表格
    await db.execute('''
      CREATE TABLE ${KString.attendanceCallerRecordTableName} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        attendance_caller_id INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        present INTEGER NOT NULL,
        notes TEXT,
        created TEXT NOT NULL
      )
    ''');
  }
}
