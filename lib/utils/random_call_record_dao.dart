import '../configs/strings.dart';
import '../models/random_call_record.dart';
import 'database_helper.dart';

class RandomCallRecordDao {
  static final RandomCallRecordDao _instance = RandomCallRecordDao._internal();
  RandomCallRecordDao._internal();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  static const String tableName = KString.randomCallerRecordTableName;
  factory RandomCallRecordDao() => _instance;


  Future<List<RandomCallRecordModel>> getRecordsByCallerIdStudentId(int callerId, int studentId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'random_caller_id = ? AND student_id = ?',
      whereArgs: [callerId, studentId],
    );
    return List.generate(maps.length, (i) => RandomCallRecordModel.fromMap(maps[i]));
  }
}