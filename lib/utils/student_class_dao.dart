import 'package:sqflite/sqflite.dart';

import '../configs/strings.dart';
import '../models/student_class_model.dart';
import './database_helper.dart';

class StudentClassDao {
  static final StudentClassDao _instance = StudentClassDao._internal();
  final DatabaseHelper dbHelper = DatabaseHelper(); // 使用单例数据库帮助类实例
  final String tableName = KString.studentClassTableName;

  StudentClassDao._internal();

  factory StudentClassDao() => _instance;

  Future<int> insertStudentClass(StudentClassModel studentClass) async {
    final db = await dbHelper.database;
    var mapData = _processMap(studentClass);
    return await db.insert(
      tableName,
      mapData,
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

  Future<void> deleteStudentClassById(int id) async {
    final db = await dbHelper.database;
    await db.delete(tableName, where: 'id=?', whereArgs: [id]);
  }

  Future<void> updateStudentClassByClassName(
    StudentClassModel studentClassModel,
  ) async {
    var mapData = _processMap(studentClassModel);
    final db = await dbHelper.database;
    await db.update(
      tableName,
      mapData,
      where: 'class_name=?',
      whereArgs: [studentClassModel.className],
    );
  }

  Future<void> deleteStudentClassByClassName(String className) async {
    final db = await dbHelper.database;
    await db.delete(tableName, where: 'class_name=?', whereArgs: [className]);
  }

   Future<int> updateStudentClassById(StudentClassModel studentClassModel) async {
    Map<String, dynamic> mapData = _processMap(studentClassModel);
    final db = await dbHelper.database;
    return await db.update(
      tableName,
      mapData,
      where: 'id=?',
      whereArgs: [studentClassModel.id],
    );
  }

  Map<String, dynamic> _processMap(StudentClassModel studentClassModel) {
    var mapData = studentClassModel.toMap();
    mapData.remove('class_quantity');
    return mapData;
  }
}
