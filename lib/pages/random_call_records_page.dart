import 'package:flutter/material.dart';

import '../models/random_caller_model.dart';

class RandomCallRecordsPage extends StatefulWidget {
  const RandomCallRecordsPage({super.key});

  @override
  State<StatefulWidget> createState() => _RandomRecordsState();
}

class _RandomRecordsState extends State<RandomCallRecordsPage> {
  // 筛选条件是否展开
  bool _isFilterExpanded = true;
  // 选中的点名器名称（有全部选项）
  String? _selectedCallerName;
  // 全部点名器
  final List<RandomCallerModel> _allCallers = [];

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('随机点名记录'),);}
}
