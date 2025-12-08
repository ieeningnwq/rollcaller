import 'package:flutter/material.dart';

import '../models/random_caller_model.dart';
import '../models/student_class_model.dart';
import '../utils/student_class_dao.dart';

class RandomCallerViewDialog extends StatelessWidget {
  final RandomCallerModel randomCaller;

  const RandomCallerViewDialog({super.key, required this.randomCaller});

  Future<StudentClassModel> _getStudentClass() async {
    StudentClassDao studentClassDao = StudentClassDao();
    return await studentClassDao.getStudentClass(randomCaller.classId);
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
            title: Text(randomCaller.randomCallerName),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '班级: ${studentClass?.className}',
                  textAlign: TextAlign.left,
                ),

                Text(
                  '重复点名: ${randomCaller.isDuplicate == 1 ? '是' : '否'}',
                  textAlign: TextAlign.left,
                ),
                Text('备注: ${randomCaller.notes}', textAlign: TextAlign.left),
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
