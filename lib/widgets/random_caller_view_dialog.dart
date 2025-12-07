import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/random_caller_model.dart';
import '../providers/random_caller_provider.dart';
import '../utils/student_class_dao.dart';

class RandomCallerViewDialog extends StatelessWidget {
  final RandomCallerModel randomCaller;

  const RandomCallerViewDialog({super.key, required this.randomCaller});

  @override
  Widget build(BuildContext context) {
    var randomCaller = Provider.of<RandomCallerProvider>(
      context,
      listen: false,
    ).selectedCaller;
    return AlertDialog(
      title: Text(randomCaller!.randomCallerName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder(
            future: StudentClassDao().getStudentClass(randomCaller.classId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Text(
                  '班级: ${snapshot.data?.className}',
                  textAlign: TextAlign.left,
                );
              } else {
                return const CircularProgressIndicator();
              }
            },
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
