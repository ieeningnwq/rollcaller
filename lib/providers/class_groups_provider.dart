import 'package:flutter/material.dart';

import '../models/student_class_group.dart';

class ClassGroupsProvider with ChangeNotifier {
  final List<StudentClassGroup> _classGroups = [];
  final List<StudentClassGroup> _filterClassGroups = [];

  List<StudentClassGroup> get classGroups => _classGroups;
  List<StudentClassGroup> get filterClassGroups => _filterClassGroups;

  void addClassGroupWithoutNotify(StudentClassGroup group) {
    _classGroups.add(group);
  }

  void changeClassGroups(List<StudentClassGroup> newList) {
    _classGroups.clear();
    _classGroups.addAll(newList);
    notifyListeners();
  }

  void changeClassGroupsWithoutNotify(List<StudentClassGroup> newList) {
    _classGroups.clear();
    _classGroups.addAll(newList);
  }

  void changeFilterClassGroupsWithoutNotify(String filter) {
    _filterClassGroups.clear();
    _filterClassGroups.addAll(
      _classGroups
          .where((element) => element.studentClass.className.contains(filter))
          .toList(),
    );
  }

  void changeFilterClassGroups(String filter) {
    _filterClassGroups.clear();
    _filterClassGroups.addAll(
      _classGroups,
      //     .where((element) => element.studentClass.className.contains(filter))
      //     .toList(),
    );
    notifyListeners();
  }
}
