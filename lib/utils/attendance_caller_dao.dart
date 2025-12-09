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
}
