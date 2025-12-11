import '../configs/strings.dart';
import '../models/random_call_record.dart';
import 'database_helper.dart';

class RandomCallRecordDao {
  static final RandomCallRecordDao _instance = RandomCallRecordDao._internal();
  RandomCallRecordDao._internal();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  static const String tableName = KString.randomCallerRecordTableName;
  factory RandomCallRecordDao() => _instance;

  Future<List<RandomCallRecordModel>> getRecordsByCallerIdStudentId(
    int callerId,
    int studentId,
  ) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'random_caller_id = ? AND student_id = ?',
      whereArgs: [callerId, studentId],
    );
    return List.generate(
      maps.length,
      (i) => RandomCallRecordModel.fromMap(maps[i]),
    );
  }

  Future<List<RandomCallRecordModel>> getRecordsByCallerId({
    required int callerId,
  }) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'random_caller_id = ?',
      whereArgs: [callerId],
    );
    return List.generate(
      maps.length,
      (i) => RandomCallRecordModel.fromMap(maps[i]),
    );
  }

  Future<List<RandomCallRecordModel>> getRecordsByCallerIdByConditions({
    required List<String> conditions,
    required List<dynamic> whereArgs,
  }) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: conditions.join(' '),
      whereArgs: whereArgs,
    );
    List<RandomCallRecordModel> randomCallRecords = [];
    for (var map in maps) {
      randomCallRecords.add(RandomCallRecordModel.fromMap(map));
    }
    return randomCallRecords;
    // return List.generate(
    //   maps.length,
    //   (i) => RandomCallRecordModel.fromMap(maps[i]),
    // );
  }

  Future<int> insertRandomCallRecord(
    RandomCallRecordModel randomCallRecordModel,
  ) async {
    final db = await _databaseHelper.database;
    return await db.insert(tableName, randomCallRecordModel.toMap());
  }

  Future<int> update(RandomCallRecordModel record) async {
    final db = await _databaseHelper.database;
    return await db.update(
      tableName,
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<RandomCallRecordModel>> getRandomCallRecordsByStudentId(int studentId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'student_id = ?',
      whereArgs: [studentId],
    );
    return List.generate(
      maps.length,
      (i) => RandomCallRecordModel.fromMap(maps[i]),
    );
  }

  Future<List<RandomCallRecordModel>> getRandomCallRecordsByCallerId(int callerId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'random_caller_id = ?',
      whereArgs: [callerId],
    );
    return List.generate(
      maps.length,
      (i) => RandomCallRecordModel.fromMap(maps[i]),
    );
  }
}
