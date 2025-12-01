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

  Future<List<Map<String, dynamic>>> getStudentClassesByName(
    String className,
  ) async {
    final db = await dbHelper.database;
    return await db.query(
      tableName,
      columns: ['class_name'],
      where: 'class_name=?',
      whereArgs: [className],
    );
  }

  Future<bool> isStudentClassesNameExist(String className) async {
    final db = await dbHelper.database;
    var response = await db.query(
      tableName,
      columns: ['class_name'],
      where: 'class_name=?',
      whereArgs: [className],
    );
    return response.isNotEmpty;
  }
}
