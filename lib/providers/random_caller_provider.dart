import 'package:flutter/material.dart';

import '../models/random_caller_model.dart';

class RandomCallerProvider with ChangeNotifier {
  final Map<int, RandomCallerModel> _randomCallers = {};

  Map<int, RandomCallerModel> get randomCallers => _randomCallers;

  void updateRollCallerWithoutNotify(RandomCallerModel randomCallerModel) {
    if (randomCallerModel.id == null) {
      return;
    }
    _randomCallers[randomCallerModel.id!] = randomCallerModel;
  }
}