import 'package:flutter/material.dart';

class CurrentIndexProvider with ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  // 切换底部导航栏
  void changeIndex(int newIndex) {
    _currentIndex = newIndex;
    notifyListeners();
  }
}
