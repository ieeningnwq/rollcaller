import 'package:flutter/material.dart';

import '../models/random_caller_model.dart';
import 'attendance_call_records_page.dart';
import 'random_call_records_page.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<StatefulWidget> createState() => _RecordState();
}

class _RecordState extends State<RecordPage> {
  // 0表示随机点名，1表示签到点名
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部标题栏
            Container(
              padding: const EdgeInsets.all(12),
              child: Text(
                '点名记录管理',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 随机点名按钮
                _buildRandomRollCallButton(),
                _buildAttendenceButton(),
              ],
            ),
            _selectedIndex == 0
                ? RandomCallRecordsPage()
                : AttendanceCallRecordsPage(),
          ],
        ),
      ),
    );
  }

  Expanded _buildRandomRollCallButton() {
    return Expanded(
      flex: 1,
      child: Container(
        margin: const EdgeInsets.only(left: 4, right: 3),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedIndex = 0;
            });
            // 随机点名功能
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedIndex == 0 ? Colors.blue : Colors.white,
            foregroundColor: _selectedIndex == 0 ? Colors.white : Colors.blue,
            side: BorderSide(
              color: _selectedIndex == 0 ? Colors.blue : Colors.blue,
            ),
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shuffle,
                color: _selectedIndex == 0 ? Colors.white : Colors.blue,
              ),
              const SizedBox(width: 8.0),
              Text(
                '随机点名记录',
                style: TextStyle(
                  fontSize: 16.0,
                  color: _selectedIndex == 0 ? Colors.white : Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Expanded _buildAttendenceButton() {
    return Expanded(
      flex: 1,
      child: Container(
        margin: const EdgeInsets.only(left: 3, right: 4),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedIndex = 1;
            });
            // 签到点名功能
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedIndex == 1 ? Colors.blue : Colors.white,
            foregroundColor: _selectedIndex == 1 ? Colors.white : Colors.blue,
            side: BorderSide(
              color: _selectedIndex == 1 ? Colors.blue : Colors.blue,
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                color: _selectedIndex == 1 ? Colors.white : Colors.blue,
              ),
              const SizedBox(width: 8.0),
              Text(
                '签到点名记录',
                style: TextStyle(
                  fontSize: 16.0,
                  color: _selectedIndex == 1 ? Colors.white : Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
