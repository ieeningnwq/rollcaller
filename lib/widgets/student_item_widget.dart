import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rollcall/models/student_model.dart';
import 'package:rollcall/providers/class_groups_provider.dart';

import '../utils/student_dao.dart';
import 'student_add_edit_dialog.dart';
import 'student_view_dialog.dart';
import '../providers/class_selected_provider.dart';
import '../providers/student_class_provider.dart';

class StudentItemWidget extends StatelessWidget {
  final StudentModel student;

  final TextEditingController studentNameController;

  final TextEditingController studentNumberController;
  const StudentItemWidget({
    super.key,
    required this.student,
    required this.studentNameController,
    required this.studentNumberController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      student.studentName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        student.studentNumber,
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '创建时间: ${'${student.created.year}-${student.created.month.toString().padLeft(2, '0')}-${student.created.day.toString().padLeft(2, '0')}'}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, color: Colors.grey),
                onPressed: () {
                  // 查看功能
                  showDialog(
                    context: context,
                    builder: (context) => StudentViewDialog(student: student),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.grey),
                onPressed: () {
                  final classOptions = Provider.of<StudentClassProvider>(
                    context,
                    listen: false,
                  ).studentClassesList.map((e) => e.className).toList();
                  final selectedClasses = List<bool>.filled(
                    classOptions.length,
                    false,
                  );
                  for (int i = 0; i < classOptions.length; i++) {
                    selectedClasses[i] = ',${student.className},'.contains(
                      ',${classOptions[i]},',
                    );
                  }
                  Provider.of<StudentClassSelectedProvider>(
                    context,
                    listen: false,
                  ).changeSelectedClassesWithoutNotify(selectedClasses);

                  // 编辑功能
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return StudentAddEditDialog(
                        student: student,
                        title: '编辑学生',
                        studentNameController: studentNameController,
                        studentNumberController: studentNumberController,
                      );
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.grey),
                onPressed: () {
                  // 删除功能
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('确认删除'),
                      content: const Text('确定删除该学生吗？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await StudentDao().deleteStudentById(student.id);
                            if (context.mounted) {
                              // 刷新学生列表
                              Provider.of<ClassGroupsProvider>(
                                context,
                                listen: false,
                              ).removeStudent(student);
                              Navigator.of(context).pop();
                            }
                          },
                          child: const Text('删除'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
