import 'package:flutter/material.dart';
import '../models/student_model.dart';

class StudentViewDialog extends StatelessWidget {
  final StudentModel student;

  const StudentViewDialog({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('学生信息详情'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoRow('姓名', student.studentName),
            _buildInfoRow('学号', student.studentNumber),
            _buildInfoRow('班级', student.className),
            _buildInfoRow(
              '创建时间',
              '${student.created.year}-${student.created.month.toString().padLeft(2, '0')}-${student.created.day.toString().padLeft(2, '0')}',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }
}
