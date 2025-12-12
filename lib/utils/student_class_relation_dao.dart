import 'package:sqflite/sqflite.dart';

import '../configs/strings.dart';
import 'database_helper.dart';

class StudentClassRelationDao {
  static final StudentClassRelationDao _instance = StudentClassRelationDao._internal();
  final DatabaseHelper dbHelper = DatabaseHelper(); // 使用单例数据库帮助类实例
  final String tableName = KString.studentClassRelationTableName;

  StudentClassRelationDao._internal();

  factory StudentClassRelationDao() => _instance;

  Future<List<int>> getAllClassIdsByStudentId(int studentId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      columns: ['class_id'],
      where: 'student_id = ?',
      whereArgs: [studentId],
    );
    return maps.map((map) => map['class_id'] as int).toList();
  }

  Future<List<int>> getAllStudentIdsByClassId(int classId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      columns: ['student_id'],
      where: 'class_id = ?',
      whereArgs: [classId],
    );
    return maps.map((map) => map['student_id'] as int).toList();
  }

  Future<void> insertStudentClasses(int studentId, List<int> classIds) async {
    final db = await dbHelper.database;
    for (int classId in classIds) {
      await db.insert(
        tableName,
        {
          'student_id': studentId,
          'class_id': classId,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

   Future<int> deleteStudentClasses(int studentId) async {
    final db = await dbHelper.database;
    return await db.delete(
      tableName,
      where: 'student_id = ?',
      whereArgs: [studentId],
    );
  }

  Future<bool> isStudentClassRelationExist(int? studentId, int classId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      columns: ['id'],
      where: 'student_id = ? AND class_id = ?',
      whereArgs: [studentId, classId],
    );
    return maps.isNotEmpty;
  }

  Future<int> insertStudentClassRelation(Map<String, int?> map) async {
    final db = await dbHelper.database;
    return await db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
}