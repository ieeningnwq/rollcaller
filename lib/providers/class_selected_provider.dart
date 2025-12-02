import 'package:flutter/material.dart';

class StudentClassSelectedProvider with ChangeNotifier {
  final List<bool> _selectedClasses = [];

  List<bool> get selectedClasses => _selectedClasses;

  void setSelectedClasses(int index, bool? value) {
    _selectedClasses[index] = value ?? false;
    notifyListeners();
  }

  void setSelectedClassesWithoutNotify(int index, bool? value) {
    _selectedClasses[index] = value ?? false;
  }

  void changeSelectedClasses(List<bool> newList) {
    _selectedClasses.clear();
    _selectedClasses.addAll(newList);
    notifyListeners();
  }

  void changeSelectedClassesWithoutNotify(List<bool> newList) {
    _selectedClasses.clear();
    _selectedClasses.addAll(newList);
  }
}
