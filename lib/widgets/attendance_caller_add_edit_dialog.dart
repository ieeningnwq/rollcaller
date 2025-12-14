import 'package:flutter/material.dart';

import '../models/attendance_caller_model.dart';
import '../models/student_class_model.dart';
import '../utils/attendance_caller_dao.dart';
import '../utils/student_class_dao.dart';

class AttendanceCallerAddEditDialog extends StatefulWidget {
  final AttendanceCallerModel attendanceCaller;
  final String title;

  const AttendanceCallerAddEditDialog({
    super.key,
    required this.attendanceCaller,
    required this.title,
  });

  @override
  State<StatefulWidget> createState() {
    return _AttendanceCallerAddEditDialogState();
  }
}

class _AttendanceCallerAddEditDialogState
    extends State<AttendanceCallerAddEditDialog> {
  final TextEditingController _attendanceCallerNameController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final GlobalKey _formKey = GlobalKey<FormState>();
  int _selectedStudentClassId = -1;
  bool _isAdd = false;
  Map<int, StudentClassModel>? _allStudentClassesMap = {};

  @override
  initState() {
    super.initState();
    _selectedStudentClassId = widget.attendanceCaller.classId;
    _isAdd = widget.title == '新增点名器';
    _attendanceCallerNameController.text =
        widget.attendanceCaller.attendanceCallerName;
    _notesController.text = widget.attendanceCaller.notes;
  }

  @override
  dispose() {
    super.dispose();
    _attendanceCallerNameController.dispose();
    _notesController.dispose();
  }

  Future<Map<int, StudentClassModel>> _getAllStudentClassesMap() async {
    Map<int, StudentClassModel> allStudentClassesMap = {};
    StudentClassDao studentClassDao = StudentClassDao();
    return await studentClassDao.getAllStudentClasses().then((value) {
      for (var element in value) {
        allStudentClassesMap[element.id!] = element;
      }
      return allStudentClassesMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<int, StudentClassModel>>(
      future: _getAllStudentClassesMap(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            _allStudentClassesMap = snapshot.data;
            if (_selectedStudentClassId == -1 &&
                _allStudentClassesMap!.isNotEmpty) {
              _selectedStudentClassId = _allStudentClassesMap!.keys.first;
            }
            return AlertDialog(
              title: Text(widget.title),
              content: Form(
                key: _formKey,
                child: SizedBox(
                  width: double.maxFinite,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      _buildAttendanceCallerNameField(),
                      _buildNotesField('备注（选填）'),
                      _buildClassIdField(),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    if (_allStudentClassesMap!.isEmpty) {
                      // 显示SnackBar
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '暂无班级，无法添加点名器，请先添加班级',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onInverseSurface,
                              ),
                            ),
                            backgroundColor: Theme.of(context).colorScheme.inverseSurface,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                      Navigator.of(context).pop(false);
                      return;
                    }
                    _saveAttendanceCaller(context);
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          }
        }
        return const CircularProgressIndicator();
      },
    );
  }

  TextFormField _buildAttendanceCallerNameField() {
    bool isAttendanceCallerNameUnique = true;

    return TextFormField(
      controller: _attendanceCallerNameController,
      decoration: const InputDecoration(labelText: '点名器名称'),
      autovalidateMode: AutovalidateMode.onUnfocus,
      onChanged: (value) {
        WidgetsFlutterBinding.ensureInitialized(); // 确保初始化Flutter绑定。对于插件很重要。
        AttendanceCallerDao attendanceCallerDao = AttendanceCallerDao();
        attendanceCallerDao.isAttendanceCallerNameExist(value).then((v) {
          if (v) {
            if (!_isAdd &&
                widget.attendanceCaller.attendanceCallerName ==
                    _attendanceCallerNameController.text) {
              isAttendanceCallerNameUnique = true;
            } else {
              isAttendanceCallerNameUnique = false;
            }
          } else {
            isAttendanceCallerNameUnique = true;
          }
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '点名器名称不能为空';
        }
        if (!isAttendanceCallerNameUnique) {
          return '$value重复使用';
        }
        return null;
      },
    );
  }

  TextField _buildNotesField(String label) {
    return TextField(
      decoration: InputDecoration(labelText: label),
      controller: _notesController,
    );
  }

  Widget _buildClassIdField() {
    if (_allStudentClassesMap!.isEmpty) {
      return const Text('暂无班级，无法添加点名器，请先添加班级');
    }

    return RadioGroup<int>(
      groupValue: _selectedStudentClassId,
      onChanged: _isAdd
          ? (value) {
              setState(() {
                _selectedStudentClassId = value!;
              });
            }
          : (value) {
              null;
            },
      child: Column(
        children: _allStudentClassesMap!.values
            .map(
              (e) => RadioListTile<int>(
                value: e.id!,
                title: Text(
                  e.className,
                ),
                fillColor: WidgetStateProperty.all(
                  _isAdd ? Theme.of(context).colorScheme.onSurface : Theme.of(context).disabledColor,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  void _saveAttendanceCaller(BuildContext context) {
    if ((_formKey.currentState as FormState).validate()) {
      widget.attendanceCaller.attendanceCallerName =
          _attendanceCallerNameController.text;
      widget.attendanceCaller.classId = _selectedStudentClassId;
      widget.attendanceCaller.notes = _notesController.text;
      if (_isAdd) {
        // 新增点名器
        widget.attendanceCaller.created = DateTime.now();
        AttendanceCallerDao()
            .insertAttendanceCaller(widget.attendanceCaller)
            .then((value) {
              if (context.mounted) {
                if (value != 0) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        '添加成功',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onInverseSurface,
                        ),
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.inverseSurface,
                    ),
                  );
                  Navigator.of(context).pop(true);
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        '添加失败',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onInverseSurface,
                        ),
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.inverseSurface,
                    ),
                  );
                  Navigator.of(context).pop(false);
                }
              }
            });
      } else {
        AttendanceCallerDao()
            .updateAttendanceCaller(widget.attendanceCaller)
            .then((value) {
              if (context.mounted) {
                if (value != 0) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        '更新成功',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onInverseSurface,
                        ),
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.inverseSurface,
                    ),
                  );
                  Navigator.of(context).pop(true);
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        '更新失败',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onInverseSurface,
                        ),
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.inverseSurface,
                    ),
                  );
                  Navigator.of(context).pop(false);
                }
              }
            });
      }
    }
  }
}
