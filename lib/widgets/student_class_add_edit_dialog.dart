import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/student_class_model.dart';
import '../utils/student_class_dao.dart';
import '../utils/student_dao.dart';

class StudentClassAddEditDialog extends StatefulWidget {
  final StudentClassModel studentClass;
  final String title;

  const StudentClassAddEditDialog({
    super.key,
    required this.studentClass,
    required this.title,
  });

  @override
  State<StatefulWidget> createState() {
    return _StudentClassAddEditDialogState();
  }
}

class _StudentClassAddEditDialogState extends State<StudentClassAddEditDialog> {
  // 班级名称
  final TextEditingController classNameController = TextEditingController();
  // 学生人数
  final TextEditingController studentQuantityController =
      TextEditingController();
  // 教师姓名
  final TextEditingController teacherNameController = TextEditingController();
  // 备注
  final TextEditingController notesController = TextEditingController();
  // 表单验证键
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isAdd = false;

  @override
  initState() {
    super.initState();
    isAdd = widget.title == '添加班级';
    classNameController.text = widget.studentClass.className;
    studentQuantityController.text = widget.studentClass.studentQuantity
        .toString();
    teacherNameController.text = widget.studentClass.teacherName;
    notesController.text = widget.studentClass.notes;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            children: [
              _buildClassNameInfoRow('班级名称（必填）'),
              _buildClassQuantityInfoRowInt('学生数量（必填）'),
              _buildInfoRow('教师姓名（可选）', teacherNameController),
              _buildInfoRow('备注（可选）', notesController),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            (context);
          },
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              // 处理添加/编辑学生班级的逻辑
              _saveOnPressed();
            }
          },
          child: const Text('确定'),
        ),
      ],
    );
  }

  Padding _buildInfoRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        decoration: InputDecoration(labelText: label),
        controller: controller,
      ),
    );
  }

  Padding _buildClassNameInfoRow(String label) {
    bool isClassNameUnique = true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(labelText: label),
        controller: classNameController,
        autovalidateMode: AutovalidateMode.onUnfocus,
        onChanged: (value) {
          WidgetsFlutterBinding.ensureInitialized(); // 确保初始化Flutter绑定。对于插件很重要。
          var classDao = StudentClassDao(); // 创建StudentClassDao实例。
          classDao
              .isStudentClassesNameExist(value)
              .then(
                (onValue) => {
                  if (onValue)
                    {
                      if (!isAdd &&
                          (classNameController.text ==
                              widget.studentClass.className))
                        isClassNameUnique = true
                      else
                        isClassNameUnique = false,
                    }
                  else
                    isClassNameUnique = true,
                },
              );
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '班级名称不能为空';
          }
          if (!isClassNameUnique) {
            return '$value重复使用';
          }
          return null; // 如果没有找到重复值，返回null表示验证通过
        },
      ),
    );
  }

  Padding _buildClassQuantityInfoRowInt(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        keyboardType: TextInputType.number,
        // 设置键盘类型为数字键盘
        inputFormatters: <TextInputFormatter>[
          // 添加输入格式化器以限制输入为数字
          FilteringTextInputFormatter.digitsOnly, // 只允许输入数字
        ],
        decoration: InputDecoration(labelText: label),
        controller: studentQuantityController,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '学生人数不能为空';
          }
          return null;
        },
      ),
    );
  }

  Future<void> _saveOnPressed() async {
    // 表单验证通过，执行添加/编辑操作
    String oldClassName = widget.studentClass.className;
    widget.studentClass.className = classNameController.text;
    widget.studentClass.studentQuantity = int.parse(
      studentQuantityController.text,
    );
    widget.studentClass.teacherName = teacherNameController.text;
    widget.studentClass.notes = notesController.text;
    // 获取数据库dao
    var classDao = StudentClassDao(); // 创建StudentClassDao实例。

    if (isAdd) {
      // 添加操作
      widget.studentClass.created = DateTime.now();
      classDao.insertStudentClass(widget.studentClass).then((id) {
        if (id != 0) {
          widget.studentClass.id = id;
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('添加成功')));
            Navigator.of(context).pop(true);
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('添加失败')));
            Navigator.of(context).pop(false);
          }
        }
      });
    } else {
      // 更新班级操作
      // 找到班级相关学生
      var studentDao = StudentDao(); // 创建StudentDao实例。
      var students = await studentDao.getAllStudentsByClassName(oldClassName);
      classDao.updateStudentClassById(widget.studentClass).then((onValue) {
        if (onValue != 0) {
          // 更新学生班级名称
          for (var student in students) {
            var classNames = student.className.split(',');
            for (int i = 0; i < classNames.length; i++) {
              if (classNames[i] == oldClassName) {
                classNames[i] = widget.studentClass.className;
                break;
              }
            }
            student.className = classNames.join(',');
            studentDao.updateStudentById(student);
          }
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('更新成功')));
            Navigator.of(context).pop(true);
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('更新失败')));
            Navigator.of(context).pop(false);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    classNameController.dispose();
    studentQuantityController.dispose();
    teacherNameController.dispose();
    notesController.dispose();
    super.dispose();
  }
}
