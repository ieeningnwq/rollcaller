import 'package:flutter/material.dart';

class RandomCallerSelectedClassIdProvider extends ChangeNotifier {
  int _selectedClassId = -1;

  int get selectedClassId => _selectedClassId;

  void setSelectedClassId(int classId) {
    _selectedClassId = classId;
    notifyListeners();
  }

  void selectedClassIdWithoutNotify(int classId) {
    _selectedClassId = classId;
  }
}
