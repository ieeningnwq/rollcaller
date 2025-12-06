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

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentClassProvider>(
      builder: (context, studentClassProvider, child) {
        return Scaffold(
          // appBar: AppBar(title: const Text(KString.studentClassAppBarTitle)),
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
                    future: _getStudentClassList(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          List<Map<String, dynamic>>? data = snapshot.data;
                          log(data.toString());
                          List<StudentClassModel> studentClassList = [];
                          for (Map<String, dynamic> item in data!) {
                            studentClassList.add(
                              StudentClassModel.fromMap(item),
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

  Future<List<Map<String, dynamic>>> _getStudentClassList() async {
    WidgetsFlutterBinding.ensureInitialized(); // 确保初始化Flutter绑定。对于插件很重要。
    var classDao = StudentClassDao(); // 创建StudentClassDao实例。
    StudentDao studentDao = StudentDao();
    List<Map<String, dynamic>> data = [];
    List<Map<String, dynamic>> studentClasses = await classDao
        .getAllStudentClasses();
    if (studentClasses.isNotEmpty) {
      for (Map<String, dynamic> item in studentClasses) {
        Map<String, dynamic> copyItem = Map.from(item);
        List<Map<String, dynamic>> number = await studentDao
            .getAllStudentsByClassName(item['class_name']);
        copyItem['class_quantity'] = number.length;
        data.add(copyItem);
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
    var classes = await _getStudentClassList();
    if (mounted) {
      // 更新列表
      Provider.of<StudentClassProvider>(
        context,
        listen: false,
      ).changeStudentClass(
        classes.map((e) => StudentClassModel.fromMap(e)).toList(),
      );
    }
  }

  void _onLoading() async {
    _refreshClassData();
    // 加载完成
    _refreshController.loadComplete();
  }
}
