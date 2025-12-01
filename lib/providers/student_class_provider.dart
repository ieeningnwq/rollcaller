import 'package:flutter/material.dart';

import '../models/student_class_model.dart';

class StudentClassProvider with ChangeNotifier {
  List<StudentClassModel> studentClassList = [];

  // student class数据发生改变
  void changeStudentClass(List<StudentClassModel> newList) {
    studentClassList.clear();
    studentClassList.addAll(newList);
    notifyListeners();
  }
}
