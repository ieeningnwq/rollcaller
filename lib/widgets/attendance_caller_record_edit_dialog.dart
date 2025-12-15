import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../configs/attendance_status.dart';
import '../models/attendance_call_record.dart';

class AttendanceCallerRecordEditDialog extends StatefulWidget {
  final AttendanceCallRecordModel record;

  const AttendanceCallerRecordEditDialog({super.key, required this.record});

  @override
  State<StatefulWidget> createState() {
    return _AttendanceCallerRecordEditDialogState();
  }
}

class _AttendanceCallerRecordEditDialogState
    extends State<AttendanceCallerRecordEditDialog> {
  late AttendanceCallRecordModel _record;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑分数'),
      content: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 4.w),
          decoration: BoxDecoration(
            color: _record.present.statusColor,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: InkWell(
            onTap: () {
              // 切换状态
              _toggleAttendanceStatus(_record);
            },
            child: Text(
              _record.present.statusText,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_record);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }

  // 切换签到状态
  void _toggleAttendanceStatus(AttendanceCallRecordModel record) {
    final currentStatus = record.present;
    final statuses = [
      AttendanceStatus.present,
      AttendanceStatus.late,
      AttendanceStatus.excused,
      AttendanceStatus.absent,
    ];
    final currentIndex = statuses.indexOf(currentStatus);
    final nextIndex = (currentIndex + 1) % statuses.length;
    setState(() {
      _record.present = statuses[nextIndex];
    });
  }
}
