import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rollcall/utils/random_caller_dao.dart';

import '../models/random_call_record.dart';
import '../models/random_caller_group.dart';
import '../models/random_caller_model.dart';
import '../models/student_model.dart';
import '../utils/random_call_record_dao.dart';
import '../utils/student_class_dao.dart';
import '../utils/student_class_relation_dao.dart';
import '../utils/student_dao.dart';
import '../widgets/random_caller_add_edit_dialog.dart';
import '../widgets/random_caller_view_dialog.dart';

/// 随机点名器页面
class RandomCallPage extends StatefulWidget {
  const RandomCallPage({super.key});

  @override
  State<RandomCallPage> createState() => _RandomCallPageState();
}

class _RandomCallPageState extends State<RandomCallPage>
    with SingleTickerProviderStateMixin {
  // 全部随机点名器
  late Map<int, RandomCallerModel> _allRandomCallersMap = {};
  // 当前选择随机点名器
  int? _selectedCallerId;
  // 选择点名器、班级、学生、点名记录信息
  RandomCallerGroupModel? _randomCallerGroup;
  // 随机点名器选择组件初始选择第一个学生
  StudentModel? _currentStudent;
  // 随机点名器抽取动画控制器
  late AnimationController _controller;
  late Animation<double> _animation;
  // 随机点名器是否正在抽取
  bool _isPicking = false;
  // 随机点名器随机数生成器
  final Random _random = Random();
  // 滚动控制器，用于点击学生后滚动到抽取区域
  final ScrollController _scrollController = ScrollController();
  // 存储Future对象，避免每次build都创建新的Future
  Future<RandomCallerGroupModel?>? _randomCallerFuture;
  // 评分组件分数
  int _score = 5;
  // 学生组折叠状态
  bool _isPickedGroupExpanded = true; // 已抽取学生组默认展开
  bool _isUnpickedGroupExpanded = true; // 未抽取学生组默认展开
  // 选择点名器折叠
  bool _isRandomCallerInfoWidgetExpanded = true;
  // !  可选择学生，为满足不可重复点名需求
  late Map<int, StudentModel> _ableToSelectStudents;

  @override
  initState() {
    super.initState();
    // 初始化动画控制器 - 速度更快
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    // 初始化动画
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // 动画完成后，检查是否还在抽取中
          if (_isPicking) {
            // 如果还在抽取中，立即开始下一次动画
            _controller.reset();
            _controller.forward();

            // 随机选择一个新的学生
            setState(() {
              int studentId = _ableToSelectStudents.keys
                  .toList()[_random.nextInt(_ableToSelectStudents.length)];
              _currentStudent = _ableToSelectStudents[studentId];
            });
          }
        }
      });

    // 初始化时创建Future对象
    _randomCallerFuture = _getRandomCallerPageInfo();
  }

  Future<RandomCallerGroupModel?> _getRandomCallerPageInfo() async {
    Map<int, List<RandomCallRecordModel>> randomCallRecords = {};

    var allRandomCallers = await RandomCallerDao()
        .getAllIsNotArchiveRandomCallers();
    // 保存全部随机点名器
    _allRandomCallersMap = {
      for (var randomCaller in allRandomCallers) randomCaller.id!: randomCaller,
    };
    // 初始选择第一个随机点名器
    _selectedCallerId ??= allRandomCallers.isNotEmpty
        ? allRandomCallers.first.id
        : null;
    if (_selectedCallerId != null) {
      var selectedCaller = _allRandomCallersMap[_selectedCallerId!]!;
      var studentClass = await StudentClassDao().getStudentClass(
        selectedCaller.classId,
      );
      List<StudentModel> students = [];
      List<int> studentIds = await StudentClassRelationDao()
          .getAllStudentIdsByClassId(studentClass.id!);
      for (int studentId in studentIds) {
        var student = await StudentDao().getStudentById(studentId);
        if (student != null) {
          students.add(student);
        }
      }
      List<StudentModel> studentModels = students;

      for (var student in studentModels) {
        randomCallRecords[student.id!] = [];
      }
      for (var student in studentModels) {
        randomCallRecords[student.id!] = [];
      }
      var records = await RandomCallRecordDao().getRecordsByCallerId(
        callerId: selectedCaller.id!,
      );
      for (var record in records) {
        randomCallRecords[record.studentId]!.add(record);
      }
      // 初始化可选择学生
      if (selectedCaller.isDuplicate == 0) {
        // 不可重复
        _ableToSelectStudents = {
          for (var student in studentModels)
            if (randomCallRecords[student.id!]!.isEmpty) student.id!: student,
        };
      } else {
        // 可重复
        _ableToSelectStudents = {
          for (var student in studentModels) student.id!: student,
        };
      }
      // 初始选择第一个学生
      _currentStudent = _ableToSelectStudents.isNotEmpty
          ? _ableToSelectStudents.values.first
          : null;
      return RandomCallerGroupModel(
        randomCallerModel: selectedCaller,
        students: {for (var student in studentModels) student.id!: student},
        studentClassModel: studentClass,
        randomCallRecords: randomCallRecords,
      );
    }else{
      _selectedCallerId = null;
      return null;
    }
  }

  Future<void> _refreshPageData() async {
    setState(() {
      // 更新Future对象，触发FutureBuilder重新构建
      _randomCallerFuture = _getRandomCallerPageInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _randomCallerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          _randomCallerGroup = snapshot.data;
          return Expanded(
            child: SingleChildScrollView(
              controller: _scrollController, // 添加滚动控制器
              padding: const EdgeInsets.all(4.0),
              child: Column(
                children: [
                  _buildRandomCallerInfoWidget(),
                  _buildCallerCallWidget(),
                  _buildStudentScoreWidget(),
                  _buildStudentCardsWidget(),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Column _buildCallerCallWidget() {
    return Column(
      children: [
        // 学生抽取卡片
        Card(
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              children: [
                // 学生姓名显示
                Text(
                  _currentStudent?.studentName ?? '没有学生',
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 4.0),

                // 学号显示
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: 0.7 + (_animation.value * 0.3), // 添加透明度动画
                      child: child,
                    );
                  },
                  child: Text(
                    _currentStudent == null
                        ? '没有学生'
                        : _currentStudent?.studentNumber ?? '没有学号',
                    style: const TextStyle(
                      fontSize: 18.0,
                      color: Colors.black54,
                    ),
                  ),
                ),

                const SizedBox(height: 8.0),

                // 开始随机抽取按钮
                SizedBox(
                  width: double.infinity,
                  height: 40.0,
                  child: ElevatedButton(
                    onPressed: _currentStudent != null
                        ? _toggleRandomPick
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C4AB6), // 紫色背景
                      foregroundColor: Colors.white, // 白色文字
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                      elevation: 4.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shuffle, size: 20.0),
                        const SizedBox(width: 8.0),
                        Text(_isPicking ? '停止抽取' : '开始随机抽取'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 开始/停止随机抽取
  void _toggleRandomPick() {
    setState(() {
      if (_isPicking) {
        // 停止抽取
        _isPicking = false;
        _controller.stop();
        _controller.reset();

        // 抽取停止后，重置分数为默认值5分
        _score = 5;
      } else {
        // 开始抽取
        _isPicking = true;
        _controller.forward();
      }
    });
  }

  GestureDetector _buildRandomCallerInfoWidget() {
    return GestureDetector(
      onTap: () {
        // 点击显示/折叠点名器信息区域
        setState(() {
          _isRandomCallerInfoWidgetExpanded =
              !_isRandomCallerInfoWidgetExpanded;
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
                  Row(
                    children: [
                      const Text(
                        '选择点名器',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        '    ${_randomCallerGroup == null ? '无选中点名器' : (_randomCallerGroup!.randomCallerModel.isDuplicate == 0 ? '${_randomCallerGroup!.randomCallerModel.randomCallerName}：不可重复' : '${_randomCallerGroup!.randomCallerModel.randomCallerName}：可重复')}',
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _isRandomCallerInfoWidgetExpanded
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
              crossFadeState: _isRandomCallerInfoWidgetExpanded
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
            builder: (context) => RandomCallerViewDialog(
              randomCaller: _allRandomCallersMap[_selectedCallerId!]!,
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
            builder: (context) => RandomCallerAddEditDialog(
              title: '编辑点名器',
              randomCaller: _allRandomCallersMap[_selectedCallerId!]!,
            ),
          ).then((value) {
            if (value != null && value == true) {
              // 刷新随机点名器列表
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
      onPressed: () async {
        // 校验是否有关联的随机点名记录
        final randomCallRecords = await RandomCallRecordDao()
            .getRandomCallRecordsByCallerId(_selectedCallerId!);
        if (randomCallRecords.isNotEmpty) {
          // 有随机点名记录，提示用户先删除随机点名记录
          Fluttertoast.showToast(msg: '该点名器下有随机点名记录，无法删除。请先删除该点名器下的所有随机点名记录。');
          return;
        }
        // 删除点名器功能
        if (_selectedCallerId != null) {
          if(mounted) {
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
                      await RandomCallerDao()
                          .deleteRandomCaller(_selectedCallerId!)
                          .then((value) {
                            if (value > 0) {
                              if (context.mounted) {
                                // 删除后的处理
                                _selectedCallerId = null;
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
          }
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

  Padding _buildStudentScoreWidget() {
    // 评分组件 - 一直显示
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // 分数范围和滑动条
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('1分', style: TextStyle(color: Colors.black54)),
                      Text('10分', style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Slider(
                    value: _score.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '$_score分',
                    activeColor: const Color(0xFF6C4AB6),
                    inactiveColor: Colors.grey.shade300,
                    onChanged: (value) {
                      setState(() {
                        _score = value.round();
                      });
                    },
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    '$_score分',
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C4AB6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4.0),

              // 评分按钮组
              SizedBox(
                width: double.infinity,
                height: 40.0,
                child: ElevatedButton(
                  onPressed: _currentStudent != null ? _saveScore : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C4AB6), // 紫色背景
                    foregroundColor: Colors.white, // 白色文字
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                    elevation: 4.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.save, size: 20.0),
                      SizedBox(width: 8.0),
                      Text('保存评分'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 保存评分按钮，添加随机点名记录
  void _saveScore() {
    // 获取 RandomCallRecordModel对象
    RandomCallRecordModel randomCallRecordModel = RandomCallRecordModel(
      randomCallerId: _selectedCallerId!,
      studentId: _currentStudent!.id!,
      score: _score,
      notes: '',
      created: DateTime.now(),
    );
    RandomCallRecordDao().insertRandomCallRecord(randomCallRecordModel).then((
      value,
    ) {
      if (value > 0) {
        // 插入成功
        randomCallRecordModel.id = value;
        setState(() {
          // 更新选中的随机点名记录
          _randomCallerGroup!.randomCallRecords[_currentStudent!.id!]!.add(
            randomCallRecordModel,
          );
          // 如果不可重复
          if (_randomCallerGroup!.randomCallerModel.isDuplicate == 0) {
            // 如果不可重复选择，从可选择学生中移除当前选中的学生
            _ableToSelectStudents.remove(_currentStudent!.id!);
            // 初始选择第一个学生
            _currentStudent = _ableToSelectStudents.isNotEmpty
                ? _ableToSelectStudents.values.first
                : null;
          }
          // 保存评分后，重置分数为默认值5分
          _score = 5;
        });
      }
    });
  }

  // 计算学生平均分
  double _calculateAverageScore(List<int> scores) {
    if (scores.isEmpty) return 0.0;
    double sum = scores.fold(0, (sum, score) => sum + score);
    return sum / scores.length;
  }

  // 构建学生组列表
  Widget _buildStudentGroup({required bool isPickedGroup}) {
    if (_randomCallerGroup == null || _randomCallerGroup!.students.isEmpty) {
      return const Text(
        '暂无学生',
        style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
      );
    }
    List<Map<StudentModel, List<RandomCallRecordModel>>> studentRecords = [];
    for (StudentModel student in _randomCallerGroup!.students.values) {
      if (_randomCallerGroup!.randomCallRecords.containsKey(student.id!)) {
        if (_randomCallerGroup!.randomCallRecords[student.id!]!.isNotEmpty &&
            isPickedGroup) {
          studentRecords.add({
            student: _randomCallerGroup!.randomCallRecords[student.id!] ?? [],
          });
        }
        if (_randomCallerGroup!.randomCallRecords[student.id!]!.isEmpty &&
            !isPickedGroup) {
          studentRecords.add({
            student: _randomCallerGroup!.randomCallRecords[student.id!] ?? [],
          });
        }
      }
    }

    // 对学生进行排序：已抽取学生按抽取次数降序，未抽取学生按学号升序
    studentRecords.sort((a, b) {
      if (a.values.first.isNotEmpty && b.values.first.isNotEmpty) {
        // 已抽取学生按抽取次数降序
        return b.values.first.length.compareTo(a.values.first.length);
      } else {
        // 未抽取学生按学号升序
        return a.keys.first.studentNumber.compareTo(b.keys.first.studentNumber);
      }
    });

    return Column(
      children: studentRecords.map((studentRecord) {
        double average = _calculateAverageScore(
          List<int>.from(studentRecord.values.first.map((e) => e.score)),
        );
        return GestureDetector(
          onTap: () {
            // 实现手动抽取功能
            setState(() {
              // 设置当前学生为被点击的学生
              if (_randomCallerGroup!.randomCallerModel.isDuplicate == 0 &&
                  isPickedGroup) {
                Fluttertoast.showToast(
                  msg:
                      '${_randomCallerGroup!.randomCallerModel.randomCallerName}不可重复选择，已抽取学生无法重复选择',
                );
              } else {
                _currentStudent = studentRecord.keys.first;
              }
              // 重置分数为默认值5分
              _score = 5;
            });

            // 滚动到抽取学生区域
            _scrollController.animateTo(
              0, // 滚动到页面顶部（抽取学生区域在顶部）
              duration: const Duration(milliseconds: 500), // 滚动动画持续时间
              curve: Curves.easeInOut, // 滚动曲线
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: studentRecord.values.first.isNotEmpty
                    ? Color(0xFF6C4AB6)
                    : Colors.grey.shade200,
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentRecord.keys.first.studentName,
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      studentRecord.keys.first.studentNumber,
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '抽取: ${studentRecord.values.first.length}次',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: studentRecord.values.first.isNotEmpty
                                ? Color(0xFF6C4AB6)
                                : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          '平均分: ${average > 0 ? average.toStringAsFixed(1) : '—'}',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: average > 0
                                ? Color(0xFF6C4AB6)
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Padding _buildStudentCardsWidget() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '学生列表',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16.0),

              // 已抽取学生组
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isPickedGroupExpanded = !_isPickedGroupExpanded;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '已抽取学生',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C4AB6),
                      ),
                    ),
                    Icon(
                      _isPickedGroupExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: Color(0xFF6C4AB6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4.0),
              AnimatedCrossFade(
                firstChild: Container(height: 0),
                secondChild: _buildStudentGroup(isPickedGroup: true),
                crossFadeState: _isPickedGroupExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
                sizeCurve: Curves.easeInOut,
              ),

              const SizedBox(height: 8.0),

              // 未抽取学生组
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isUnpickedGroupExpanded = !_isUnpickedGroupExpanded;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '未抽取学生',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C4AB6),
                      ),
                    ),
                    Icon(
                      _isUnpickedGroupExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: Color(0xFF6C4AB6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12.0),
              AnimatedCrossFade(
                firstChild: Container(height: 0),
                secondChild: _buildStudentGroup(isPickedGroup: false),
                crossFadeState: _isUnpickedGroupExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
                sizeCurve: Curves.easeInOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
