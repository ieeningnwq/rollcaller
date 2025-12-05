import 'package:flutter/material.dart';

import '../models/roll_caller_model.dart';

class RollCallerProvider with ChangeNotifier {
  final Map<int, RollCallerModel> _rollCallers = {};

  // 获取roll caller列表
  List<RollCallerModel> get rollCallersList => _rollCallers.values.toList();
}