import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:rollcall/models/student_model.dart';
import 'package:rollcall/utils/student_dao.dart';
import 'package:rollcall/widgets/student_class_add_edit_dialog.dart';

import '../configs/strings.dart';
import '../models/student_class_model.dart';
import '../utils/student_class_dao.dart';

class StudentClassPage extends StatefulWidget {
  const StudentClassPage({super.key});

  @override
  State<StatefulWidget> createState() => _StudentClassState();
}

class _StudentClassState extends State<StudentClassPage> {
  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );

  // 存储Future对象，避免每次build都创建新的Future
  late Future<Map<int, StudentClassModel>> _studentClassFuture;

  // 所有班级对象
  late Map<int, StudentClassModel> _studentClassMap;

  @override
  initState() {
    _studentClassFuture = _getStudentClassList();
    super.initState();
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
                      _studentClassMap = snapshot.data!;
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
                            StudentClassModel studentClass = _studentClassMap
                                .values
                                .elementAt(index);
                            return Card(
                              elevation: 2.0,
                              margin: EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),

                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 顶部：班级名称和人数已满标签
                                    _classNameQuantityStatusWidget(
                                      studentClass,
                                      _getQuantityStatusIcon(studentClass),
                                      _getQuantityStatusColor(studentClass),
                                      _getQuantityStatusInfo(studentClass),
                                      _getQuantityStatusDecorationColor(
                                        studentClass,
                                      ),
                                    ),
                                    const SizedBox(height: 4.0),

                                    // 中间：班级信息
                                    _classInfoWidget(studentClass),
                                    SizedBox(height: 16.0),
                                    // 班级备注
                                    Text(
                                      studentClass.notes,
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    SizedBox(height: 12.0),
                                    // 底部操作按钮
                                    _actionsWidget(context, studentClass),
                                  ],
                                ),
                              ),
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
              );
            },
          ).then((onValue) {
            if (onValue) {
              _refreshClassData();
            }
          });
        },
        tooltip: '添加班级',
        child: Icon(Icons.add),
      ),
    );
  }

  Future<Map<int, StudentClassModel>> _getStudentClassList() async {
    WidgetsFlutterBinding.ensureInitialized(); // 确保初始化Flutter绑定。对于插件很重要。
    var classDao = StudentClassDao(); // 创建StudentClassDao实例。
    StudentDao studentDao = StudentDao();
    Map<int, StudentClassModel> data = {};
    List<StudentClassModel> studentClasses = await classDao
        .getAllStudentClasses();
    if (studentClasses.isNotEmpty) {
      for (StudentClassModel item in studentClasses) {
        List<StudentModel> number = await studentDao.getAllStudentsByClassName(
          item.className,
        );
        item.classQuantity = number.length;
        data[item.id!] = item;
      }
    }
    return data;
  }

  void _onRefresh() async {
    _refreshClassData();
    // 刷新完成
    _refreshController.refreshCompleted();
  }

  void _refreshClassData() {
    setState(() {
      _studentClassFuture = _getStudentClassList();
    });
  }

  void _onLoading() async {
    _refreshClassData();
    // 加载完成
    _refreshController.loadComplete();
  }

  Row _classNameQuantityStatusWidget(
    StudentClassModel studentClass,
    Icon statusIcon,
    Color statusColor,
    String quantityInfo,
    Color deprecationColor,
  ) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        studentClass.className,
        style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
      ),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: deprecationColor,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          children: [
            statusIcon,
            SizedBox(width: 4.0),
            Text(
              quantityInfo,
              style: TextStyle(
                fontSize: 12.0,
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Row _classInfoWidget(StudentClassModel studentClass) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '班级现有人数',
            style: TextStyle(fontSize: 14.0, color: Colors.grey.shade600),
          ),
          SizedBox(height: 4.0),
          Text(
            '${studentClass.classQuantity}',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 12.0),
          Text(
            '学生现有人数',
            style: TextStyle(fontSize: 14.0, color: Colors.grey.shade600),
          ),
          SizedBox(height: 4.0),
          Text(
            '${studentClass.studentQuantity}',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '教师',
            style: TextStyle(fontSize: 14.0, color: Colors.grey.shade600),
          ),
          SizedBox(height: 4.0),
          Text(
            studentClass.teacherName,
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 12.0),
          Text(
            '创建时间',
            style: TextStyle(fontSize: 14.0, color: Colors.grey.shade600),
          ),
          SizedBox(height: 4.0),
          Text(
            '${studentClass.created.year}-${studentClass.created.month.toString().padLeft(2, '0')}-${studentClass.created.day.toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ],
  );

  Row _actionsWidget(
    BuildContext context,
    StudentClassModel studentClass,
  ) => Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      TextButton.icon(
        onPressed: () {
          // 编辑按钮点击事件
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return StudentClassAddEditDialog(
                studentClass: studentClass,
                title: '编辑班级',
              );
            },
          ).then((onValue) {
            if (onValue != null && onValue == true) {
              _refreshClassData();
            }
          });
        },
        icon: Icon(Icons.edit, color: Colors.blue),
        label: Text('编辑', style: TextStyle(color: Colors.blue)),
      ),
      SizedBox(width: 8.0),
      TextButton.icon(
        onPressed: () {
          var classDao = StudentClassDao(); // 创建StudentClassDao实例。
          // 删除按钮点击事件
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('确认删除'),
                content: Text('确定要删除班级“${studentClass.className}”吗？此操作不可恢复。'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('取消'),
                  ),
                  TextButton(
                    onPressed: () async {
                      // 校验该班级下是否还有学生
                      var studentDao = StudentDao();
                      var students = await studentDao.getAllStudentsByClassName(
                        studentClass.className,
                      );
                      if (students.isEmpty) {
                        classDao
                            .deleteStudentClassByClassName(
                              studentClass.className,
                            )
                            .then((value) {
                              if (value != 0) {
                                // 删除成功
                                setState(() {
                                  _studentClassMap.remove(studentClass.id!);
                                });
                                if (context.mounted) {
                                  Navigator.of(context).pop(); // 关闭确认弹窗
                                }
                              }
                            });
                      } else {
                        // 班级下还有学生，提示用户先删除学生
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('提示'),
                                content: Text('该班级下还有学生，无法删除。请先删除班级下的所有学生。'),
                                actions: [
                                  TextButton(
                                    onPressed: () => {
                                      Navigator.of(context).pop(),
                                      Navigator.of(context).pop(),
                                    },
                                    child: Text('确定'),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                        // 关闭确认弹窗
                      }
                    },
                    child: Text('删除', style: TextStyle(color: Colors.red)),
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
  );

  Icon _getQuantityStatusIcon(StudentClassModel studentClass) {
    int classQuantity = studentClass.classQuantity;
    return classQuantity == studentClass.studentQuantity
        ? Icon(Icons.check_circle, size: 16, color: Colors.green)
        : classQuantity < studentClass.studentQuantity
        ? Icon(Icons.warning_amber, size: 16, color: Colors.yellow)
        : Icon(Icons.error, size: 16, color: Colors.red);
  }

  Color _getQuantityStatusColor(StudentClassModel studentClass) {
    int classQuantity = studentClass.classQuantity;
    return classQuantity == studentClass.studentQuantity
        ? Colors.green
        : classQuantity < studentClass.studentQuantity
        ? Colors.yellow
        : Colors.red;
  }

  String _getQuantityStatusInfo(StudentClassModel studentClass) {
    int classQuantity = studentClass.classQuantity;
    return classQuantity == studentClass.studentQuantity
        ? '人数已满'
        : classQuantity < studentClass.studentQuantity
        ? '人数未满'
        : '人数超员';
  }

  Color _getQuantityStatusDecorationColor(StudentClassModel studentClass) {
    int classQuantity = studentClass.classQuantity;
    return classQuantity == studentClass.studentQuantity
        ? Colors.green.shade100
        : classQuantity < studentClass.studentQuantity
        ? Colors.yellow.shade100
        : Colors.red.shade100;
  }
}
