import 'dart:developer';

import 'package:flutter/material.dart';

import '../models/student_class_group.dart';
import '../models/student_model.dart';

class ClassGroupsProvider with ChangeNotifier {
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
    for (var entry in _classGroups.entries) {
      List<StudentModel> students = [];
      String className = entry.key;
      StudentClassGroup group = entry.value;
      for (var student in group.students) {
        if (student.studentNumber.contains(filter) ||
            student.studentName.contains(filter)) {
          students.add(student);
        }
      }
      if (students.isNotEmpty) {
        StudentClassGroup newGroup = StudentClassGroup(
          studentClass: group.studentClass,
          students: students,
          isExpanded: group.isExpanded,
        );
        _filterClassGroups.putIfAbsent(className, () => newGroup);
      }
    }
    log(filterClassGroups.toString());
  }

  void changeFilterClassGroups(String filter) {
    _filterClassGroups.clear();
    for (var entry in _classGroups.entries) {
      List<StudentModel> students = [];
      String className = entry.key;
      StudentClassGroup group = entry.value;
      for (var student in group.students) {
        if (student.studentNumber.contains(filter) ||
            student.studentName.contains(filter)) {
          students.add(student);
        }
      }
      if (students.isNotEmpty) {
        StudentClassGroup newGroup = StudentClassGroup(
          studentClass: group.studentClass,
          students: students,
        );
        _filterClassGroups.putIfAbsent(className, () => newGroup);
      }
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
