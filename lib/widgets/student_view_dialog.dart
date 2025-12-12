import 'package:flutter/material.dart';
import 'package:rollcall/utils/student_class_relation_dao.dart';
import '../models/student_class_model.dart';
import '../models/student_model.dart';
import '../utils/student_class_dao.dart';

class StudentViewDialog extends StatefulWidget {
  final StudentModel student;
  

  const StudentViewDialog({super.key, required this.student});

  @override
  State<StudentViewDialog> createState() => _StudentViewDialogState();



  
}

class _StudentViewDialogState extends State<StudentViewDialog> {
  late Future<List<StudentClassModel>> _getStudentAllClassesFuture;

  @override
  void initState() {
    super.initState();
    _getStudentAllClassesFuture = _getStudentAllClasses();
  }
  
  Future<List<StudentClassModel>> _getStudentAllClasses() async {
    return await StudentClassRelationDao().getAllClassIdsByStudentId(widget.student.id!).then((classIds) async {
      List<StudentClassModel> allClasses = [];
      for (var classId in classIds) {
        allClasses.add(await StudentClassDao().getStudentClass(classId));
      }
      return allClasses;
    });
    
  }

  @override
  Widget build(BuildContext context) {
    // 拿到学生所在的所有班级
    return AlertDialog(
      title: const Text('学生信息详情'),
      content: SingleChildScrollView(
        child: FutureBuilder(future: _getStudentAllClasses(), builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow('姓名', widget.student.studentName),
                _buildInfoRow('学号', widget.student.studentNumber),
                _buildInfoRow('班级', snapshot.data!.map((e) => e.className).join(', ')),
                _buildInfoRow(
                  '创建时间',
                  '${widget.student.created.year}-${widget.student.created.month.toString().padLeft(2, '0')}-${widget.student.created.day.toString().padLeft(2, '0')}',
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return const CircularProgressIndicator();
          }
        })),
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
