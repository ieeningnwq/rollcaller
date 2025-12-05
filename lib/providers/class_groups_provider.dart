import 'package:flutter/material.dart';

import '../models/student_class_group.dart';
import '../models/student_model.dart';

class ClassGroupsProvider with ChangeNotifier {
  final Map<int, StudentClassGroup> _classGroups = {};
  final Map<int, StudentClassGroup> _filterClassGroups = {};

  List<StudentClassGroup> get classGroups => _classGroups.values.toList();
  List<StudentClassGroup> get filterClassGroups =>
      _filterClassGroups.values.toList();

  void addClassGroupWithoutNotify(StudentClassGroup group) {
    _classGroups.putIfAbsent(group.studentClass.id!, () => group);
  }

  void changeClassGroups(List<StudentClassGroup> newList) {
    var tClassGroups = Map.from(_classGroups);
    _classGroups.clear();
    for (var group in newList) {
      if (tClassGroups.containsKey(group.studentClass.className)) {
        group.isExpanded =
            tClassGroups[group.studentClass.className]!.isExpanded;
      }
      _classGroups.putIfAbsent(group.studentClass.id!, () => group);
    }
    notifyListeners();
  }

  void changeClassGroupsWithoutNotify(List<StudentClassGroup> newList) {
    var tClassGroups = Map.from(_classGroups);
    _classGroups.clear();
    for (var group in newList) {
      if (tClassGroups.containsKey(group.studentClass.id)) {
        group.isExpanded = tClassGroups[group.studentClass.id!]!.isExpanded;
      }
      _classGroups.putIfAbsent(group.studentClass.id!, () => group);
    }
  }

  void changeFilterClassGroupsWithoutNotify(String filter) {
    _filterClassGroups.clear();
    for (var entry in _classGroups.entries) {
      List<StudentModel> students = [];
      int classId = entry.key;
      StudentClassGroup group = entry.value;
      for (var student in group.students) {
        if (student.studentNumber.contains(filter) ||
            student.studentName.contains(filter)) {
          students.add(student);
        }
      }
      StudentClassGroup newGroup = StudentClassGroup(
        studentClass: group.studentClass,
        students: students,
        isExpanded: group.isExpanded,
      );
      _filterClassGroups.putIfAbsent(classId, () => newGroup);
    }
  }

  void changeFilterClassGroups(String filter) {
    _filterClassGroups.clear();
    for (var entry in _classGroups.entries) {
      List<StudentModel> students = [];
      int classId = entry.key;
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
        _filterClassGroups.putIfAbsent(classId, () => newGroup);
      }
    }
    notifyListeners();
  }

  void changeExpanded(int index) {
    var aList = _filterClassGroups.values.toList();
    _classGroups[aList[index].studentClass.id!]!.isExpanded =
        !aList[index].isExpanded;
    notifyListeners();
  }

  void addStudent(StudentModel student) {
    addStudentWithoutNotify(student);
    notifyListeners();
  }

  void addStudentWithoutNotify(StudentModel student) {
    for (var element in _classGroups.values) {
      if (',${student.className},'.contains(
        ',${element.studentClass.className},',
      )) {
        element.students.add(student);
      }
    }
  }

  void removeStudentWithoutNotify(StudentModel student) {
    for (var element in _classGroups.values) {
      if (',${student.className},'.contains(
        ',${element.studentClass.className},',
      )) {
        for (int i = 0; i < element.students.length; i++) {
          if (element.students[i].id == student.id) {
            element.students.removeAt(i);
            break;
          }
        }
      }
    }
  }

  void removeStudent(StudentModel student) {
    removeStudentWithoutNotify(student);
    notifyListeners();
  }

  void updateStudent(StudentModel student, StudentModel oldStudent) {
    removeStudentWithoutNotify(oldStudent);
    addStudentWithoutNotify(student);
    notifyListeners();
  }
}
