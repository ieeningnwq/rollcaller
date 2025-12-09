import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../configs/attendance_status.dart';
import '../models/attendance_call_record.dart';
import '../models/attendance_caller_group.dart';
import '../models/attendance_caller_model.dart';
import '../models/student_class_model.dart';
import '../models/student_model.dart';
import '../utils/attendance_call_record_dao.dart';
import '../utils/attendance_caller_dao.dart';
import '../utils/student_class_dao.dart';
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
        _filteredStudents = _students;
      } else {
        _filteredStudents = _students.where((student) {
          return student.studentName.contains(_searchController.text) ||
              student.studentNumber.contains(_searchController.text);
        }).toList();
      }
    });

    _attendanceCallerFuture = _getAttendanceCallerPageInfo();
  }

  Future<AttendanceCallerGroupModel?> _getAttendanceCallerPageInfo() async {
    try {
      Map<int, AttendanceCallRecordModel> attendanceCallRecords = {};
      // 获取全部签到点名器
      List<AttendanceCallerModel> allAttendanceCallers =
          await AttendanceCallerDao().getAllAttendanceCallers();
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
        List<StudentModel> students = await StudentDao()
            .getAllStudentsByClassName(studentClass.className);
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
      AttendanceStatus.present,
      AttendanceStatus.late,
      AttendanceStatus.excused,
      AttendanceStatus.absent,
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
  Widget build(BuildContext context) {
    return Expanded(
      child: FutureBuilder<AttendanceCallerGroupModel?>(
        future: _attendanceCallerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAttendanceCallerInfoWidget(),
                // 搜索框 - 固定在顶部
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(20),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: '搜索学生',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(8),
                    ),
                  ),
                ),
                SizedBox(height: 4),
                // 签到状态列表 - 扩展以填充剩余空间
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha(20),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 标题行 - 固定在顶部
                        Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '签到状态',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '共$totalCount人',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: Colors.grey.withAlpha(20)),

                        // 学生列表 - 可滚动
                        Expanded(
                          child: _filteredStudents.isNotEmpty
                              ? ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: _filteredStudents.length,
                                  itemBuilder: (context, index) {
                                    final StudentModel student =
                                        _filteredStudents[index];
                                    return Column(
                                      children: [
                                        ListTile(
                                          onTap: () =>
                                              _toggleAttendanceStatus(index),
                                          title: Text(
                                            student.studentName,
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          subtitle: Text(
                                            '学号: ${student.studentNumber}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          trailing: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _attendanceCallerGroup!
                                                  .attendanceCallRecords[student
                                                      .id!]!
                                                  .present
                                                  .statusColor,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _attendanceCallerGroup!
                                                  .attendanceCallRecords[student
                                                      .id!]!
                                                  .present
                                                  .statusText,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (index <
                                            _filteredStudents.length - 1)
                                          Divider(
                                            height: 1,
                                            color: Colors.grey.withAlpha(20),
                                          ),
                                      ],
                                    );
                                  },
                                )
                              : Center(
                                  child: Text(
                                    '暂无学生',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // 签到统计 - 固定在底部
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(20),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标题和出勤率
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '签到统计',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${attendanceRate.round()}%',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF6200EE),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),

                        // 进度条
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            widthFactor: attendanceRate / 100,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF6200EE),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12),

                        // 各状态统计
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: stats.entries.map((entry) {
                            return Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: entry.key.statusColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  entry.key.statusText,
                                  style: TextStyle(fontSize: 12),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${entry.value}',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 8),
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
        margin: const EdgeInsets.all(4.0),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 顶部标题和管理链接
                  const Text(
                    '选择点名器',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Icon(
                    _isAttendanceCallerInfoWidgetExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 20,
                  ),
                ],
              ),
            ),

            // 点名器信息区域
            AnimatedCrossFade(
              firstChild: const SizedBox(height: 0, width: 0),
              secondChild: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildArchiveIconButton(),
                        _buildViewIconButton(),
                        _buildAddIconButton(),
                        _buildEditIconButton(),
                        _buildDeleteIconButton(),
                      ],
                    ),
                    const SizedBox(height: 8),
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

  IconButton _buildArchiveIconButton() {
    return IconButton(
      onPressed: () {
        // 点名器归档功能
        if (_selectedCallerId != null) {
          // showDialog(
          //   context: context,
          //   builder: (context) => RandomCallerViewDialog(
          //     randomCaller: _allAttendaceCallersMap[_selectedCallerId!]!,
          //   ),
          // );
        } else {
          Fluttertoast.showToast(msg: '请先选择点名器');
        }
      },
      icon: const Icon(Icons.archive, color: Colors.grey),
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
          Fluttertoast.showToast(msg: '请先选择点名器');
        }
      },
      icon: const Icon(Icons.remove_red_eye, color: Colors.grey),
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
              title: '编辑点名器',
              attendanceCaller: _allAttendaceCallersMap[_selectedCallerId!]!,
            ),
          ).then((value) {
            if (value != null && value == true) {
              // 刷新点名器列表
              _refreshPageData();
            }
          });
        } else {
          Fluttertoast.showToast(msg: '请先选择点名器');
        }
      },
      icon: const Icon(Icons.edit, color: Colors.blue),
    );
  }

  IconButton _buildAddIconButton() {
    return IconButton(
      onPressed: () => {
        // 新增点名器功能
        showDialog(
          context: context,
          builder: (context) => AttendanceCallerAddEditDialog(
            title: '新增点名器',
            attendanceCaller: AttendanceCallerModel(),
          ),
        ).then((value) {
          if (value != null && value == true) {
            // 刷新随机点名器列表
            _refreshPageData();
          }
        }),
      },
      icon: Icon(Icons.add, color: Colors.green),
    );
  }

  IconButton _buildDeleteIconButton() {
    return IconButton(
      onPressed: () {
        // 删除点名器功能
        if (_selectedCallerId != null) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('确认删除'),
                content: const Text('确定要删除选中的点名器吗？此操作不可撤销。'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
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
                                  const SnackBar(content: Text('删除成功')),
                                );
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('删除失败')),
                                );
                              }
                            }
                          });
                    },
                    child: const Text('删除'),
                  ),
                ],
              );
            },
          );
        } else {
          Fluttertoast.showToast(msg: '请先选择点名器');
        }
      },
      icon: const Icon(Icons.delete, color: Colors.red),
    );
  }

  DropdownButtonFormField<int> _buildDropdownButton() {
    return DropdownButtonFormField<int>(
      initialValue: _selectedCallerId,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 10.0,
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
      style: const TextStyle(fontSize: 16.0, color: Colors.black),
      dropdownColor: Colors.white,
      icon: const Icon(Icons.arrow_drop_down),
      iconSize: 24.0,
      iconEnabledColor: Colors.grey,
    );
  }

  void _refreshPageData() {
    setState(() {
      _attendanceCallerFuture = _getAttendanceCallerPageInfo();
    });
  }
}
