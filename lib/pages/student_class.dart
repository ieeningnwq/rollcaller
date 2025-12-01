import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rollcall/models/student_class_model.dart';
import 'package:rollcall/utils/student_class_dao.dart';

import '../providers/student_class_provider.dart';
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

  final GlobalKey _formKey = GlobalKey<FormState>();
  bool _isClassNameUnique = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentClassProvider>(
      builder: (context, studentClassProvider, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('班级管理')),
          body: FutureBuilder(
            future: _getStudentClassList(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                List<Map<String, dynamic>>? data = snapshot.data;
                log(data.toString());
                List<StudentClassModel> studentClassList = [];
                for (Map<String, dynamic> item in data!) {
                  studentClassList.add(StudentClassModel.fromMap(item));
                }
                studentClassProvider.studentClassList = studentClassList;
                return ListView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: studentClassProvider.studentClassList.length,
                  itemBuilder: (context, index) {
                    return _classCardItem(
                      index,
                      studentClassProvider.studentClassList[index],
                      context,
                    );
                  },
                );
              } else {
                return Center(child: Text('数据加载中...'));
              }
            },
          ),
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
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getStudentClassList() {
    WidgetsFlutterBinding.ensureInitialized(); // 确保初始化Flutter绑定。对于插件很重要。
    var dbHelper = DatabaseHelper(); // 创建DatabaseHelper实例。
    var classDao = StudentClassDao(dbHelper); // 创建StudentClassDao实例。
    return classDao.getAllStudentClasses();
  }

  AlertDialog _studentClassDialog(
    String title, {
    String className = '',
    int studentQuantity = 0,
    String teacherName = '',
    String notes = '',
  }) {
    // 判断是新增还是修改
    bool isAdd = title == '创建班级';
    classNameController.text = className;
    studentQuantityController.text = studentQuantity.toString();
    teacherNameController.text = teacherName;
    notesController.text = notes;
    return AlertDialog(
      title: Text(title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              decoration: InputDecoration(labelText: '班级名称'),
              controller: classNameController,
              autovalidateMode: AutovalidateMode.onUnfocus,
              onChanged: (value) {
                WidgetsFlutterBinding.ensureInitialized(); // 确保初始化Flutter绑定。对于插件很重要。
                var dbHelper = DatabaseHelper(); // 创建DatabaseHelper实例。
                var classDao = StudentClassDao(
                  dbHelper,
                ); // 创建StudentClassDao实例。
                classDao
                    .isStudentClassesNameExist(value)
                    .then(
                      (onValue) => {
                        if (onValue)
                          {
                            if (!isAdd &&
                                (classNameController.text == className))
                              _isClassNameUnique = true
                            else
                              _isClassNameUnique = false,
                          },
                      },
                    );
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '班级名称不能为空';
                }
                if (!_isClassNameUnique) return '$value重复使用';
                return null; // 如果没有找到重复值，返回null表示验证通过
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
                }
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
              var classDao = StudentClassDao(dbHelper); // 创建StudentClassDao实例。
              // 判断是新增还是修改
              if (isAdd) {
                // 新增班级
                await classDao.insertStudentClass(
                  StudentClassModel.fromMap({
                    'class_name': classNameController.text,
                    'student_quantity': int.parse(
                      studentQuantityController.text,
                    ),
                    'teacher_name': teacherNameController.text,
                    'notes': notesController.text,
                  }),
                ); // 插入或者更新用户数据。
              } else {
                // 修改班级
                await classDao.updateStudentClassByClassName(
                  StudentClassModel.fromMap({
                    'class_name': classNameController.text,
                    'student_quantity': int.parse(
                      studentQuantityController.text,
                    ),
                    'teacher_name': teacherNameController.text,
                    'notes': notesController.text,
                  }),
                ); // 插入或者更新用户数据。
              }
              var classes = await classDao.getAllStudentClasses(); // 获取所有班级数据。
              log(classes.toString());
              if (mounted) {
                // 更新列表
                Provider.of<StudentClassProvider>(
                  context,
                  listen: false,
                ).changeStudentClass(
                  classes.map((e) => StudentClassModel.fromMap(e)).toList(),
                );
                Navigator.of(context).pop(); // 关闭弹窗
              }
            }
          },
        ),
      ],
    );
  }

  Widget _classCardItem(int index, StudentClassModel studentClass, context) {
    // 检查是否人数已满
    bool isFull = studentClass.studentQuantity >= 45; // 假设45是班级最大人数

    return Card(
      elevation: 2.0,
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部：班级名称和人数已满标签
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  studentClass.className,
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 16.0, color: Colors.green),
                      SizedBox(width: 4.0),
                      Text(
                        '人数已满',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0),

            // 中间：班级信息
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '班级人数',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      '${studentClass.studentQuantity}',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 12.0),
                    Text(
                      '学生人数',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      '${studentClass.studentQuantity}',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '教师',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      studentClass.teacherName,
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 12.0),
                    Text(
                      '创建时间',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      '${studentClass.created.year}-${studentClass.created.month.toString().padLeft(2, '0')}-${studentClass.created.day.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16.0),

            // 班级备注
            Text(
              studentClass.notes,
              style: TextStyle(fontSize: 14.0, color: Colors.grey.shade700),
            ),
            SizedBox(height: 16.0),

            // 底部操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // 查看按钮点击事件
                  },
                  icon: Icon(Icons.visibility, color: Colors.blue),
                  label: Text('查看', style: TextStyle(color: Colors.blue)),
                ),
                SizedBox(width: 8.0),
                TextButton.icon(
                  onPressed: () {
                    // 编辑按钮点击事件
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return _studentClassDialog(
                          '编辑班级',
                          className: studentClass.className,
                          studentQuantity: studentClass.studentQuantity,
                          teacherName: studentClass.teacherName,
                          notes: studentClass.notes,
                        );
                      },
                    );
                  },
                  icon: Icon(Icons.edit, color: Colors.blue),
                  label: Text('编辑', style: TextStyle(color: Colors.blue)),
                ),
                SizedBox(width: 8.0),
                TextButton.icon(
                  onPressed: () {
                    var dbHelper = DatabaseHelper(); // 创建DatabaseHelper实例。
                    var classDao = StudentClassDao(
                      dbHelper,
                    ); // 创建StudentClassDao实例。
                    // 删除按钮点击事件
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('确认删除'),
                          content: Text(
                            '确定要删除班级“${studentClass.className}”吗？此操作不可恢复。',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('取消'),
                            ),
                            TextButton(
                              onPressed: () async {
                                await classDao.deleteStudentClassByClassName(
                                  studentClass.className,
                                );
                                var classes = await classDao
                                    .getAllStudentClasses();
                                if (context.mounted) {
                                  Provider.of<StudentClassProvider>(
                                    context,
                                    listen: false,
                                  ).changeStudentClass(
                                    classes
                                        .map(
                                          (e) => StudentClassModel.fromMap(e),
                                        )
                                        .toList(),
                                  );
                                  Navigator.of(context).pop(); // 关闭确认弹窗
                                }
                              },
                              child: Text(
                                '删除',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: Icon(Icons.delete, color: Colors.red),
                  label: Text('删除', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  dispose() {
    super.dispose();
    classNameController.dispose();
    studentQuantityController.dispose();
    teacherNameController.dispose();
    notesController.dispose();
  }
}
