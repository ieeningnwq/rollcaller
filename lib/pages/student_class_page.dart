import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../configs/strings.dart';
import '../models/student_class_model.dart';
import '../models/student_model.dart';
import '../utils/attendance_caller_dao.dart';
import '../utils/random_caller_dao.dart';
import '../utils/student_class_dao.dart';
import '../utils/student_class_relation_dao.dart';
import '../utils/student_dao.dart';
import '../widgets/student_class_add_edit_dialog.dart';

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
  dispose() {
    super.dispose();
    _refreshController.dispose();
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
              padding:  EdgeInsets.all(12.w),
              child: Text(
                KString.studentClassAppBarTitle,
                style: Theme.of(context).textTheme.headlineLarge,
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
                          itemCount: _studentClassMap.isEmpty
                              ? 1
                              : _studentClassMap.length,
                          itemBuilder: (context, index) {
                            if (_studentClassMap.isEmpty) {
                              return Center(
                                child: Text(
                                  '暂无班级',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              );
                            }
                            StudentClassModel studentClass = _studentClassMap
                                .values
                                .elementAt(index);
                            return Card(
                              color: Theme.of(context).colorScheme.surfaceContainerHigh,
                              elevation: 10.0.w,
                              margin: EdgeInsets.symmetric(
                                horizontal: 16.0.h,
                                vertical: 8.0.w,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0.r),
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.outline.withAlpha(150),
                                  width: 1.0.w,
                                ),
                              ),
                              

                              child: Padding(
                                padding: EdgeInsets.all(8.0.w),
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
                                    SizedBox(height: 4.0.h),

                                    // 中间：班级信息
                                    _classInfoWidget(studentClass),
                                    SizedBox(height: 16.0.h),
                                    // 班级备注
                                    Text(
                                      studentClass.notes,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                                      ),
                                    ),
                                    SizedBox(height: 12.0.h),
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
        backgroundColor: Theme.of(context).colorScheme.primary,
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
            if (onValue!=null && onValue) {
              _refreshClassData();
            }
          });
        },
        tooltip: '添加班级',
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
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
        List<StudentModel> students = [];
        List<int> studentIds = await StudentClassRelationDao()
            .getAllStudentIdsByClassId(item.id!);
        for (int studentId in studentIds) {
          var student = await studentDao.getStudentById(studentId);
          if (student != null) {
            students.add(student);
          }
        }
        item.classQuantity = students.length;
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

  Wrap _classNameQuantityStatusWidget(
    StudentClassModel studentClass,
    Icon statusIcon,
    Color statusColor,
    String quantityInfo,
    Color deprecationColor,
  ) => Wrap(
    spacing: 8.0.w,
    children: [
      Text(
        softWrap: true,
        overflow: TextOverflow.ellipsis,
        studentClass.className,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 16.0.h, vertical: 8.0.w),
        decoration: BoxDecoration(
          color: deprecationColor,
          borderRadius: BorderRadius.circular(12.0.r),
        ),
        child: Row(
          children: [
            statusIcon,
            SizedBox(width: 4.0.w),
            Text(
              quantityInfo,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w800,
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            ),
          ),
          SizedBox(height: 4.0.h),
          Text(
            '${studentClass.classQuantity}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12.0.h),
          Text(
            '学生现有人数',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            ),
          ),
          SizedBox(height: 4.0.h),
          Text(
            '${studentClass.studentQuantity}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '教师',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            ),
          ),
          SizedBox(height: 4.0.h),
          Text(
            studentClass.teacherName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12.0.h),
          Text(
            '创建时间',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            ),
          ),
          SizedBox(height: 4.0.h),
          Text(
            '${studentClass.created.year}-${studentClass.created.month.toString().padLeft(2, '0')}-${studentClass.created.day.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
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
        icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.secondary),
        label: Text('编辑', style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.secondary,
        )),
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
                      List<int> studentIds = await StudentClassRelationDao()
                          .getAllStudentIdsByClassId(studentClass.id!);
                      // 校验该班级是否还有随机点名器
                      var randomCallerDao = RandomCallerDao();
                      var randomCallers = await randomCallerDao
                          .getRandomCallersByClassId(studentClass.id!);
                      // 校验该班级是否还有签到点名器
                      var attendanceCallerDao = AttendanceCallerDao();
                      var attendanceCallers = await attendanceCallerDao
                          .getAttendanceCallersByClassId(studentClass.id!);
                      if (studentIds.isEmpty &&
                          randomCallers.isEmpty &&
                          attendanceCallers.isEmpty) {
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
                        Fluttertoast.showToast(
                          msg:
                              '该班级下还有学生、随机点名器、签到点名器，无法删除。请先删除班级下的所有学生、随机点名器、签到点名器。',
                        );
                        // 关闭确认弹窗
                      }
                    },
                    child: Text('删除', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    )),
                  ),
                ],
              );
            },
          );
        },
        icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
        label: Text('删除', style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.error,
        )),
      ),
    ],
  );

  Icon _getQuantityStatusIcon(StudentClassModel studentClass) {
    int classQuantity = studentClass.classQuantity;
    return classQuantity == studentClass.studentQuantity
        ? Icon(Icons.check_circle, size: 16, color: Colors.green)
        : classQuantity < studentClass.studentQuantity
        ? Icon(Icons.warning_amber, size: 16, color: Color.fromARGB(170, 146, 64, 14))
        : Icon(Icons.error, size: 16, color: Colors.red);
  }

  Color _getQuantityStatusColor(StudentClassModel studentClass) {
    int classQuantity = studentClass.classQuantity;
    return classQuantity == studentClass.studentQuantity
        ? Colors.green
        : classQuantity < studentClass.studentQuantity
        ? Color.fromARGB(170, 146, 64, 14)
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
        ? Color.fromARGB(170, 254, 243, 199)
        : Colors.red.shade100;
  }
}
