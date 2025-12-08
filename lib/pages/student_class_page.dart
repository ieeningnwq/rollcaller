import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:rollcall/utils/student_dao.dart';
import 'package:rollcall/widgets/student_class_add_edit_dialog.dart';

import '../configs/strings.dart';
import '../models/student_class_model.dart';
import '../providers/student_class_provider.dart';
import '../utils/student_class_dao.dart';
import '../widgets/class_item_card.dart';

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

  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );

  // 存储Future对象，避免每次build都创建新的Future
  late Future<List<StudentClassModel>> _studentClassFuture;

  @override
  initState() {
    _studentClassFuture = _getStudentClassList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentClassProvider>(
      builder: (context, studentClassProvider, child) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部标题栏
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    KString.studentClassAppBarTitle,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: FutureBuilder(
                    future: _studentClassFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          List<StudentClassModel>? data = snapshot.data;
                          List<StudentClassModel> studentClassList = [];
                          for (StudentClassModel item in data!) {
                            studentClassList.add(
                              item,
                            );
                          }
                          studentClassProvider.changeStudentClassWithoutNotify(
                            studentClassList,
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
                              scrollDirection: Axis.vertical,
                              itemCount: snapshot.data?.length ?? 0,
                              itemBuilder: (context, index) {
                                return ClassItemCard(
                                  index: index,
                                  studentClassProvider: studentClassProvider,
                                  classNameController: classNameController,
                                  studentQuantityController:
                                      studentQuantityController,
                                  teacherNameController: teacherNameController,
                                  notesController: notesController,
                                );
                              },
                            ),
                          );
                        }
                      } else {
                        return Center(child: Text('没有数据...'));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return StudentClassAddEditDialog(
                    studentClass: StudentClassModel(
                      className: '',
                      studentQuantity: 0,
                      teacherName: '',
                      notes: '',
                      created: DateTime.now(),
                    ),
                    title: '添加班级',
                    studentClassProvider: studentClassProvider,
                    classNameController: classNameController,
                    teacherNameController: teacherNameController,
                    notesController: notesController,
                    studentQuantityController: studentQuantityController,
                  );
                },
              );
            },
            tooltip: '添加班级',
            child: Icon(Icons.add),
          ),
        );
      },
    );
  }

  Future<List<StudentClassModel>> _getStudentClassList() async {
    WidgetsFlutterBinding.ensureInitialized(); // 确保初始化Flutter绑定。对于插件很重要。
    var classDao = StudentClassDao(); // 创建StudentClassDao实例。
    StudentDao studentDao = StudentDao();
    List<StudentClassModel> data = [];
    List<StudentClassModel> studentClasses = await classDao
        .getAllStudentClasses();
    if (studentClasses.isNotEmpty) {
      for (StudentClassModel item in studentClasses) {
        List<Map<String, dynamic>> number = await studentDao
            .getAllStudentsByClassName(item.className);
        item.classQuantity = number.length;
        data.add(item);
      }
    }
    return data;
  }

  @override
  dispose() {
    super.dispose();
    classNameController.dispose();
    studentQuantityController.dispose();
    teacherNameController.dispose();
    notesController.dispose();
  }

  void _onRefresh() async {
    _refreshClassData();
    // 刷新完成
    _refreshController.refreshCompleted();
  }

  Future<void> _refreshClassData() async {
    setState(() {
      _studentClassFuture = _getStudentClassList();
    });
  }

  void _onLoading() async {
    _refreshClassData();
    // 加载完成
    _refreshController.loadComplete();
  }
}
