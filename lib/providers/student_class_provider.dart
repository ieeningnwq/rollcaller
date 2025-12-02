import 'package:flutter/material.dart';

import '../models/student_class_model.dart';

class StudentClassProvider with ChangeNotifier {
  final List<StudentClassModel> _studentClassList = [];

  final List<Icon> _icon = [];
  final List<Color> _color = [];
  final List<Color> _deprecationColor = [];
  final List<String> _string = [];

  List<Icon> get icon => _icon;
  List<Color> get color => _color;
  List<String> get string => _string;
  List<Color> get deprecationColor => _deprecationColor;

  // 获取student class列表
  List<StudentClassModel> get studentClassesList => _studentClassList;

  // student class数据发生改变
  void changeStudentClassWithoutNotify(List<StudentClassModel> newList) {
    _studentClassList.clear();
    _icon.clear();
    _color.clear();
    _string.clear();
    for (var element in newList) {
      _icon.add(
        element.classQuantity == element.studentQuantity
            ? Icon(Icons.check_circle, size: 16, color: Colors.green)
            : element.classQuantity < element.studentQuantity
            ? Icon(Icons.warning_amber, size: 16, color: Colors.yellow)
            : Icon(Icons.error, size: 16, color: Colors.red),
      );
      _color.add(
        element.classQuantity == element.studentQuantity
            ? Colors.green
            : element.classQuantity < element.studentQuantity
            ? Colors.yellow
            : Colors.red,
      );
      _deprecationColor.add(
        element.classQuantity == element.studentQuantity
            ? Colors.green.shade100
            : element.classQuantity < element.studentQuantity
            ? Colors.yellow.shade100
            : Colors.red.shade100,
      );
      _string.add(
        element.classQuantity == element.studentQuantity
            ? '人数已满'
            : element.classQuantity < element.studentQuantity
            ? '人数未满'
            : '人数超员',
      );
    }
    _studentClassList.addAll(newList);
  }

  // student class数据发生改变
  void changeStudentClass(List<StudentClassModel> newList) {
    _studentClassList.clear();
    _icon.clear();
    _color.clear();
    _string.clear();
    for (var element in newList) {
      _icon.add(
        element.classQuantity == element.studentQuantity
            ? Icon(Icons.check_circle, color: Colors.green)
            : element.classQuantity > element.studentQuantity
            ? Icon(Icons.warning_amber, color: Colors.yellow)
            : Icon(Icons.error, color: Colors.red),
      );
      _color.add(
        element.classQuantity == element.studentQuantity
            ? Colors.green
            : element.classQuantity > element.studentQuantity
            ? Colors.yellow
            : Colors.red,
      );
      _string.add(
        element.classQuantity == element.studentQuantity
            ? '人数已满'
            : element.classQuantity > element.studentQuantity
            ? '人数未满'
            : '人数超员',
      );
    }
    _studentClassList.addAll(newList);
    notifyListeners();
  }
}
