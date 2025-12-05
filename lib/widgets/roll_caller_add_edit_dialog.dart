import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/roll_caller_model.dart';
import '../providers/roll_caller_selected_class_id_provider.dart';
import '../utils/roll_caller_dao.dart';
import '../utils/student_class_dao.dart';

class RollCallerAddEditDialog extends StatelessWidget {
  final RollCallerModel rollCaller;
  final String title;
  late final bool isAdd;

  final TextEditingController randomCallerNameController;
  final TextEditingController notesController;
  final GlobalKey _formKey = GlobalKey<FormState>();

  RollCallerAddEditDialog({
    super.key,
    required this.rollCaller,
    required this.title,
    required this.randomCallerNameController,
    required this.notesController,
  }) {
    isAdd = title == '添加点名器';
  }

  @override
  Widget build(BuildContext context) {
    randomCallerNameController.text = rollCaller.randomCallerName;
    notesController.text = rollCaller.notes;
    return AlertDialog(
      title: Text(title),
      content: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            _buildRollCallerNameField(),
            _buildNotesField('备注（选填）'),
            _buildClassIdField(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            _saveRollCaller(context);
            }
        ,
          child: const Text('保存'),
        ),
      ],
    );
  }

  TextFormField _buildRollCallerNameField() {
    bool isRollCallerNameUnique = true;

    return TextFormField(
      controller: randomCallerNameController,
      decoration: const InputDecoration(labelText: '点名器名称'),
      autovalidateMode: AutovalidateMode.onUnfocus,
      onChanged: (value) {
        WidgetsFlutterBinding.ensureInitialized(); // 确保初始化Flutter绑定。对于插件很重要。
        RollCallerDao rollCallerDao = RollCallerDao();
        rollCallerDao.isRollCallerNameExist(value).then((value) {
          if (value) {
            if (!isAdd &&
                rollCaller.randomCallerName != randomCallerNameController.text) {
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
      controller: notesController,
    );
  }

  Future<List<Map<String, dynamic>>> _getClasses() async {
    StudentClassDao studentClassDao = StudentClassDao();
    return await studentClassDao.getAllStudentClasses();
  }
  
  Consumer<RollCallerSelectedClassIdProvider> _buildClassIdField() {
    return Consumer<RollCallerSelectedClassIdProvider>(
              builder: (context, rollCallerSelectedClassProvider, child) {
                return FutureBuilder(
              future: _getClasses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    if (snapshot.data!.isEmpty) {
                      return const Text('暂无班级，无法添加点名器，请先添加班级');
                    }
                    if (rollCallerSelectedClassProvider.selectedClassId == -1) {
                      rollCallerSelectedClassProvider.selectedClassIdWithoutNotify(snapshot.data![0]['id']!);
                    }
                    return RadioGroup<int>(
                      groupValue: rollCallerSelectedClassProvider.selectedClassId,
                      onChanged: (value) {
                        rollCallerSelectedClassProvider.updateSelectedClassId(value!);
                      },
                      child: Column(
                        children: snapshot.data!
                            .map(
                              (e) => RadioListTile<int>(
                                value: e['id']!,
                                title: Text(e['class_name']!),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  }
                } else {
                  return CircularProgressIndicator();
                }
              },
            );
          },
            );
  }
  
  void _saveRollCaller(BuildContext context) {
    if ((_formKey.currentState as FormState).validate()) {
      rollCaller.randomCallerName = randomCallerNameController.text;
      rollCaller.classId = Provider.of<RollCallerSelectedClassIdProvider>(context, listen: false).selectedClassId!;
      rollCaller.notes = notesController.text;
      if (isAdd) {
        rollCaller.created = DateTime.now();
        var rollCallerDao=RollCallerDao();
        rollCallerDao.insertRollCaller(rollCaller).then((value) {
          if (value != 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('添加成功')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('添加失败')),
            );
          }
        });
      } else {
        // RollCallerDao rollCallerDao = RollCallerDao();
        // rollCallerDao.updateRollCaller(rollCaller);
      }
      Navigator.of(context).pop();
    }
  }
}
