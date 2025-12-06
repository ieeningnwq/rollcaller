import 'dart:developer';
import 'package:flutter/material.dart';
import '../models/student_class_model.dart';

class StudentClassProvider with ChangeNotifier {
  final Map<int, StudentClassModel> _studentClass = {};

  final Map<int, Icon> _icon = {};
  final Map<int, Color> _color = {};
  final Map<int, Color> _deprecationColor = {};
  final Map<int, String> _quantityInfo = {};

  List<Icon> get icon => _icon.values.toList();
  List<Color> get color => _color.values.toList();
  List<String> get quantityInfo => _quantityInfo.values.toList();
  List<Color> get deprecationColor => _deprecationColor.values.toList();

  // 获取student class列表
  List<StudentClassModel> get studentClassesList =>
      _studentClass.values.toList();

  // 清除所有信息重新设置
  void _clear() {
    _studentClass.clear();
    _icon.clear();
    _color.clear();
    _quantityInfo.clear();
    _deprecationColor.clear();
  }

  // student class数据发生改变
  Future<void> changeStudentClassWithoutNotify(
    List<StudentClassModel> newList,
  ) async {
    // 清除所有信息重新设置
    _clear();
    for (var element in newList) {
      _studentClass.putIfAbsent(element.id!, () => element);
      _addIconColorQuantityInfo(element);
    }
    log(_studentClass.toString());
  }

  void _addIconColorQuantityInfo(StudentClassModel element) {
    int classQuantity = element.classQuantity;
    _icon.putIfAbsent(
      element.id!,
      () => classQuantity == element.studentQuantity
          ? Icon(Icons.check_circle, size: 16, color: Colors.green)
          : classQuantity < element.studentQuantity
          ? Icon(Icons.warning_amber, size: 16, color: Colors.yellow)
          : Icon(Icons.error, size: 16, color: Colors.red),
    );
    _color.putIfAbsent(
      element.id!,
      () => classQuantity == element.studentQuantity
          ? Colors.green
          : classQuantity < element.studentQuantity
          ? Colors.yellow
          : Colors.red,
    );
    _deprecationColor.putIfAbsent(
      element.id!,
      () => classQuantity == element.studentQuantity
          ? Colors.green.shade100
          : classQuantity < element.studentQuantity
          ? Colors.yellow.shade100
          : Colors.red.shade100,
    );
    _quantityInfo.putIfAbsent(
      element.id!,
      () => classQuantity == element.studentQuantity
          ? '人数已满'
          : classQuantity < element.studentQuantity
          ? '人数未满'
          : '人数超员',
    );
  }

  // student class数据发生改变
  void changeStudentClass(List<StudentClassModel> newList) {
    changeStudentClassWithoutNotify(newList);
    notifyListeners();
  }

  void addStudentClass(StudentClassModel studentClass) {
    _studentClass.putIfAbsent(studentClass.id!, () => studentClass);
    _addIconColorQuantityInfo(studentClass);
    notifyListeners();
  }

  Future<void> updateStudentClass(StudentClassModel studentClass) async {
    _studentClass.update(studentClass.id!, (value) => studentClass);
    _updateIconColorQuantityInfo(studentClass);
    notifyListeners();
  }

  Future<void> _updateIconColorQuantityInfo(
    StudentClassModel studentClass,
  ) async {
    int classQuantity = studentClass.classQuantity;

    _icon.update(
      studentClass.id!,
      (value) => classQuantity == studentClass.studentQuantity
          ? Icon(Icons.check_circle, size: 16, color: Colors.green)
          : classQuantity < studentClass.studentQuantity
          ? Icon(Icons.warning_amber, size: 16, color: Colors.yellow)
          : Icon(Icons.error, size: 16, color: Colors.red),
    );
    _color.update(
      studentClass.id!,
      (value) => classQuantity == studentClass.studentQuantity
          ? Colors.green
          : classQuantity < studentClass.studentQuantity
          ? Colors.yellow
          : Colors.red,
    );
    _deprecationColor.update(
      studentClass.id!,
      (value) => classQuantity == studentClass.studentQuantity
          ? Colors.green.shade100
          : classQuantity < studentClass.studentQuantity
          ? Colors.yellow.shade100
          : Colors.red.shade100,
    );
    _quantityInfo.update(
      studentClass.id!,
      (value) => classQuantity == studentClass.studentQuantity
          ? '人数已满'
          : classQuantity < studentClass.studentQuantity
          ? '人数未满'
          : '人数超员',
    );
  }

  void removeStudentClass(int id) {
    _studentClass.remove(id);
    _icon.remove(id);
    _color.remove(id);
    _quantityInfo.remove(id);
    _deprecationColor.remove(id);
    notifyListeners();
  }
}
