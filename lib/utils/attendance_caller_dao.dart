import 'package:sqflite/sqflite.dart';

import '../configs/strings.dart';
import '../models/attendance_caller_model.dart';
import 'database_helper.dart';

class AttendanceCallerDao {
  static final AttendanceCallerDao _instance = AttendanceCallerDao._internal();
  AttendanceCallerDao._internal();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  static const String tableName = KString.attendanceCallerTableName;
  factory AttendanceCallerDao() => _instance;

  Future<List<AttendanceCallerModel>> getAllAttendanceCallers() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return List.generate(maps.length, (i) {
      return AttendanceCallerModel.fromMap(maps[i]);
    });
  }

  Future<bool> isAttendanceCallerNameExist(String callerName) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'attendance_caller_name = ?',
      whereArgs: [callerName],
    );
    return maps.isNotEmpty;
  }

  Future<int> insertAttendanceCaller(
    AttendanceCallerModel attendanceCaller,
  ) async {
    final db = await _databaseHelper.database;
    final Map<String, dynamic> map = attendanceCaller.toMap();
    map.remove('id');
    return await db.insert(tableName, map);
  }

  Future<int> updateAttendanceCaller(
    AttendanceCallerModel attendanceCaller,
  ) async {
    final db = await _databaseHelper.database;
    final Map<String, dynamic> map = attendanceCaller.toMap();
    map.remove('id');
    return await db.update(
      tableName,
      map,
      where: 'id = ?',
      whereArgs: [attendanceCaller.id],
    );
  }

  Future<int> deleteAttendanceCaller(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<AttendanceCallerModel>> getAllIsNotArchiveAttendanceCallers() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'is_archive = ?',
      whereArgs: [0],
    );
    return maps.isNotEmpty
        ? maps.map((map) => AttendanceCallerModel.fromMap(map)).toList()
        : [];
  }

  Future<List<AttendanceCallerModel>> getAttendanceCallersByClassId(int classId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'class_id = ?',
      whereArgs: [classId],
    );
    return maps.isNotEmpty
        ? maps.map((map) => AttendanceCallerModel.fromMap(map)).toList()
        : [];
  }

  Future<void> deleteAllAttendanceCallers() async {
    final db = await _databaseHelper.database;
    await db.delete(tableName);
  }

  Future<void> insertAttendanceCallers(List<dynamic> backupData) async {
    final db = await _databaseHelper.database;
    for (var map in backupData) {
      await db.insert(
        tableName,
        map,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getAllAttendanceCallersMap() async {
    final db = await _databaseHelper.database;
    return await db.query(tableName);
  }
}
