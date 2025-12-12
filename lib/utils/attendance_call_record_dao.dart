import 'package:sqflite/sqflite.dart';

import '../configs/strings.dart';
import '../models/attendance_call_record.dart';
import 'database_helper.dart';

class AttendanceCallRecordDao {
  static final AttendanceCallRecordDao _instance =
      AttendanceCallRecordDao._internal();
  AttendanceCallRecordDao._internal();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  static const String tableName = KString.attendanceCallerRecordTableName;
  factory AttendanceCallRecordDao() => _instance;

  Future<List<AttendanceCallRecordModel>> getRecordsByCallerIdByConditions({
    required List<String> conditions,
    required List<dynamic> whereArgs,
  }) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: conditions.join(' '),
      whereArgs: whereArgs,
    );

    return List.generate(
      maps.length,
      (i) => AttendanceCallRecordModel.fromMap(maps[i]),
    );
  }

  Future<List<AttendanceCallRecordModel>> getRecordsByCallerId({
    required int callerId,
  }) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'attendance_caller_id = ?',
      whereArgs: [callerId],
    );

    return List.generate(
      maps.length,
      (i) => AttendanceCallRecordModel.fromMap(maps[i]),
    );
  }

  Future<int> insertAttendanceCallRecord(
    AttendanceCallRecordModel attendanceCallRecordModel,
  ) async {
    final db = await _databaseHelper.database;
    return await db.insert(tableName, attendanceCallRecordModel.toMap());
  }

  Future<int> updateAttendanceCallRecord(
    AttendanceCallRecordModel attendanceCallRecordModel,
  ) async {
    final db = await _databaseHelper.database;
    return await db.update(
      tableName,
      attendanceCallRecordModel.toMap(),
      where: 'id = ?',
      whereArgs: [attendanceCallRecordModel.id],
    );
  }

  Future<int> deleteAttendanceCallRecord(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAttendanceCallRecordById(int recordId) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  Future<List<AttendanceCallRecordModel>> getAttendanceCallRecordsByCallerId(int callerId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'attendance_caller_id = ?',
      whereArgs: [callerId],
    );

    return List.generate(
      maps.length,
      (i) => AttendanceCallRecordModel.fromMap(maps[i]),
    );
  }

  Future<List<AttendanceCallRecordModel>> getAttendanceCallRecordsByStudentId(int studentId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'student_id = ?',
      whereArgs: [studentId],
    );

    return List.generate(
      maps.length,
      (i) => AttendanceCallRecordModel.fromMap(maps[i]),
    );
  }

  Future<List<AttendanceCallRecordModel>> getAllAttendanceCallerRecords() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
    );
    return List.generate(
      maps.length,
      (i) => AttendanceCallRecordModel.fromMap(maps[i]),
    );
  }

  Future<void> deleteAllAttendanceCallerRecords() async {
    final db = await _databaseHelper.database;
    await db.delete(tableName);
  }

  Future<void> insertAttendanceCallRecords(List<dynamic> backupData) async {
    final db = await _databaseHelper.database;
    for (var map in backupData) {
      await db.insert(
        tableName,
        map,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getAllAttendanceCallerRecordsMap() async {
    final db = await _databaseHelper.database;
    return await db.query(tableName);
  }
}
