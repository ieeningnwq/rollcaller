import 'package:flutter/material.dart';

import '../models/student_model.dart';

class StudentProvider with ChangeNotifier {
  List<StudentModel> studentList = [];

  // student数据发生改变
  void changeStudent(List<StudentModel> newList) {
    studentList.clear();
    studentList.addAll(newList);
    notifyListeners();
  }
}
