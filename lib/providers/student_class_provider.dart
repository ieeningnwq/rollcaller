import 'package:flutter/material.dart';

import '../models/student_class_model.dart';

class StudentClassProvider with ChangeNotifier {
  final List<StudentClassModel> _studentClassList = [];

  // 获取student class列表
  List<StudentClassModel> get studentClassesList => _studentClassList;

  // student class数据发生改变
  void changeStudentClassWithoutNotify(List<StudentClassModel> newList) {
    _studentClassList.clear();
    _studentClassList.addAll(newList);
  }

  // student class数据发生改变
  void changeStudentClass(List<StudentClassModel> newList) {
    _studentClassList.clear();
    _studentClassList.addAll(newList);
    notifyListeners();
  }
}
