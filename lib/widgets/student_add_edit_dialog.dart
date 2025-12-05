import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/student_model.dart';
import '../providers/class_groups_provider.dart';
import '../providers/class_selected_provider.dart';
import '../providers/student_class_provider.dart';
import '../utils/student_dao.dart';

class StudentAddEditDialog extends StatelessWidget {
  final StudentModel student;
  final String title;
  late final bool isAdd;

  final TextEditingController studentNameController;
  final TextEditingController studentNumberController;
  final GlobalKey _formKey = GlobalKey<FormState>();

  StudentAddEditDialog({
    super.key,
    required this.student,
    required this.title,
    required this.studentNameController,
    required this.studentNumberController,
  }) {
    isAdd = title == '添加学生';
  }

  @override
  Widget build(BuildContext context) {
    studentNameController.text = student.studentName;
    studentNumberController.text = student.studentNumber;
    final List<String> classOptions = Provider.of<StudentClassProvider>(
      context,
      listen: false,
    ).studentClassesList.map((e) => e.className).toList();
    return AlertDialog(
      title: Text(title),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            children: [
              // 学生学号
              _buildStudentNumberField(),
              // 学生姓名
              _buildStudengNameField(),
              const SizedBox(height: 4),
              // 班级选择
              const Text('所在班级', style: TextStyle(fontSize: 16)),
              _buildClassSelectField(classOptions),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消'),
        ),
        TextButton(
          onPressed: () => _saveOnPressed(context, classOptions),
          child: Text('保存'),
        ),
      ],
    );
  }

  TextFormField _buildStudentNumberField() {
    bool isStudentNumberUnique = true;
    return TextFormField(
      decoration: InputDecoration(labelText: '学生学号', hintText: '请输入学生学号（必填）'),
      controller: studentNumberController,
      autovalidateMode: AutovalidateMode.onUnfocus,
      onChanged: (value) {
        WidgetsFlutterBinding.ensureInitialized(); // 确保初始化Flutter绑定。对于插件很重要。
        var studentDao = StudentDao(); // 创建StudentstudentDao实例。
        studentDao
            .isStudentNumberExist(value)
            .then(
              (onValue) => {
                if (onValue)
                  {
                    if (!isAdd &&
                        (studentNumberController.text == student.studentNumber))
                      isStudentNumberUnique = true
                    else
                      isStudentNumberUnique = false,
                  }
                else
                  isStudentNumberUnique = true,
              },
            );
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '学号不能为空';
        }
        if (!isStudentNumberUnique) {
          return '$value重复使用';
        }
        return null; // 如果没有找到重复值，返回null表示验证通过
      },
    );
  }

  TextFormField _buildStudengNameField() {
    return TextFormField(
      decoration: InputDecoration(labelText: '学生姓名', hintText: '请输入学生姓名（必填）'),
      controller: studentNameController,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '姓名不能为空';
        }
        return null;
      },
    );
  }

  Consumer<StudentClassSelectedProvider> _buildClassSelectField(
    List<String> classOptions,
  ) {
    return Consumer<StudentClassSelectedProvider>(
      builder: (context, selectedClassProvider, child) {
        return Column(
          children: List.generate(classOptions.length, (index) {
            return CheckboxListTile(
              value: selectedClassProvider.selectedClasses[index],
              title: Text(classOptions[index]),
              onChanged: (value) {
                selectedClassProvider.setSelectedClasses(index, value);
                // 更新 className
                student.className = selectedClassProvider.selectedClasses
                    .asMap()
                    .entries
                    .where((entry) => entry.value)
                    .map((entry) => classOptions[entry.key])
                    .toList()
                    .join(',');
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            );
          }),
        );
      },
    );
  }

  void _saveOnPressed(BuildContext context, List<String> classOptions) async {
    if ((_formKey.currentState as FormState).validate()) {
      WidgetsFlutterBinding.ensureInitialized(); // 确保初始化Flutter绑定。对于插件很重要。
      var studentDao = StudentDao(); // 创建StudentstudentDao实例。
      String selectedClassListStr =
          Provider.of<StudentClassSelectedProvider>(context, listen: false)
              .selectedClasses
              .asMap()
              .entries
              .where((entry) => entry.value)
              .map((entry) => classOptions[entry.key])
              .toList()
              .join(',');
      StudentModel oldStudent = StudentModel(
        studentName: student.studentName,
        studentNumber: student.studentNumber,
        className: student.className,
        created: student.created,
      );
      // 更新学生信息
      student.studentNumber = studentNumberController.text;
      student.studentName = studentNameController.text;
      student.className = selectedClassListStr;
      // 判断是新增还是修改
      if (isAdd) {
        // 新增学生
        student.created = DateTime.now();
        studentDao
            .insertStudent(student)
            .then(
              (id) => {
                student.id = id,
                // 添加学生列表，刷新数据
                if (context.mounted)
                  {
                    Provider.of<ClassGroupsProvider>(
                      context,
                      listen: false,
                    ).addStudent(student),
                  },
              },
            );
      } else {
        // 修改学生
        studentDao
            .updateStudentClassById(student)
            .then(
              (value) => {
                // 更新学生列表，刷新数据
                if (context.mounted)
                  {
                    Provider.of<ClassGroupsProvider>(
                      context,
                      listen: false,
                    ).updateStudent(student, oldStudent),
                  },
              },
            );
      }
    }
    if (context.mounted) {
      Navigator.of(context).pop(); // 关闭弹窗
    }
  }
}
