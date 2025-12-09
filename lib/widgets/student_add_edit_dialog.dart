import 'package:flutter/material.dart';

import '../models/student_class_model.dart';
import '../models/student_model.dart';
import '../utils/student_class_dao.dart';
import '../utils/student_dao.dart';

class StudentAddEditDialog extends StatefulWidget {
  final StudentModel student;
  final String title;

  const StudentAddEditDialog({
    super.key,
    required this.student,
    required this.title,
  });

  @override
  State<StatefulWidget> createState() {
    return _StudentAddEditDialogState();
  }
}

class _StudentAddEditDialogState extends State<StudentAddEditDialog> {
  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _studentNumberController =
      TextEditingController();
  final GlobalKey _formKey = GlobalKey<FormState>();

  Future<Map<String, StudentClassModel>>? _allStudentClassesMapFuture;

  // 选中的班级{id:bool}
  Map<String, bool>? _selectedClasses;
  // 所有班级消息
  late Map<String, StudentClassModel> _allStudentClassesMap;

  bool isAdd = false;
  @override
  void initState() {
    super.initState();
    _allStudentClassesMapFuture = _getAllStudentClassesMap();
    isAdd = widget.title == '添加学生';
    _studentNameController.text = widget.student.studentName;
    _studentNumberController.text = widget.student.studentNumber;
  }

  Future<Map<String, StudentClassModel>> _getAllStudentClassesMap() async {
    Map<String, StudentClassModel> allStudentClassesMap = {};
    StudentClassDao studentClassDao = StudentClassDao();
    return await studentClassDao.getAllStudentClasses().then((value) {
      for (var element in value) {
        allStudentClassesMap[element.className] = element;
      }
      return allStudentClassesMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, StudentClassModel>>(
      future: _allStudentClassesMapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            _allStudentClassesMap = snapshot.data!;
            if (_selectedClasses == null) {
              _selectedClasses = {};
              for (var element in _allStudentClassesMap.keys) {
                _selectedClasses![element] = false;
              }
              if (widget.student.className.isNotEmpty) {
                for (String element in widget.student.className.split(',')) {
                  _selectedClasses![element] = true;
                }
              }
            }
            return AlertDialog(
              title: Text(widget.title),
              content: Form(
                key: _formKey,
                child: SizedBox(
                  width: double.maxFinite,
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // 学生学号
                              _buildStudentNumberField(),
                              // 学生姓名
                              _buildStudengNameField(),
                              const SizedBox(height: 4),
                              // 班级选择
                              const Text(
                                '所在班级',
                                style: TextStyle(fontSize: 16),
                              ),
                              _buildClassSelectField(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('取消'),
                ),
                TextButton(
                  onPressed: () => _saveOnPressed(context),
                  child: Text('保存'),
                ),
              ],
            );
          }
        }
        return const CircularProgressIndicator();
      },
    );
  }

  TextFormField _buildStudentNumberField() {
    bool isStudentNumberUnique = true;
    return TextFormField(
      decoration: InputDecoration(labelText: '学生学号', hintText: '请输入学生学号（必填）'),
      controller: _studentNumberController,
      autovalidateMode: AutovalidateMode.onUnfocus,
      onChanged: (value) {
        WidgetsFlutterBinding.ensureInitialized(); // 确保初始化Flutter绑定。对于插件很重要。
        var studentDao = StudentDao(); // 创建StudentstudentDao实例。
        studentDao
            .isStudentNumberExist(value)
            .then(
              (onValue) => {
                if (onValue)
                  {
                    if (!isAdd &&
                        (_studentNumberController.text ==
                            widget.student.studentNumber))
                      isStudentNumberUnique = true
                    else
                      isStudentNumberUnique = false,
                  }
                else
                  isStudentNumberUnique = true,
              },
            );
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '学号不能为空';
        }
        if (!isStudentNumberUnique) {
          return '$value重复使用';
        }
        return null; // 如果没有找到重复值，返回null表示验证通过
      },
    );
  }

  TextFormField _buildStudengNameField() {
    return TextFormField(
      decoration: InputDecoration(labelText: '学生姓名', hintText: '请输入学生姓名（必填）'),
      controller: _studentNameController,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '姓名不能为空';
        }
        return null;
      },
    );
  }

  Column _buildClassSelectField() {
    return Column(
      children: List.generate(_allStudentClassesMap.length, (index) {
        return CheckboxListTile(
          value: _selectedClasses![_allStudentClassesMap.keys.toList()[index]],
          title: Text(
            _allStudentClassesMap[_allStudentClassesMap.keys.toList()[index]]!
                .className,
          ),
          onChanged: (value) {
            setState(() {
              _selectedClasses![_allStudentClassesMap.keys.toList()[index]] =
                  value!;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
        );
      }),
    );
  }

  void _saveOnPressed(BuildContext context) async {
    if ((_formKey.currentState as FormState).validate()) {
      WidgetsFlutterBinding.ensureInitialized(); // 确保初始化Flutter绑定。对于插件很重要。
      var studentDao = StudentDao(); // 创建StudentstudentDao实例。
      // 更新学生信息
      widget.student.studentNumber = _studentNumberController.text;
      widget.student.studentName = _studentNameController.text;
      List<String> classNames = [];
      _selectedClasses!.forEach((key, value) {
        if (value) {
          classNames.add(key);
        }
      });
      widget.student.className = classNames.join(',');
      // 判断是新增还是修改
      if (isAdd) {
        // 新增学生
        widget.student.created = DateTime.now();
        studentDao
            .insertStudent(widget.student)
            .then(
              (id) => {
                if (id != 0)
                  {
                    // 添加学生列表，刷新数据
                    if (context.mounted)
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('新增成功'))),
                  }
                else
                  {
                    if (context.mounted)
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('新增失败'))),
                  },
              },
            );
      } else {
        // 修改学生
        studentDao
            .updateStudentClassById(widget.student)
            .then(
              (value) => {
                if (value != 0)
                  {
                    if (context.mounted)
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('修改成功'))),
                  }
                else
                  {
                    if (context.mounted)
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('修改失败'))),
                  },
              },
            );
      }
      if (context.mounted) {
        Navigator.of(context).pop(true); // 关闭弹窗
      }
    }
  }
}
