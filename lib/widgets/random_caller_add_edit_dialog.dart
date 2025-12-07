import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../models/random_caller_model.dart';
import '../models/student_class_model.dart';
import '../utils/random_caller_dao.dart';

class RandomCallerAddEditDialog extends StatefulWidget {
  final RandomCallerModel randomCaller;
  final String title;
  final Map<int, StudentClassModel> allStudentClassesMap;

  const RandomCallerAddEditDialog({
    super.key,
    required this.randomCaller,
    required this.title,
    required this.allStudentClassesMap,
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

  @override
  initState() {
    super.initState();
    _selectedStudentClassId = widget.randomCaller.classId;
    if (_selectedStudentClassId == -1) {
      _selectedStudentClassId = widget.allStudentClassesMap.isNotEmpty
          ? widget.allStudentClassesMap.keys.first
          : -1;
    }
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

  @override
  Widget build(BuildContext context) {
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
            if (widget.allStudentClassesMap.isEmpty) {
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

  TextFormField _buildRollCallerNameField() {
    bool isRollCallerNameUnique = true;

    return TextFormField(
      controller: _randomCallerNameController,
      decoration: const InputDecoration(labelText: '点名器名称'),
      autovalidateMode: AutovalidateMode.onUnfocus,
      onChanged: (value) {
        WidgetsFlutterBinding.ensureInitialized(); // 确保初始化Flutter绑定。对于插件很重要。
        RandomCallerDao randomCallerDao = RandomCallerDao();
        randomCallerDao.isRollCallerNameExist(value).then((value) {
          if (value) {
            if (!_isAdd &&
                widget.randomCaller.randomCallerName !=
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
    if (widget.allStudentClassesMap.isEmpty) {
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
        children: widget.allStudentClassesMap.values
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
