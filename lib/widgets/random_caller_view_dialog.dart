import 'package:flutter/material.dart';

import '../models/random_caller_model.dart';
import '../models/student_class_model.dart';

class RandomCallerViewDialog extends StatelessWidget {
  final RandomCallerModel randomCaller;
  final Map<int, StudentClassModel> allStudentClassesMap;

  const RandomCallerViewDialog({
    super.key,
    required this.randomCaller,
    required this.allStudentClassesMap,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(randomCaller.randomCallerName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '班级: ${allStudentClassesMap[randomCaller.classId]?.className}',
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
  }
}
