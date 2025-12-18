import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../configs/attendance_status.dart';
import '../configs/strings.dart';
import '../models/attendance_call_record.dart';
import '../models/attendance_caller_group.dart';
import '../models/attendance_caller_model.dart';
import '../models/student_class_model.dart';
import '../models/student_model.dart';
import '../utils/attendance_call_record_dao.dart';
import '../utils/attendance_caller_dao.dart';
import '../utils/student_class_dao.dart';
import '../utils/student_class_relation_dao.dart';
import '../utils/student_dao.dart';
import '../widgets/attendance_caller_add_edit_dialog.dart';
import '../widgets/attendance_caller_view_dialog.dart';

class AttendencePage extends StatefulWidget {
  const AttendencePage({super.key});

  @override
  State<StatefulWidget> createState() => _AttendencePageState();
}

class _AttendencePageState extends State<AttendencePage> {
  // 点名器信息是否折叠
  bool _isAttendanceCallerInfoWidgetExpanded = true;
  // 当前选择随机点名器
  int? _selectedCallerId;
  // 所有签到点名器
  Map<int, AttendanceCallerModel> _allAttendaceCallersMap = {};
  // 签到点名器、班级、学生、点名记录信息
  AttendanceCallerGroupModel? _attendanceCallerGroup;
  // 获取当前点名器所有信息Future
  Future<AttendanceCallerGroupModel?>? _attendanceCallerFuture;
  // 搜索框控制器
  final TextEditingController _searchController = TextEditingController();
  // 签到状态
  final stats = {
    AttendanceStatus.present: 0,
    AttendanceStatus.late: 0,
    AttendanceStatus.excused: 0,
    AttendanceStatus.absent: 0,
  };
  List<StudentModel> _students = [];
  // 过滤后的学生列表{'studentName+Number':studentModel}
  List<StudentModel> _filteredStudents = [];
  @override
  initState() {
    super.initState();
    _searchController.addListener(() {
      // 更新筛选列表
      if (_searchController.text.isEmpty) {
        setState(() {
          _filteredStudents = _students;
        });
      } else {
        setState(() {
          _filteredStudents = _students.where((student) {
            return student.studentName.contains(_searchController.text) ||
                student.studentNumber.contains(_searchController.text);
          }).toList();
        });
      }
    });

    _attendanceCallerFuture = _getAttendanceCallerPageInfo();
  }

  Future<AttendanceCallerGroupModel?> _getAttendanceCallerPageInfo() async {
    try {
      Map<int, AttendanceCallRecordModel> attendanceCallRecords = {};
      // 获取全部签到点名器
      List<AttendanceCallerModel> allAttendanceCallers =
          await AttendanceCallerDao().getAllIsNotArchiveAttendanceCallers();
      // 保存全部签到点名器
      _allAttendaceCallersMap = {
        for (var attendanceCaller in allAttendanceCallers)
          attendanceCaller.id: attendanceCaller,
      };
      // 初始选择第一个签到点名器
      _selectedCallerId ??= allAttendanceCallers.isNotEmpty
          ? allAttendanceCallers.first.id
          : null;
      if (_selectedCallerId != null) {
        AttendanceCallerModel selectedCaller =
            _allAttendaceCallersMap[_selectedCallerId!]!;
        // 获取班级信息
        StudentClassModel studentClass = await StudentClassDao()
            .getStudentClass(selectedCaller.classId);
        // 获取班级学生
        List<StudentModel> students = [];
        List<int> studentIds = await StudentClassRelationDao()
            .getAllStudentIdsByClassId(studentClass.id!);
        for (int studentId in studentIds) {
          var student = await StudentDao().getStudentById(studentId);
          if (student != null) {
            students.add(student);
          }
        }
        // 学生列表
        _students = students;
        _sortStudents();
        // 过滤后的学生列表
        _filteredStudents = students;
        // 获取签到记录
        List<AttendanceCallRecordModel> records =
            await AttendanceCallRecordDao().getRecordsByCallerId(
              callerId: selectedCaller.id,
            );
        // 构建签到记录映射
        for (AttendanceCallRecordModel record in records) {
          attendanceCallRecords[record.studentId] = record;
        }
        // 如果有学生没有状态，那么添加默认值
        for (StudentModel student in students) {
          if (!attendanceCallRecords.containsKey(student.id)) {
            var attendanceCallRecord = AttendanceCallRecordModel.fromMap({
              'attendance_caller_id': selectedCaller.id,
              'student_id': student.id,
            });
            // 将没有签到记录的学生插入记录数据库
            int id = await AttendanceCallRecordDao().insertAttendanceCallRecord(
              attendanceCallRecord,
            );
            // 赋值id
            attendanceCallRecord.id = id;
            attendanceCallRecords[student.id!] = attendanceCallRecord;
          }
        }
        // 构建并返回分组模型
        return AttendanceCallerGroupModel(
          attendanceCallerModel: selectedCaller,
          students: {for (var student in students) student.id!: student},
          studentClassModel: studentClass,
          attendanceCallRecords: attendanceCallRecords,
        );
      } else {
        _students = [];
        _filteredStudents = [];
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // 学生排序方法：按学号排序
  void _sortStudents() {
    _students.sort((a, b) {
      // 直接按学号排序
      return a.studentNumber.compareTo(b.studentNumber);
    });
  }

  // 获取签到统计数据
  Map<AttendanceStatus, int> _getAttendanceStats() {
    final stats = {
      AttendanceStatus.present: 0,
      AttendanceStatus.late: 0,
      AttendanceStatus.excused: 0,
      AttendanceStatus.absent: 0,
    };
    // 遍历学生，如果没有签到记录则添加插入默认值
    for (StudentModel student
        in _attendanceCallerGroup?.students.values ?? []) {
      var record = _attendanceCallerGroup!.attendanceCallRecords[student.id!]!;
      stats[record.present] = (stats[record.present] ?? 0) + 1;
    }
    return stats;
  }

  // 切换签到状态
  void _toggleAttendanceStatus(int index) {
    final currentStatus = _attendanceCallerGroup!
        .attendanceCallRecords[_filteredStudents[index].id!]!
        .present;
    final statuses = [
      AttendanceStatus.absent,
      AttendanceStatus.present,
      AttendanceStatus.late,
      AttendanceStatus.excused,
    ];
    final currentIndex = statuses.indexOf(currentStatus);
    final nextIndex = (currentIndex + 1) % statuses.length;
    setState(() {
      _attendanceCallerGroup!
              .attendanceCallRecords[_filteredStudents[index].id!]!
              .present =
          statuses[nextIndex];
    });
    // 更新数据库
    AttendanceCallRecordDao().updateAttendanceCallRecord(
      _attendanceCallerGroup!.attendanceCallRecords[_filteredStudents[index]
          .id!]!,
    );
  }

  @override
  dispose() {
    super.dispose();
    _searchController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FutureBuilder<AttendanceCallerGroupModel?>(
        future: _attendanceCallerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('${KString.errorPrefix}${snapshot.error}');
          } else {
            _attendanceCallerGroup = snapshot.data;
            // 更新签到数据
            final stats = _getAttendanceStats();
            // 签到人数
            final presentCount = stats[AttendanceStatus.present] ?? 0;
            // 总的人数
            final totalCount = _attendanceCallerGroup?.students.length ?? 0;
            //签到率
            final attendanceRate = totalCount > 0
                ? (presentCount / totalCount) * 100
                : 0;
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(left: 8.w, right: 8.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildAttendanceCallerInfoWidget(),
                        // 搜索框
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8.r),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).shadowColor.withAlpha(100),
                                spreadRadius: 1.r,
                                blurRadius: 3.r,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.search,
                                size: Theme.of(
                                  context,
                                ).textTheme.labelLarge?.fontSize,
                              ),
                              hintText: KString.searchStudent, // 搜索学生
                              hintStyle: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        // 签到状态列表
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8.r),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).shadowColor.withAlpha(20),
                                spreadRadius: 1.r,
                                blurRadius: 3.r,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 标题行 - 固定在顶部
                              Padding(
                                padding: EdgeInsets.all(12.w),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          KString.attendanceStatus, // 签到状态
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                              ),
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          '${KString.totalCountPrefix}$totalCount${KString.peopleountSuffix}', // 共X人
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withAlpha(100),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                height: 1,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(100),
                              ),

                              // 学生列表 - 可滚动
                              _filteredStudents.isNotEmpty
                                  ? ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: _filteredStudents.length,
                                      itemBuilder: (context, index) {
                                        final StudentModel student =
                                            _filteredStudents[index];
                                        return Column(
                                          children: [
                                            ListTile(
                                              onTap: () =>
                                                  _toggleAttendanceStatus(
                                                    index,
                                                  ),
                                              title: Text(
                                                student.studentName,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.onSurface,
                                                    ),
                                              ),
                                              subtitle: Text(
                                                '${KString.studentNumberPrefix}${student.studentNumber}', // 学号：X
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface
                                                          .withAlpha(100),
                                                    ),
                                              ),
                                              trailing: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 12.h,
                                                  vertical: 8.w,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _attendanceCallerGroup!
                                                      .attendanceCallRecords[student
                                                          .id!]!
                                                      .present
                                                      .statusColor,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        12.r,
                                                      ),
                                                ),
                                                child: Text(
                                                  _attendanceCallerGroup!
                                                      .attendanceCallRecords[student
                                                          .id!]!
                                                      .present
                                                      .statusText,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color: Colors.white,
                                                      ),
                                                ),
                                              ),
                                            ),
                                            if (index <
                                                _filteredStudents.length - 1)
                                              Divider(
                                                height: 1,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withAlpha(100),
                                              ),
                                          ],
                                        );
                                      },
                                    )
                                  : Center(
                                      child: Text(
                                        KString.noStudent, // 暂无学生
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withAlpha(100),
                                            ),
                                      ),
                                    ),
                            ],
                          ),
                        ),

                        SizedBox(height: 8.h),
                      ],
                    ),
                  ),
                ),
                // 签到统计 - 固定在底部
                Container(
                  margin: EdgeInsets.only(left: 8.w, right: 8.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.shadow.withAlpha(100),
                        spreadRadius: 1.r,
                        blurRadius: 3.r,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标题和出勤率
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              KString.attendanceStatistics, // 签到统计
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                            ),
                            Text(
                              '${attendanceRate.round()}%',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        // 进度条
                        Container(
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: FractionallySizedBox(
                            widthFactor: attendanceRate / 100,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),

                        // 各状态统计
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: stats.entries.map((entry) {
                            return Row(
                              children: [
                                Container(
                                  width: 16.w,
                                  height: 16.h,
                                  decoration: BoxDecoration(
                                    color: entry.key.statusColor,
                                    borderRadius: BorderRadius.circular(2.r),
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  entry.key.statusText,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '${entry.value}',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
              ],
            );
          }
        },
      ),
    );
  }

  GestureDetector _buildAttendanceCallerInfoWidget() {
    return GestureDetector(
      onTap: () {
        // 点击显示/折叠点名器信息区域
        setState(() {
          _isAttendanceCallerInfoWidgetExpanded =
              !_isAttendanceCallerInfoWidgetExpanded;
        });
      },
      child: Container(
        margin: EdgeInsets.only(top: 12.h, bottom: 12.h),
        padding: EdgeInsets.only(
          left: 8.0.w,
          right: 8.0.w,
          top: 4.0.h,
          bottom: 4.0.h,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0.r),
          color: Theme.of(context).colorScheme.surfaceContainer,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withAlpha(100),
              blurRadius: 10.0.r,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 顶部标题和管理链接
                  Text(
                    KString.chooseACaller, // 选择点名器
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Icon(
                    _isAttendanceCallerInfoWidgetExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: Theme.of(context).textTheme.titleLarge?.fontSize,
                  ),
                ],
              ),
            ),

            // 点名器信息区域
            AnimatedCrossFade(
              firstChild: const SizedBox(height: 0, width: 0),
              secondChild: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildViewIconButton(),
                        _buildAddIconButton(),
                        _buildEditIconButton(),
                        _buildDeleteIconButton(),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    _buildDropdownButton(),
                  ],
                ),
              ),
              crossFadeState: _isAttendanceCallerInfoWidgetExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  IconButton _buildViewIconButton() {
    return IconButton(
      onPressed: () {
        // 查看点名器功能
        if (_selectedCallerId != null) {
          showDialog(
            context: context,
            builder: (context) => AttendanceCallerViewDialog(
              attendanceCaller: _allAttendaceCallersMap[_selectedCallerId!]!,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                KString.pleaseChooseACaller, // 请先选择点名器
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                ),
              ),
              backgroundColor: Theme.of(context).colorScheme.inverseSurface,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      icon: Icon(
        Icons.remove_red_eye,
        color: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  IconButton _buildEditIconButton() {
    return IconButton(
      onPressed: () {
        // 编辑点名器功能
        if (_selectedCallerId != null) {
          showDialog(
            context: context,
            builder: (context) => AttendanceCallerAddEditDialog(
              title: KString.editCaller, // 编辑点名器
              attendanceCaller: _allAttendaceCallersMap[_selectedCallerId!]!,
            ),
          ).then((value) {
            if (value != null && value == true) {
              // 刷新点名器列表
              _refreshPageData();
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                KString.pleaseChooseACaller, // 请先选择点名器
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                ),
              ),
              backgroundColor: Theme.of(context).colorScheme.inverseSurface,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.tertiary),
    );
  }

  IconButton _buildAddIconButton() {
    return IconButton(
      onPressed: () => {
        // 新增点名器功能
        showDialog(
          context: context,
          builder: (context) => AttendanceCallerAddEditDialog(
            title: KString.addCaller, // 新增点名器
            attendanceCaller: AttendanceCallerModel(),
          ),
        ).then((value) {
          if (value != null && value == true) {
            // 刷新随机点名器列表
            _refreshPageData();
          }
        }),
      },
      icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
    );
  }

  IconButton _buildDeleteIconButton() {
    return IconButton(
      onPressed: () async {
        // 删除点名器功能
        if (_selectedCallerId != null) {
          // 校验是否有关联的签到点名记录
          final attendanceCallRecords = await AttendanceCallRecordDao()
              .getAttendanceCallRecordsByCallerId(_selectedCallerId!);
          if (attendanceCallRecords.isNotEmpty) {
            // 有签到点名记录，提示用户先删除签到点名记录
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    KString.forbitDeleteAttendanceCallerInfo, // 该点名器下有签到点名记录，无法删除。请先删除该点名器下的所有签到点名记录。
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onInverseSurface,
                    ),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.inverseSurface,
                  duration: const Duration(seconds: 3),
                ),
              );
            }

            return;
          }
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(KString.confirmDeleteCallerTitle), // 确认删除
                  content: Text(KString.confirmDeleteCallerRecordContent), // 确定要删除选中的点名器吗？此操作不可撤销。
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(KString.cancel), // 取消
                    ),
                    TextButton(
                      onPressed: () async {
                        await AttendanceCallerDao()
                            .deleteAttendanceCaller(_selectedCallerId!)
                            .then((value) {
                              if (value > 0) {
                                _selectedCallerId = null;
                                if (context.mounted) {
                                  // 删除后的处理
                                  _refreshPageData();
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        KString.deleteSuccess, // 删除成功
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onInverseSurface,
                                        ),
                                      ),
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.inverseSurface,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        KString.deleteFail, // 删除失败
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onInverseSurface,
                                        ),
                                      ),
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.inverseSurface,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              }
                            });
                      },
                      child: Text(KString.delete), // 删除
                    ),
                  ],
                );
              },
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  KString.pleaseChooseACaller, // 请先选择点名器
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onInverseSurface,
                  ),
                ),
                backgroundColor: Theme.of(context).colorScheme.inverseSurface,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      },
      icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
    );
  }

  DropdownButtonFormField<int> _buildDropdownButton() {
    return DropdownButtonFormField<int>(
      initialValue: _selectedCallerId,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12.0.h,
          vertical: 10.0.w,
        ),
      ),
      items: _allAttendaceCallersMap.values.map((
        AttendanceCallerModel attendanceCaller,
      ) {
        return DropdownMenuItem<int>(
          value: attendanceCaller.id,
          child: Text(attendanceCaller.attendanceCallerName),
        );
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() {
            _selectedCallerId = newValue;
            _refreshPageData();
          });
        }
      },
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      dropdownColor: Theme.of(context).colorScheme.surface,
      icon: Icon(
        Icons.arrow_drop_down,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      iconSize: Theme.of(context).textTheme.bodyMedium?.fontSize ?? 24.0,
      iconEnabledColor: Theme.of(context).colorScheme.secondary,
    );
  }

  void _refreshPageData() {
    setState(() {
      _attendanceCallerFuture = _getAttendanceCallerPageInfo();
    });
  }
}
