import 'package:rollcall/configs/strings.dart';

import '../models/roll_caller_model.dart';
import 'database_helper.dart';

class RollCallerDao {
  static final RollCallerDao _instance = RollCallerDao._internal();
  RollCallerDao._internal();
  final DatabaseHelper dbHelper = DatabaseHelper(); // 使用单例数据库帮助类实例
  static const String tableName = KString.randomCallerTableName;
  factory RollCallerDao() => _instance;

  Future<int> insertRollCaller(RollCallerModel rollCallerModel) async {
    final db = await dbHelper.database;
    return await db.insert(tableName, rollCallerModel.toMap());
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
}
