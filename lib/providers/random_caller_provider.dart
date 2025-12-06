import 'package:flutter/material.dart';

import '../models/random_caller_model.dart';

class RandomCallerProvider with ChangeNotifier {
  final Map<int, RandomCallerModel> _randomCallers = {};

  Map<int, RandomCallerModel> get randomCallers => _randomCallers;

  void updateRandomCallerWithoutNotify(RandomCallerModel randomCallerModel) {
    if (randomCallerModel.id == null) {
      return;
    }
    _randomCallers[randomCallerModel.id!] = randomCallerModel;
  }

    void updateRandomCaller(RandomCallerModel randomCallerModel) {
    if (randomCallerModel.id == null) {
      return;
    }
    _randomCallers[randomCallerModel.id!] = randomCallerModel;
    notifyListeners();
  }

  void addRandomCaller(RandomCallerModel randomCaller) {
    if (randomCaller.id == null) {
      return;
    }
    _randomCallers[randomCaller.id!] = randomCaller;
    notifyListeners();
  }

  void removeRandomCaller(int id) {
    _randomCallers.remove(id);
    notifyListeners();
  }
}