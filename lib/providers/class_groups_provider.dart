import 'package:flutter/material.dart';

import '../models/student_class_group.dart';

class ClassGroupsProvider with ChangeNotifier {
  // final List<StudentClassGroup> _classGroups = [];
  // final List<StudentClassGroup> _filterClassGroups = [];
  final Map<String, StudentClassGroup> _classGroups = {};
  final Map<String, StudentClassGroup> _filterClassGroups = {};

  List<StudentClassGroup> get classGroups => _classGroups.values.toList();
  List<StudentClassGroup> get filterClassGroups =>
      _filterClassGroups.values.toList();

  void addClassGroupWithoutNotify(StudentClassGroup group) {
    _classGroups.putIfAbsent(group.studentClass.className, () => group);
  }

  void changeClassGroups(List<StudentClassGroup> newList) {
    var tClassGroups = Map.from(_classGroups);
    _classGroups.clear();
    for (var group in newList) {
      if (tClassGroups.containsKey(group.studentClass.className)) {
        group.isExpanded =
            tClassGroups[group.studentClass.className]!.isExpanded;
      }
      _classGroups.putIfAbsent(group.studentClass.className, () => group);
    }
    notifyListeners();
  }

  void changeClassGroupsWithoutNotify(List<StudentClassGroup> newList) {
    var tClassGroups = Map.from(_classGroups);
    _classGroups.clear();
    for (var group in newList) {
      if (tClassGroups.containsKey(group.studentClass.className)) {
        group.isExpanded =
            tClassGroups[group.studentClass.className]!.isExpanded;
      }
      _classGroups.putIfAbsent(group.studentClass.className, () => group);
    }
  }

  void changeFilterClassGroupsWithoutNotify(String filter) {
    _filterClassGroups.clear();
    for (var group in _classGroups.entries) {
      _filterClassGroups.putIfAbsent(group.key, () => group.value);
    }
  }

  void changeFilterClassGroups(String filter) {
    _filterClassGroups.clear();
    for (var group in _classGroups.entries) {
      _filterClassGroups.putIfAbsent(group.key, () => group.value);
    }
    notifyListeners();
  }

  void changeExpanded(int index) {
    var aList = _filterClassGroups.values.toList();
    _classGroups[aList[index].studentClass.className]!.isExpanded =
        !aList[index].isExpanded;
    notifyListeners();
  }
}
