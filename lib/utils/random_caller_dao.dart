import 'package:rollcall/configs/strings.dart';

import '../models/random_caller_model.dart';
import 'database_helper.dart';

class RandomCallerDao {
  static final RandomCallerDao _instance = RandomCallerDao._internal();
  RandomCallerDao._internal();
  final DatabaseHelper dbHelper = DatabaseHelper(); // 使用单例数据库帮助类实例
  static const String tableName = KString.randomCallerTableName;
  factory RandomCallerDao() => _instance;

  Future<int> insertRandomCaller(RandomCallerModel randomCallerModel) async {
    final db = await dbHelper.database;
    return await db.insert(tableName, randomCallerModel.toMap());
  }

  Future<bool> isRollCallerNameExist(String value) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      columns: ['random_caller_name'],
      where: 'random_caller_name = ?',
      whereArgs: [value],
    );
    return maps.isNotEmpty;
  }

  Future<List<RandomCallerModel>> getAllRandomCallers() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return maps.isNotEmpty
        ? maps.map((map) => RandomCallerModel.fromMap(map)).toList()
        : [];
  }

  Future<int> updateRandomCaller(RandomCallerModel randomCallerModel) async {
    final db = await dbHelper.database;
    return await db.update(
      tableName,
      randomCallerModel.toMap(),
      where: 'id = ?',
      whereArgs: [randomCallerModel.id],
    );
  }

  Future<int> deleteRandomCaller(int id) async {
    final db = await dbHelper.database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<RandomCallerModel>> getAllIsNotArchiveRandomCallers() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'is_archive = ?',
      whereArgs: [0],
    );
    return maps.isNotEmpty
        ? maps.map((map) => RandomCallerModel.fromMap(map)).toList()
        : [];
  }

  Future<List<RandomCallerModel>> getRandomCallersByClassId(int classId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'class_id = ?',
      whereArgs: [classId],
    );
    return maps.isNotEmpty
        ? maps.map((map) => RandomCallerModel.fromMap(map)).toList()
        : [];
  }
}
