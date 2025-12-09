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
      where: 'attendanceCallerName = ?',
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
}
