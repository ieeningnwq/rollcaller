import 'package:flutter/material.dart';

class RollCallerSelectedClassIdProvider extends ChangeNotifier {
  int _selectedClassId=-1;
  int get selectedClassId => _selectedClassId;

  void updateSelectedClassId(int  value) {
    _selectedClassId = value;
    notifyListeners();
  }

  void selectedClassIdWithoutNotify(int value) {
    _selectedClassId = value;
  }
}