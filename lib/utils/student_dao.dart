import 'package:rollcall/models/Student_model.dart';
import 'package:sqflite/sqflite.dart';

import '../configs/strings.dart';
import './database_helper.dart';

class StudentDao {
  final DatabaseHelper dbHelper; // 使用单例数据库帮助类实例
  final String tableName = KString.studentTableName;

  StudentDao(this.dbHelper);

  Future<int> insertStudent(StudentModel student) async {
    final db = await dbHelper.database;
    return await db.insert(
      tableName,
      student.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllStudents() async {
    final db = await dbHelper.database;
    return await db.query(tableName);
  }

  Future<List<Map<String, dynamic>>> getStudentsByClassName(
    String className,
  ) async {
    final db = await dbHelper.database;
    return await db.query(tableName);
  }
}
