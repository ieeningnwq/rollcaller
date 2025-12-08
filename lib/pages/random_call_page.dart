import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:rollcall/utils/random_caller_dao.dart';

import '../models/random_call_record.dart';
import '../models/random_caller_group.dart';
import '../models/random_caller_model.dart';
import '../models/student_class_model.dart';
import '../models/student_model.dart';
import '../providers/random_caller_provider.dart';
import '../utils/random_call_record_dao.dart';
import '../utils/student_class_dao.dart';
import '../utils/student_dao.dart';
import '../widgets/random_caller_add_edit_dialog.dart';
import '../widgets/random_caller_view_dialog.dart';

/// 随机点名器页面
class RandomCallPage extends StatefulWidget {
  const RandomCallPage({super.key});

  @override
  State<RandomCallPage> createState() => _RandomCallPageState();
}

class _RandomCallPageState extends State<RandomCallPage> {
  // 全部随机点名器
  late Map<int, RandomCallerModel> _allRandomCallersMap = {};
  // 当前选择随机点名器
  int? _selectedCallerId;
  // 新建/编辑时当前学生班级id
  // 添加dialog 是否重复点名状态

  // 全部班级
  Map<int, StudentClassModel> _allStudentClassesMap = {};

  RandomCallerGroupModel? _randomCallerGroup;

  @override
  initState() {
    super.initState();
    // 获取所有随机点名器数据
    RandomCallerDao().getAllRandomCallers().then((allRandomCallers) {
      setState(() {
        _allRandomCallersMap = {
          for (var randomCaller in allRandomCallers)
            randomCaller.id!: randomCaller,
        };
        _selectedCallerId = allRandomCallers.isNotEmpty
            ? allRandomCallers.first.id
            : null;
      });
    });
    // 获取所有班级数据
    StudentClassDao().getAllStudentClasses().then((allStudentClasses) {
      setState(() {
        _allStudentClassesMap = {
          for (var studentClass in allStudentClasses)
            studentClass['id']!: StudentClassModel.fromMap(studentClass),
        };
      });
    });
  }

  Future<RandomCallerGroupModel?> _getRandomCallerPageInfo() async {
    Map<int, List<RandomCallRecordModel>> randomCallRecords = {};

    return RandomCallerDao().getAllRandomCallers().then((
      allRandomCallers,
    ) async {
      _allRandomCallersMap = {
        for (var randomCaller in allRandomCallers)
          randomCaller.id!: randomCaller,
      };
      _selectedCallerId ??= allRandomCallers.isNotEmpty
          ? allRandomCallers.first.id
          : null;
      if (_selectedCallerId != null) {
        var selectedCaller = _allRandomCallersMap[_selectedCallerId!]!;
        return await StudentClassDao()
            .getStudentClass(selectedCaller.classId)
            .then((studentClass) async {
              return (StudentDao().getAllStudentsByClassName(
                studentClass!.className,
              )).then((students) {
                List<StudentModel> studentModels = students
                    .map((e) => StudentModel.fromMap(e))
                    .toList();
                for (var element in studentModels) {
                  RandomCallRecordDao()
                      .getRecordsByCallerIdStudentId(
                        selectedCaller.id!,
                        element.id!,
                      )
                      .then((records) {
                        randomCallRecords[element.id!] = records;
                      });
                }
                return RandomCallerGroupModel(
                  randomCallerModel: selectedCaller,
                  students: studentModels,
                  studentClassModel: studentClass!,
                  randomCallRecords: randomCallRecords,
                );
              });
            });
      } else {
        return null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getRandomCallerPageInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          _randomCallerGroup = snapshot.data;
          return Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildRandomCallerInfoWidget(),
                  // RandomCallerInfoWidget(),
                  // RandomCallerCallWidget(),
                  // StudentScoreWidget(),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Container _buildRandomCallerInfoWidget() {
    return Container(
      margin: const EdgeInsets.all(10.0),
      padding: const EdgeInsets.all(14.0),
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
          // 顶部标题和管理链接
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '选择点名器',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Spacer(),
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
    );
  }

  IconButton _buildViewIconButton() {
    return IconButton(
      onPressed: () {
        // 查看点名器功能
        if (_selectedCallerId != null) {
          showDialog(
            context: context,
            builder: (context) => RandomCallerViewDialog(
              randomCaller: _allRandomCallersMap[_selectedCallerId!]!,
              allStudentClassesMap: _allStudentClassesMap,
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
          builder: (context) => RandomCallerAddEditDialog(
            title: '新增点名器',
            randomCaller: RandomCallerModel(
              classId: -1,
              randomCallerName: '',
              isDuplicate: 0,
              isArchive: 0,
              notes: '',
              created: DateTime.now(),
            ),
          ),
        ).then((value) {
          if (value == true) {
            // 刷新随机点名器列表
            RandomCallerDao().getAllRandomCallers().then((allRandomCallers) {
              setState(() {
                _allRandomCallersMap = {
                  for (var randomCaller in allRandomCallers)
                    randomCaller.id!: randomCaller,
                };
                _selectedCallerId = allRandomCallers.isNotEmpty
                    ? allRandomCallers.first.id
                    : null;
              });
            });
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
      items: _allRandomCallersMap.values.map((RandomCallerModel randomCaller) {
        return DropdownMenuItem<int>(
          value: randomCaller.id,
          child: Text(randomCaller.randomCallerName),
        );
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() {
            _selectedCallerId = newValue;
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
}
