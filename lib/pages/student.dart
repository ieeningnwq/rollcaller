import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:rollcall/configs/strings.dart';

import '../models/student_model.dart';
import '../utils/database_helper.dart';
import '../utils/student_dao.dart';

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  final TextEditingController classNameController = TextEditingController();
  final TextEditingController studentNumberController = TextEditingController();
  final TextEditingController studentNameController = TextEditingController();

  final GlobalKey _formKey = GlobalKey<FormState>();
  bool _isStudentNumberUnique = true;
  final List<String> _classOptions = [
    '一年级一班',
    '一年级二班',
    '二年级一班',
    '二年级二班',
    '三年级一班',
  ];
  final List<bool> _selectedClasses = List<bool>.filled(5, false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(KString.studentClassTitle)),
      body: const Center(child: Text(KString.studentClassTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => {
          showDialog(
            context: context,
            builder: (context) => _studentDialog('创建学生'),
          ),
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  AlertDialog _studentDialog(
    String title, {
    String studentName = '',
    String studentNumber = '',
    String className = '',
  }) {
    // 判断是新增还是修改
    bool isAdd = title == '创建学生';
    studentNameController.text = studentName;
    studentNumberController.text = studentNumber;
    classNameController.text = className;
    return AlertDialog(
      title: Text(title),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(
                  labelText: '学生学号',
                  hintText: '请输入学生学号',
                ),
                controller: studentNumberController,
                autovalidateMode: AutovalidateMode.onUnfocus,
                onChanged: (value) {
                  WidgetsFlutterBinding.ensureInitialized(); // 确保初始化Flutter绑定。对于插件很重要。
                  var dbHelper = DatabaseHelper(); // 创建DatabaseHelper实例。
                  var studentDao = StudentDao(
                    dbHelper,
                  ); // 创建StudentstudentDao实例。
                  studentDao
                      .isStudentNumberExist(value)
                      .then(
                        (onValue) => {
                          if (onValue)
                            {
                              if (!isAdd &&
                                  (studentNumberController.text ==
                                      studentNumber))
                                _isStudentNumberUnique = true
                              else
                                _isStudentNumberUnique = false,
                            },
                        },
                      );
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '学号不能为空';
                  }
                  if (!_isStudentNumberUnique) return '$value重复使用';
                  return null; // 如果没有找到重复值，返回null表示验证通过
                },
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: '学生姓名',
                  hintText: '请输入学生姓名',
                ),
                controller: studentNameController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '姓名不能为空';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // 班级选择
              const Text('所在班级', style: TextStyle(fontSize: 16)),
              Column(
                children: List.generate(_classOptions.length, (index) {
                  return CheckboxListTile(
                    title: Text(_classOptions[index]),
                    value: _selectedClasses[index],
                    onChanged: (value) =>
                        _checkboxListTileOnProcess(index, value),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('取消'),
          onPressed: () {
            Navigator.of(context).pop(); // 关闭弹窗
          },
        ),
        TextButton(
          child: Text('保存'),
          onPressed: () async {
            if ((_formKey.currentState as FormState).validate()) {
              WidgetsFlutterBinding.ensureInitialized(); // 确保初始化Flutter绑定。对于插件很重要。
              var dbHelper = DatabaseHelper(); // 创建DatabaseHelper实例。
              var studentDao = StudentDao(dbHelper); // 创建StudentstudentDao实例。
              // 判断是新增还是修改
              if (isAdd) {
                // 新增学生
                await studentDao.insertStudent(
                  StudentModel.fromMap({
                    'class_name': classNameController.text,
                    'student_number': studentNameController.text,
                    'student_name': studentNameController.text,
                  }),
                );
              } else {
                // 修改班级
                await studentDao.updateStudentClassByClassName(
                  StudentModel.fromMap({
                    'class_name': classNameController.text,
                    'student_number': studentNameController.text,
                    'student_name': studentNameController.text,
                  }),
                ); // 插入或者更新用户数据。
              }
              var classes = await studentDao.getAllStudents(); // 获取所有班级数据。
              log(classes.toString());
              if (mounted) {
                // // 更新列表
                // Provider.of<StudentClassProvider>(
                //   context,
                //   listen: false,
                // ).changeStudentClass(
                //   classes.map((e) => StudentClassModel.fromMap(e)).toList(),
                // );
                Navigator.of(context).pop(); // 关闭弹窗
              }
            }
          },
        ),
      ],
    );
  }

  void _checkboxListTileOnProcess(int index, bool? value) {
    setState(() {
      _selectedClasses[index] = value ?? false;
      log(_selectedClasses.toString());
    });
  }
}
