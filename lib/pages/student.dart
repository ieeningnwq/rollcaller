import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:rollcall/configs/strings.dart';
import 'package:rollcall/models/student_class_model.dart';
import 'package:rollcall/providers/class_groups_provider.dart';
import 'package:rollcall/providers/student_class_provider.dart';

import '../models/student_class_group.dart';
import '../models/student_model.dart';
import '../providers/class_selected_provider.dart';
import '../utils/database_helper.dart';
import '../utils/student_class_dao.dart';
import '../utils/student_dao.dart';

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  final TextEditingController _searchController = TextEditingController();

  final TextEditingController studentNumberController = TextEditingController();
  final TextEditingController studentNameController = TextEditingController();

  final GlobalKey _formKey = GlobalKey<FormState>();
  bool _isStudentNumberUnique = true;

  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(KString.studentClassTitle)),
      body: Consumer<ClassGroupsProvider>(
        builder: (context, classGroupsProvider, child) {
          return FutureBuilder(
            future: _getAllStudentsByClassNames(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  classGroupsProvider.changeClassGroupsWithoutNotify(
                    snapshot.data as List<StudentClassGroup>,
                  );
                  classGroupsProvider.changeFilterClassGroupsWithoutNotify(
                    _searchController.text,
                  );
                  return SmartRefresher(
                    // 启用下拉刷新
                    enablePullDown: true,
                    // 启用上拉加载
                    enablePullUp: true,
                    // 水滴效果头部
                    header: WaterDropHeader(),
                    // 经典底部加载
                    footer: ClassicFooter(loadStyle: LoadStyle.ShowWhenLoading),
                    controller: _refreshController,
                    onRefresh: _onRefresh,
                    onLoading: _onLoading,
                    child: ListView.builder(
                      itemCount: classGroupsProvider.filterClassGroups.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                            classGroupsProvider
                                .filterClassGroups[index]
                                .studentClass
                                .className,
                          ),
                          subtitle: Text(
                            '${classGroupsProvider.filterClassGroups[index].students.length} 人',
                          ),
                          onTap: () {},
                        );
                      },
                    ),
                  );
                }
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          );
        },
      ),
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
  }) {
    // 判断是新增还是修改
    bool isAdd = title == '创建学生';
    studentNameController.text = studentName;
    studentNumberController.text = studentNumber;

    Provider.of<StudentClassSelectedProvider>(
      context,
      listen: false,
    ).changeSelectedClassesWithoutNotify(
      List<bool>.filled(
        Provider.of<StudentClassProvider>(context).studentClassesList.length,
        false,
      ),
    );

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
                            }
                          else
                            _isStudentNumberUnique = true,
                        },
                      );
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '学号不能为空';
                  }
                  if (!_isStudentNumberUnique) {
                    return '$value重复使用';
                  }
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
              Consumer<StudentClassSelectedProvider>(
                builder: (context, selectedClassProvider, child) {
                  return Column(
                    children: List.generate(classOptions.length, (index) {
                      return CheckboxListTile(
                        title: Text(classOptions[index]),
                        value: selectedClassProvider.selectedClasses[index],
                        onChanged: (value) {
                          selectedClassProvider.setSelectedClasses(
                            index,
                            value,
                          );
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      );
                    }),
                  );
                },
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
              String selectedClassListStr =
                  Provider.of<StudentClassSelectedProvider>(
                        context,
                        listen: false,
                      ).selectedClasses
                      .asMap()
                      .entries
                      .where((entry) => entry.value)
                      .map((entry) => classOptions[entry.key])
                      .toList()
                      .join(',');
              // 判断是新增还是修改
              if (isAdd) {
                // 新增学生
                await studentDao.insertStudent(
                  StudentModel.fromMap({
                    'class_name': selectedClassListStr,
                    'student_number': studentNumberController.text,
                    'student_name': studentNameController.text,
                  }),
                );
              } else {
                // 修改学生
                await studentDao.updateStudentClassByClassName(
                  StudentModel.fromMap({
                    'class_name': selectedClassListStr,
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

  Future<List<StudentClassGroup>> _getAllStudentsByClassNames() async {
    WidgetsFlutterBinding.ensureInitialized(); // 确保初始化Flutter绑定。对于插件很重要。
    var dbHelper = DatabaseHelper(); // 创建DatabaseHelper实例。
    var studentDao = StudentDao(dbHelper); // 创建StudentDao实例。
    List<StudentClassGroup> classGroups = [];
    final List<StudentClassModel> studentClasses = [];
    // 获取所有班级数据
    WidgetsFlutterBinding.ensureInitialized(); // 确保初始化Flutter绑定。对于插件很重要。
    var classDao = StudentClassDao(dbHelper); // 创建StudentClassDao实例。
    await classDao.getAllStudentClasses().then(
      (value) => studentClasses.addAll(
        value.map((e) => StudentClassModel.fromMap(e)).toList(),
      ),
    );
    for (StudentClassModel classModel in studentClasses) {
      var students = await studentDao.getAllStudentsByClassName(
        classModel.className,
      );
      StudentClassGroup classGroup = StudentClassGroup(
        studentClass: classModel,
        students: students.map((e) => StudentModel.fromMap(e)).toList(),
      );
      classGroups.add(classGroup);
      log(classGroup.toString());
    }
    return classGroups;
  }

  @override
  dispose() {
    studentNumberController.dispose();
    studentNameController.dispose();
    super.dispose();
  }

  void _onRefresh() async {
    List<StudentClassGroup> classGroups = await _getAllStudentsByClassNames();

    if (context.mounted) {
      ClassGroupsProvider classGroupsProvider =
          Provider.of<ClassGroupsProvider>(context, listen: false);
      // 更新全部数据
      classGroupsProvider.changeClassGroupsWithoutNotify(classGroups);
      // 更新列表
      classGroupsProvider.changeFilterClassGroups(_searchController.text);
    }
    // 刷新完成
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    List<StudentClassGroup> classGroups = await _getAllStudentsByClassNames();
    if (context.mounted) {
      ClassGroupsProvider classGroupsProvider =
          Provider.of<ClassGroupsProvider>(context, listen: false);
      // 更新全部数据
      classGroupsProvider.changeClassGroupsWithoutNotify(classGroups);
      // 更新列表
      classGroupsProvider.changeFilterClassGroups(_searchController.text);
    }
    // 加载完成
    _refreshController.loadComplete();
  }
}
