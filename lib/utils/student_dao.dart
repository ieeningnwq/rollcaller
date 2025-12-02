import 'package:sqflite/sqflite.dart';

import '../configs/strings.dart';
import '../models/student_model.dart';
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

  Future<List<Map<String, dynamic>>> getAllStudentsByClassName(
    String className,
  ) async {
    final db = await dbHelper.database;
    return await db.query(
      tableName,
      where:
          'class_name like ? or class_name like ? or class_name like ? or class_name=?',
      whereArgs: ['$className,', ',$className', ',%$className,', className],
    );
  }

  Future<bool> isStudentNumberExist(String studentNumber) async {
    final db = await dbHelper.database;
    var response = await db.query(
      tableName,
      columns: ['student_number'],
      where: 'student_number=?',
      whereArgs: [studentNumber],
    );
    return response.isNotEmpty;
  }

  Future<void> updateStudentClassByClassName(StudentModel student) async {
    final db = await dbHelper.database;
    await db.update(
      tableName,
      student.toMap(),
      where: 'student_number=?',
      whereArgs: [student.studentNumber],
    );
  }
}
