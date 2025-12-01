import 'package:sqflite/sqflite.dart';

import '../configs/strings.dart';
import '../models/student_class_model.dart';
import './database_helper.dart';

class StudentClassDao {
  final DatabaseHelper dbHelper; // 使用单例数据库帮助类实例
  final String tableName = KString.studentClassTableName;

  StudentClassDao(this.dbHelper);

  Future<int> insertStudentClass(StudentClassModel studentClass) async {
    final db = await dbHelper.database;
    return await db.insert(
      tableName,
      studentClass.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllStudentClasses() async {
    final db = await dbHelper.database;
    return await db.query(tableName);
  }
}
