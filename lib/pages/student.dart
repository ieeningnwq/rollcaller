import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:rollcall/models/student_class_model.dart';
import 'package:rollcall/providers/class_groups_provider.dart';
import 'package:rollcall/providers/student_class_provider.dart';

import '../models/student_class_group.dart';
import '../models/student_model.dart';
import '../providers/class_selected_provider.dart';
import '../utils/student_class_dao.dart';
import '../utils/student_dao.dart';
import '../widgets/student_add_edit_dialog.dart';
import '../widgets/student_page_class_item.dart';

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  final TextEditingController _searchController = TextEditingController();

  final TextEditingController studentNumberController = TextEditingController();
  final TextEditingController studentNameController = TextEditingController();


  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      Provider.of<ClassGroupsProvider>(
        context,
        listen: false,
      ).changeFilterClassGroups(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部标题栏
            Container(
              padding: const EdgeInsets.all(12),
              child: Text(
                '学生名单管理',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            // 搜索栏
            _searchWidget(),
            // 班级列表
            Expanded(
              child: Consumer<ClassGroupsProvider>(
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
                          classGroupsProvider
                              .changeFilterClassGroupsWithoutNotify(
                                _searchController.text,
                              );
                          return SmartRefresher(
                            // 启用下拉刷新
                            enablePullDown: true,
                            // 启用上拉加载
                            enablePullUp: false,
                            // 水滴效果头部
                            header: WaterDropHeader(),
                            // 经典底部加载
                            footer: ClassicFooter(
                              loadStyle: LoadStyle.ShowWhenLoading,
                            ),
                            controller: _refreshController,
                            onRefresh: _onRefresh,
                            onLoading: _onLoading,
                            child: ListView.builder(
                              itemCount:
                                  classGroupsProvider.filterClassGroups.length,
                              itemBuilder: (context, groupIndex) {
                                return StudentPageClassItem(
                                  classGroupsProvider: classGroupsProvider,
                                  groupIndex: groupIndex,
                                  studentNameController: studentNameController,
                                  studentNumberController:
                                      studentNumberController,
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
            ),
          ],
        ),
      ),
      // 浮动添加按钮
      floatingActionButton: FloatingActionButton(
        onPressed: () => {
          // 初始化添加学生班级选择列表值
          Provider.of<StudentClassSelectedProvider>(
            context,
            listen: false,
          ).changeSelectedClassesWithoutNotify(
            List<bool>.filled(
              Provider.of<StudentClassProvider>(
                context,
                listen: false,
              ).studentClassesList.length,
              false,
            ),
          ),
          showDialog(
            context: context,
            builder: (context) => StudentAddEditDialog(
              student: StudentModel(
                studentName: '',
                studentNumber: '',
                className: '',
                created: DateTime.now(),
              ),
              title: '添加学生',
              studentNameController: studentNameController,
              studentNumberController: studentNumberController,
            ),
          ),
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<List<StudentClassGroup>> _getAllStudentsByClassNames() async {
    WidgetsFlutterBinding.ensureInitialized(); // 确保初始化Flutter绑定。对于插件很重要。
    var studentDao = StudentDao(); // 创建StudentDao实例。
    List<StudentClassGroup> classGroups = [];
    final List<StudentClassModel> studentClasses = [];
    // 获取所有班级数据
    WidgetsFlutterBinding.ensureInitialized(); // 确保初始化Flutter绑定。对于插件很重要。
    var classDao = StudentClassDao(); // 创建StudentClassDao实例。
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
    }
    // 查询有的学生没有班级
    var allStudents = await studentDao.getAllStudentsWithoutClassName();
    var studentClass = StudentClassModel(
      className: '无班级学生',
      studentQuantity: allStudents.length,
      teacherName: '',
      notes: '',
      classQuantity: allStudents.length,
      created: DateTime.now(),
    );
    studentClass.id = -1;
    StudentClassGroup classGroup = StudentClassGroup(
      studentClass: studentClass,
      students: allStudents.map((e) => StudentModel.fromMap(e)).toList(),
    );
    classGroups.add(classGroup);
    return classGroups;
  }

  @override
  dispose() {
    studentNumberController.dispose();
    studentNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _refreshClassGroupData() async {
    List<StudentClassGroup> classGroups = await _getAllStudentsByClassNames();

    if (context.mounted) {
      ClassGroupsProvider classGroupsProvider =
          Provider.of<ClassGroupsProvider>(context, listen: false);
      // 更新全部数据
      classGroupsProvider.changeClassGroupsWithoutNotify(classGroups);
      // 更新列表
      classGroupsProvider.changeFilterClassGroups(_searchController.text);
    }
  }

  void _onRefresh() async {
    _refreshClassGroupData();
    // 刷新完成
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    // _refreshClassGroupData();
    // 加载完成
    _refreshController.loadComplete();
  }

  Padding _searchWidget() => Padding(
    padding: const EdgeInsets.all(8),
    child: TextField(
      controller: _searchController,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: '搜索学号或姓名...',
        hintStyle: TextStyle(fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        filled: true,
      ),
    ),
  );
}
