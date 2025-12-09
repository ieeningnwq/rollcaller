import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
  late Map<int, AttendanceCallerModel> _allAttendaceCallersMap;
  // 签到点名器、班级、学生、点名记录信息
  AttendanceCallerGroupModel? _attendanceCallerGroup;
  // 获取当前点名器所有信息Future
  Future<AttendanceCallerGroupModel?>? _attendanceCallerFuture;

  @override
  initState() {
    super.initState();
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

        // 获取签到记录
        List<AttendanceCallRecordModel> records =
            await AttendanceCallRecordDao().getRecordsByCallerId(
              callerId: selectedCaller.id,
            );

        // 构建签到记录映射
        for (AttendanceCallRecordModel record in records) {
          attendanceCallRecords[record.studentId] = record;
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AttendanceCallerGroupModel?>(
      future: _attendanceCallerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          _attendanceCallerGroup = snapshot.data;
          return Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(4.0),
              child: Column(children: [_buildAttendanceCallerInfoWidget()]),
            ),
          );
        }
      },
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
