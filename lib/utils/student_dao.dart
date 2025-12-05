import 'package:sqflite/sqflite.dart';

import '../configs/strings.dart';
import '../models/student_model.dart';
import './database_helper.dart';

class StudentDao {
  static final StudentDao _instance = StudentDao._internal();
  final DatabaseHelper dbHelper = DatabaseHelper(); // 使用单例数据库帮助类实例
  final String tableName = KString.studentTableName;

  StudentDao._internal();

  factory StudentDao() => _instance;

  Future<int> insertStudent(StudentModel student) async {
    final db = await dbHelper.database;
    return await db.insert(
      tableName,
      student.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
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
      where: 'INSTR("," || class_name || ",", ?) > 0',
      whereArgs: [',$className,'],
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

  Future<void> deleteStudentById(int? id) async {
    final db = await dbHelper.database;
    await db.delete(tableName, where: 'id=?', whereArgs: [id]);
  }

  Future<void> updateStudentClassById(StudentModel student) async {
    final db = await dbHelper.database;
    await db.update(
      tableName,
      student.toMap(),
      where: 'id=?',
      whereArgs: [student.id],
    );
  }
}
