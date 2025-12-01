import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rollcall/models/Student_model.dart';
import 'package:rollcall/models/student_class_model.dart';
import 'package:rollcall/utils/student_class_dao.dart';

import '../utils/database_helper.dart';

class StudentClassPage extends StatefulWidget {
  const StudentClassPage({super.key});

  @override
  State<StatefulWidget> createState() => _StudentClassState();
}

class _StudentClassState extends State<StudentClassPage> {
  final TextEditingController classNameController = TextEditingController();
  final TextEditingController studentQuantityController =
      TextEditingController();
  final TextEditingController teacherNameController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('班级管理')),
      body: const Center(child: Text('Welcome to the Student Class Page!')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return _studentClassDialog('创建班级');
            },
          );
        },
        tooltip: '添加班级',
        child: FaIcon(FontAwesomeIcons.plus),
      ),
    );
  }

  AlertDialog _studentClassDialog(
    String title, {
    String className = '',
    int studentNumber = 0,
    String teacherName = '',
    String notes = '',
  }) {
    classNameController.text = className;
    studentQuantityController.text = studentNumber.toString();
    teacherNameController.text = teacherName;
    notesController.text = notes;
    AlertDialog a = AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextFormField(
            decoration: InputDecoration(labelText: '班级名称'),
            controller: classNameController,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '班级名称不能为空';
              }
              return null;
            },
          ),
          TextFormField(
            keyboardType: TextInputType.number,
            // 设置键盘类型为数字键盘
            inputFormatters: <TextInputFormatter>[
              // 添加输入格式化器以限制输入为数字
              FilteringTextInputFormatter.digitsOnly, // 只允许输入数字
            ],
            decoration: InputDecoration(labelText: '学生人数'),
            controller: studentQuantityController,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '学生人数不能为空';
              } else if (true) {}
              return null;
            },
          ),
          TextField(
            decoration: InputDecoration(labelText: '教师名称（可选）'),
            controller: teacherNameController,
          ),
          TextField(
            decoration: InputDecoration(labelText: '备注（可选）'),
            controller: notesController,
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: Text('取消'),
          onPressed: () {
            Navigator.of(context).pop(); // 关闭弹窗
          },
        ),
        TextButton(
          child: Text('创建'),
          onPressed: () async {
            WidgetsFlutterBinding.ensureInitialized(); // 确保初始化Flutter绑定。对于插件很重要。
            var dbHelper = DatabaseHelper(); // 创建DatabaseHelper实例。
            var classDao = StudentClassDao(dbHelper); // 创建UserDao实例。
            await classDao.insertStudentClass(
              StudentClassModel.fromMap({
                'class_name': classNameController.text,
                'student_quantity': int.parse(studentQuantityController.text),
                'teacher_name': teacherNameController.text,
                'notes': notesController.text,
              }),
            ); // 插入用户数据。
            var classes = await classDao.getAllStudentClasses(); // 获取所有班级数据。
            log(classes.toString()); //
            if (mounted) Navigator.of(context).pop(); // 关闭弹窗
          },
        ),
      ],
    );
    return a;
  }

  @override
  dispose() {
    super.dispose();
    classNameController.dispose();
    studentQuantityController.dispose();
    teacherNameController.dispose();
    notesController.dispose();
  }

  bool isFormDataValidate() => false;
}
