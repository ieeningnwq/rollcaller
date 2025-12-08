import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rollcall/utils/student_class_dao.dart';

import '../models/random_caller_model.dart';
import '../models/student_class_model.dart';
import '../utils/random_caller_dao.dart';

class RandomCallerAddEditDialog extends StatefulWidget {
  final RandomCallerModel randomCaller;
  final String title;

  const RandomCallerAddEditDialog({
    super.key,
    required this.randomCaller,
    required this.title,
  });

  @override
  State<StatefulWidget> createState() {
    return _RandomCallerAddEditDialogState();
  }
}

class _RandomCallerAddEditDialogState extends State<RandomCallerAddEditDialog> {
  final TextEditingController _randomCallerNameController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final GlobalKey _formKey = GlobalKey<FormState>();
  int _selectedStudentClassId = -1;
  bool _isAdd = false;
  bool _isDuplicate = false;
  Map<int, StudentClassModel>? _allStudentClassesMap = {};

  @override
  initState() {
    super.initState();
    _selectedStudentClassId = widget.randomCaller.classId;
    _isDuplicate = widget.randomCaller.isDuplicate == 1;
    _isAdd = widget.title == '新增点名器';
    _randomCallerNameController.text = widget.randomCaller.randomCallerName;
    _notesController.text = widget.randomCaller.notes;
  }

  @override
  dispose() {
    _randomCallerNameController.dispose();
    _notesController.dispose();
    super.dispose();
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
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _buildRollCallerNameField(),
                    _buildNotesField('备注（选填）'),
                    _buildIsDuplicateField(),
                    _buildClassIdField(),
                  ],
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
                      Fluttertoast.showToast(
                        msg: '暂无班级，无法添加点名器，请先添加班级',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.grey,
                        textColor: Colors.white,
                        fontSize: 16.0,
                      );
                      return;
                    }
                    _saveRandomCaller(context);
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

  TextFormField _buildRollCallerNameField() {
    bool isRollCallerNameUnique = true;

    return TextFormField(
      controller: _randomCallerNameController,
      decoration: const InputDecoration(labelText: '点名器名称'),
      autovalidateMode: AutovalidateMode.onUnfocus,
      onChanged: (value) {
        WidgetsFlutterBinding.ensureInitialized(); // 确保初始化Flutter绑定。对于插件很重要。
        RandomCallerDao randomCallerDao = RandomCallerDao();
        randomCallerDao.isRollCallerNameExist(value).then((v) {
          if (v) {
            if (!_isAdd &&
                widget.randomCaller.randomCallerName ==
                    _randomCallerNameController.text) {
              isRollCallerNameUnique = true;
            } else {
              isRollCallerNameUnique = false;
            }
          } else {
            isRollCallerNameUnique = true;
          }
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '点名器名称不能为空';
        }
        if (!isRollCallerNameUnique) {
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
                  style: TextStyle(color: _isAdd ? Colors.black : Colors.grey),
                ),
                fillColor: WidgetStateProperty.all(
                  _isAdd ? Colors.black : Colors.grey,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  void _saveRandomCaller(BuildContext context) {
    if ((_formKey.currentState as FormState).validate()) {
      widget.randomCaller.randomCallerName = _randomCallerNameController.text;
      widget.randomCaller.classId = _selectedStudentClassId;
      widget.randomCaller.isDuplicate = _isDuplicate ? 1 : 0;
      widget.randomCaller.notes = _notesController.text;
      if (_isAdd) {
        // 新增点名器
        widget.randomCaller.created = DateTime.now();
        RandomCallerDao().insertRandomCaller(widget.randomCaller).then((value) {
          if (context.mounted) {
            if (value != 0) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('添加成功')));
              Navigator.of(context).pop(true);
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('添加失败')));
              Navigator.of(context).pop(false);
            }
          }
        });
      } else {
        RandomCallerDao().updateRandomCaller(widget.randomCaller).then((value) {
          if (context.mounted) {
            if (value != 0) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('更新成功')));
              Navigator.of(context).pop(true);
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('更新失败')));
              Navigator.of(context).pop(false);
            }
          }
        });
      }
    }
  }

  CheckboxListTile _buildIsDuplicateField() {
    return CheckboxListTile(
      title: const Text('是否允许重复点名'),
      value: _isDuplicate,
      onChanged: _isAdd
          ? (value) {
              setState(() {
                _isDuplicate = value!;
              });
            }
          : null,
    );
  }
}
