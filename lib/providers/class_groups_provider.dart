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
    var isExpands = _classGroups.map((e) => e.isExpanded).toList();
    _classGroups.clear();
    _classGroups.addAll(newList);
    for (int i = 0; i < _classGroups.length; i++) {
      _classGroups[i].isExpanded = isExpands[i];
    }
    notifyListeners();
  }

  void changeClassGroupsWithoutNotify(List<StudentClassGroup> newList) {
    var isExpands = _classGroups.map((e) => e.isExpanded).toList();
    _classGroups.clear();
    _classGroups.addAll(newList);
    for (int i = 0; i < _classGroups.length; i++) {
      _classGroups[i].isExpanded = isExpands[i];
    }
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

  void changeExpanded(int index) {
    _filterClassGroups[index].isExpanded =
        !_filterClassGroups[index].isExpanded;
    notifyListeners();
  }
}
