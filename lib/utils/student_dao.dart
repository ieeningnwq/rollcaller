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

  Future<List<StudentModel>> getAllStudents() async {
    final db = await dbHelper.database;
    var result= await db.query(tableName);
    return result.map((e) => StudentModel.fromMap(e)).toList();
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

  Future<int> updateStudentById(StudentModel student) async {
    final db = await dbHelper.database;
    return await db.update(
      tableName,
      student.toMap(),
      where: 'id=?',
      whereArgs: [student.id],
    );
  }

  Future<StudentModel?> getStudentByStudentNumber(String studentNumber) async {
    final db = await dbHelper.database;
    var mapData = await db.query(tableName, where: 'student_number=?', whereArgs: [studentNumber]);
    return mapData.isNotEmpty ? StudentModel.fromMap(mapData.first) : null; 
  }

  Future<StudentModel?> getStudentById(int studentId) async {
    final db = await dbHelper.database;
    var mapData = await db.query(tableName, where: 'id=?', whereArgs: [studentId]);
    return mapData.isNotEmpty ? StudentModel.fromMap(mapData.first) : null; 
  }

  Future<List<int>> getAllStudentIds() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT student_id FROM $tableName',
    );
    return maps.map((map) => map['student_id'] as int).toList();
  }
}
