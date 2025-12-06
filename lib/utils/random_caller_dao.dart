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

  Future<List<RandomCallerModel>>? getAllRandomCallers() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return maps.isNotEmpty
        ? maps.map((map) => RandomCallerModel.fromMap(map)).toList()
        : [];
  }
}
