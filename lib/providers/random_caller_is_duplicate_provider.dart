import 'package:flutter/material.dart';

class RandomCallerIsDuplicateProvider extends ChangeNotifier {
  bool _isDuplicate = false;

  bool get isDuplicate => _isDuplicate;

  void updateIsDuplicate(bool value) {
    _isDuplicate = value;
    notifyListeners();
  }

  void updateIsDuplicateWithoutNotify(bool isDuplicate) {
    _isDuplicate = isDuplicate;
  }
}