import 'package:flutter/material.dart';

import '../models/attendance_caller_model.dart';
import '../models/student_class_model.dart';
import '../utils/student_class_dao.dart';

class AttendanceCallerViewDialog extends StatelessWidget {
  final AttendanceCallerModel attendanceCaller;

  const AttendanceCallerViewDialog({super.key, required this.attendanceCaller});

  Future<StudentClassModel> _getStudentClass() async {
    StudentClassDao studentClassDao = StudentClassDao();
    return await studentClassDao.getStudentClass(attendanceCaller.classId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StudentClassModel>(
      future: _getStudentClass(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          var studentClass = snapshot.data;
          return AlertDialog(
            title: Text(attendanceCaller.attendanceCallerName),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '班级: ${studentClass?.className}',
                  textAlign: TextAlign.left,
                ),
                Text(
                  '备注: ${attendanceCaller.notes}',
                  textAlign: TextAlign.left,
                ),
                //创建时间
                Text(
                  '创建时间: ${attendanceCaller.created.year}-${attendanceCaller.created.month.toString().padLeft(2, '0')}-${attendanceCaller.created.day.toString().padLeft(2, '0')} ${attendanceCaller.created.hour.toString().padLeft(2, '0')}:${attendanceCaller.created.minute.toString().padLeft(2, '0')}:${attendanceCaller.created.second.toString().padLeft(2, '0')}',
                  textAlign: TextAlign.left,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ],
          );
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}
