import 'package:flutter/material.dart';

import '../models/random_caller_model.dart';

class AttendanceCallRecordsPage extends StatefulWidget {
  const AttendanceCallRecordsPage({super.key});

  @override
  State<StatefulWidget> createState() => _AttendanceRecordsState();
}

class _AttendanceRecordsState extends State<AttendanceCallRecordsPage> {
  // 筛选条件是否展开
  bool _isFilterExpanded = true;
  // 选中的点名器名称（有全部选项）
  String? _selectedCallerName;
  // 全部点名器
  final List<RandomCallerModel> _allCallers = [];

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('签到点名记录'),);}
}
