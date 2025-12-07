import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../models/random_caller_model.dart';
import '../providers/random_caller_is_duplicate_provider.dart';
import '../providers/random_caller_provider.dart';
import '../providers/random_caller_selected_class_id_provider.dart';
import '../utils/random_caller_dao.dart';
import '../utils/student_class_dao.dart';

class RandomCallerAddEditDialog extends StatelessWidget {
  final RandomCallerModel randomCaller;
  final String title;
  late final bool isAdd;

  final TextEditingController randomCallerNameController;
  final TextEditingController notesController;
  final GlobalKey _formKey = GlobalKey<FormState>();

  RandomCallerAddEditDialog({
    super.key,
    required this.randomCaller,
    required this.title,
    required this.randomCallerNameController,
    required this.notesController,
  }) {
    isAdd = title == '添加点名器';
  }

  @override
  Widget build(BuildContext context) {
    randomCallerNameController.text = randomCaller.randomCallerName;
    notesController.text = randomCaller.notes;
    Provider.of<RandomCallerIsDuplicateProvider>(
      context,
      listen: false,
    ).updateIsDuplicateWithoutNotify(randomCaller.isDuplicate == 1);
    return AlertDialog(
      title: Text(title),
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            if (Provider.of<RandomCallerSelectedClassIdProvider>(
                  context,
                  listen: false,
                ).selectedClassId ==
                -1) {
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
      controller: randomCallerNameController,
      decoration: const InputDecoration(labelText: '点名器名称'),
      autovalidateMode: AutovalidateMode.onUnfocus,
      onChanged: (value) {
        WidgetsFlutterBinding.ensureInitialized(); // 确保初始化Flutter绑定。对于插件很重要。
        RandomCallerDao randomCallerDao = RandomCallerDao();
        randomCallerDao.isRollCallerNameExist(value).then((value) {
          if (value) {
            if (!isAdd &&
                randomCaller.randomCallerName !=
                    randomCallerNameController.text) {
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

  Consumer<RandomCallerSelectedClassIdProvider> _buildClassIdField() {
    return Consumer<RandomCallerSelectedClassIdProvider>(
      builder: (context, randomCallerSelectedClassProvider, child) {
        return FutureBuilder(
          future: _getClasses(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                if (snapshot.data!.isEmpty) {
                  randomCallerSelectedClassProvider
                      .selectedClassIdWithoutNotify(-1);
                  return const Text('暂无班级，无法添加点名器，请先添加班级');
                }
                if (randomCallerSelectedClassProvider.selectedClassId == -1) {
                  randomCallerSelectedClassProvider
                      .selectedClassIdWithoutNotify(snapshot.data![0]['id']!);
                }
                return RadioGroup<int>(
                  groupValue: randomCallerSelectedClassProvider.selectedClassId,
                  onChanged: isAdd
                      ? (value) {
                          randomCallerSelectedClassProvider.setSelectedClassId(
                            value!,
                          );
                        }
                      : (value) {
                          null;
                        },
                  child: Column(
                    children: snapshot.data!
                        .map(
                          (e) => RadioListTile<int>(
                            value: e['id']!,
                            title: Text(
                              e['class_name']!,
                              style: TextStyle(
                                color: isAdd ? Colors.black : Colors.grey,
                              ),
                            ),
                            fillColor: WidgetStateProperty.all(
                              isAdd ? Colors.black : Colors.grey,
                            ),
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

  void _saveRandomCaller(BuildContext context) {
    if ((_formKey.currentState as FormState).validate()) {
      randomCaller.randomCallerName = randomCallerNameController.text;
      randomCaller.classId = Provider.of<RandomCallerSelectedClassIdProvider>(
        context,
        listen: false,
      ).selectedClassId;
      randomCaller.isDuplicate =
          Provider.of<RandomCallerIsDuplicateProvider>(
            context,
            listen: false,
          ).isDuplicate
          ? 1
          : 0;
      randomCaller.notes = notesController.text;
      if (isAdd) {
        // 新增点名器
        randomCaller.created = DateTime.now();
        RandomCallerDao().insertRandomCaller(randomCaller).then((value) {
          if (context.mounted) {
            if (value != 0) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('添加成功')));
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('添加失败')));
            }
            randomCaller.id = value;
            Provider.of<RandomCallerProvider>(
              context,
              listen: false,
            ).addRandomCaller(randomCaller);
          }
        });
      } else {
        RandomCallerDao().updateRandomCaller(randomCaller).then((value) {
          if (context.mounted) {
            if (value != 0) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('更新成功')));
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('更新失败')));
            }
            Provider.of<RandomCallerProvider>(
              context,
              listen: false,
            ).updateRandomCaller(randomCaller);
          }
        });
      }
      Navigator.of(context).pop();
    }
  }

  Consumer<RandomCallerIsDuplicateProvider> _buildIsDuplicateField() {
    return Consumer<RandomCallerIsDuplicateProvider>(
      builder: (context, randomCallerIsDuplicateProvider, child) {
        return CheckboxListTile(
          title: const Text('是否允许重复点名'),
          value: randomCallerIsDuplicateProvider.isDuplicate,
          onChanged: isAdd
              ? (value) {
                  randomCallerIsDuplicateProvider.updateIsDuplicate(value!);
                }
              : null,
        );
      },
    );
  }
}
