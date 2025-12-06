import 'package:flutter/material.dart';

import '../models/random_caller_model.dart';

class RandomCallerProvider with ChangeNotifier {
  final Map<int, RandomCallerModel> _randomCallers = {};

  // 获取random caller列表
  List<RandomCallerModel> get randomCallersList => _randomCallers.values.toList();

  void updateRollCallerWithoutNotify(RandomCallerModel randomCallerModel) {
    if (randomCallerModel.id == null) {
      return;
    }
    _randomCallers[randomCallerModel.id!] = randomCallerModel;
  }
}