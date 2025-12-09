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
}
