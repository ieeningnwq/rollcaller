import 'dart:io';

import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rollcall/models/random_caller_group.dart';
import 'package:rollcall/models/student_class_model.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../models/random_call_record.dart';
import '../models/random_caller_model.dart';
import '../models/student_model.dart';
import '../utils/random_call_record_dao.dart';
import '../utils/random_caller_dao.dart';
import '../utils/student_class_dao.dart';
import '../utils/student_dao.dart';

class RandomCallRecordsPage extends StatefulWidget {
  const RandomCallRecordsPage({super.key});

  @override
  State<StatefulWidget> createState() => _RandomRecordsState();
}

class _RandomRecordsState extends State<RandomCallRecordsPage> {
  // 筛选条件是否展开
  bool _isFilterExpanded = true;

  // 全部点名器
  Map<int, RandomCallerModel> _allCallers = {};
  // 全部班级
  Map<int, StudentClassModel> _allClasses = {};
  // 按点名器分组记录
  Map<int, RandomCallerGroupModel> _groupedRecords = {};
  Map<int, RandomCallerGroupModel> _filteredRecords = {};
  // 筛选条件：选中的点名器
  int? _selectedCallerId;
  // 筛选条件：选中的班级
  int? _selectedClassId;
  // 筛选条件：日期范围
  DateTime? _startDate;
  // 筛选条件：结束日期
  DateTime? _endDate;
  // 筛选条件：是否归档
  bool? _isArchiveFilter;
  // 获取所有点名器所有信息Future
  late Future<Map<int, RandomCallerGroupModel>> _allRandomCallerGroupFuture;

  @override
  initState() {
    super.initState();
    _allRandomCallerGroupFuture = _getAllRandomCallerGroups();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _allRandomCallerGroupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }  else {
          _groupedRecords = snapshot.data!;
          return Expanded(
            child: Column(
              children: [
                // 筛选区域
                _buildSelectersWidget(),
                // 学生列表区域
                Expanded(
                  child: _filteredRecords.isEmpty
                      ? SingleChildScrollView(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  '没有找到点名记录',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '请尝试调整筛选条件',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredRecords.length,
                          itemBuilder: (context, index) {
                            final group = _filteredRecords.values
                                .toList()[index];
                            final cls = group.studentClassModel;

                            return Column(
                              children: [
                                // 分组标题
                                ListTile(
                                  title: Text(
                                    group.randomCallerModel.randomCallerName,
                                    style:
                                        group.randomCallerModel.isArchive == 1
                                        ? TextStyle(color: Colors.grey)
                                        : null,
                                  ),
                                  subtitle: Text(
                                    '班级: ${cls.className} | 记录数: ${group.allRecords.length}',
                                    style:
                                        group.randomCallerModel.isArchive == 1
                                        ? TextStyle(color: Colors.grey)
                                        : null,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // 归档按钮
                                      if (group.randomCallerModel.isArchive ==
                                          0)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.archive_outlined,
                                            color: Colors.orange,
                                          ),
                                          onPressed: () =>
                                              _showArchiveConfirmationDialog(
                                                group.randomCallerModel,
                                              ),
                                          tooltip: '归档',
                                        ),
                                      if (group.randomCallerModel.isArchive ==
                                          1)
                                        const Text(
                                          '已归档',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      Icon(
                                        group.isExpanded
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                        color:
                                            group.randomCallerModel.isArchive ==
                                                1
                                            ? Colors.grey
                                            : null,
                                      ),
                                    ],
                                  ),
                                  onTap: () => _toggleGroupExpanded(index),
                                  tileColor: Colors.grey[100],
                                ),

                                // 展开时显示记录列表
                                if (group.isExpanded)
                                  if (group.randomCallRecords.isEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 32,
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        '该点名器下没有点名记录',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    )
                                  else
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: group.allRecords.length,
                                      itemBuilder: (context, recordIndex) {
                                        final RandomCallRecordModel record =
                                            group.allRecords[recordIndex];
                                        final student =
                                            group.students[record.studentId];

                                        return Card(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 4,
                                          ),
                                          color:
                                              group
                                                      .randomCallerModel
                                                      .isArchive ==
                                                  1
                                              ? Colors.grey[50]
                                              : null,
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .baseline,
                                                      textBaseline: TextBaseline
                                                          .alphabetic,
                                                      children: [
                                                        Text(
                                                          student?.studentName ??
                                                              '未知学生',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16,
                                                            color:
                                                                group
                                                                        .randomCallerModel
                                                                        .isArchive ==
                                                                    1
                                                                ? Colors.grey
                                                                : null,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Text(
                                                          student?.studentNumber ??
                                                              '未知',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                group
                                                                        .randomCallerModel
                                                                        .isArchive ==
                                                                    1
                                                                ? Colors
                                                                      .grey[500]
                                                                : Colors
                                                                      .grey[600],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Text(
                                                      '分数: ${record.score}',
                                                      style: TextStyle(
                                                        color:
                                                            group
                                                                    .randomCallerModel
                                                                    .isArchive ==
                                                                1
                                                            ? Colors.grey[500]
                                                            : (record.score >=
                                                                      90
                                                                  ? Colors.green
                                                                  : Colors
                                                                        .orange),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  '班级: ${student?.className ?? ''}',
                                                  style: TextStyle(
                                                    color:
                                                        group
                                                                .randomCallerModel
                                                                .isArchive ==
                                                            1
                                                        ? Colors.grey
                                                        : null,
                                                  ),
                                                ),
                                                Text(
                                                  '时间: ${record.created.toString().substring(0, 19)}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        group
                                                                .randomCallerModel
                                                                .isArchive ==
                                                            1
                                                        ? Colors.grey[500]
                                                        : Colors.grey[600],
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                // 操作按钮（只有未归档的记录才显示）
                                                if (group
                                                        .randomCallerModel
                                                        .isArchive ==
                                                    0)
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      TextButton.icon(
                                                        onPressed: () {
                                                          _showEditScoreDialog(
                                                            record,
                                                          );
                                                        },
                                                        icon: const Icon(
                                                          Icons.edit,
                                                          size: 16,
                                                        ),
                                                        label: const Text('编辑'),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      TextButton.icon(
                                                        onPressed: () {
                                                          _showDeleteConfirmationDialog(
                                                            record,
                                                          );
                                                        },
                                                        icon: const Icon(
                                                          Icons.delete,
                                                          size: 16,
                                                        ),
                                                        label: const Text('删除'),
                                                        style:
                                                            TextButton.styleFrom(
                                                              foregroundColor:
                                                                  Colors.red,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  // 筛选区域
  GestureDetector _buildSelectersWidget() {
    // 筛选条件区域
    return GestureDetector(
      onTap: () {
        setState(() {
          _isFilterExpanded = !_isFilterExpanded;
        });
      },
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // 筛选条件标题和展开/折叠按钮
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '筛选条件',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),

                  TextButton.icon(
                    onPressed: _resetFilters,
                    icon: const Icon(Icons.refresh),
                    label: const Text('重置'),
                  ),
                  TextButton.icon(
                    onPressed: _showExportDialog,
                    icon: const Icon(Icons.file_upload),
                    label: const Text('导出'),
                  ),
                  Icon(
                    _isFilterExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                ],
              ),
            ),

            // 展开时显示筛选内容
            AnimatedCrossFade(
              firstChild: const SizedBox(height: 0, width: 0),
              secondChild: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 点名器筛选
                    Row(
                      children: [
                        const SizedBox(
                          width: 80,
                          child: Text('点名器: ', textAlign: TextAlign.justify),
                        ),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedCallerId,
                            hint: const Text('全部'),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text(
                                  '全部',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              ..._allCallers.values.toList().map(
                                (caller) => DropdownMenuItem(
                                  value: caller.id,
                                  child: Text(
                                    caller.randomCallerName,
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCallerId = value;
                                // 执行筛选
                                _applyFilters();
                              });
                            },
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 班级筛选
                    Row(
                      children: [
                        const SizedBox(
                          width: 80,
                          child: Text('班级: ', textAlign: TextAlign.justify),
                        ),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedClassId,
                            hint: const Text('全部'),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text(
                                  '全部',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              ..._allClasses.values.toList().map(
                                (cls) => DropdownMenuItem(
                                  value: cls.id,
                                  child: Text(
                                    cls.className,
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedClassId = value;
                                // 执行筛选
                                _applyFilters();
                              });
                            },
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 时间范围筛选
                    Row(
                      children: [
                        const SizedBox(
                          width: 80,
                          child: Text('时间范围: ', textAlign: TextAlign.justify),
                        ),
                        Expanded(
                          child: SizedBox(
                            height: 50, // 与DropdownButtonFormField高度一致
                            child: TextButton(
                              onPressed: () {
                                _showDateRangePicker();
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                alignment: Alignment.centerLeft,
                                height: double.infinity,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _startDate != null
                                          ? '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}'
                                          : '开始',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const Text(
                                      '至',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      _endDate != null
                                          ? '${_endDate!.subtract(const Duration(days: 1)).year}-${_endDate!.subtract(const Duration(days: 1)).month.toString().padLeft(2, '0')}-${_endDate!.subtract(const Duration(days: 1)).day.toString().padLeft(2, '0')}'
                                          : '结束',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 归档状态筛选
                    Row(
                      children: [
                        const SizedBox(
                          width: 80,
                          child: Text('是否归档: ', textAlign: TextAlign.justify),
                        ),
                        Expanded(
                          child: DropdownButtonFormField<bool?>(
                            initialValue: _isArchiveFilter,
                            hint: const Text('全部'),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text(
                                  '全部',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              const DropdownMenuItem(
                                value: false,
                                child: Text(
                                  '未归档',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              const DropdownMenuItem(
                                value: true,
                                child: Text(
                                  '已归档',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _isArchiveFilter = value;
                                // 执行筛选
                                _applyFilters();
                              });
                            },
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              crossFadeState: _isFilterExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  // 显示时间范围选择器弹窗
  void _showDateRangePicker() {
    showDialog(
      context: this.context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择时间范围'),
          content: SizedBox(
            height: 300,
            width: MediaQuery.of(context).size.width * 0.8,
            child: SfDateRangePicker(
              confirmText: '确定',
              cancelText: '取消',
              view: DateRangePickerView.month,
              selectionMode: DateRangePickerSelectionMode.range,
              initialSelectedRange: _startDate != null && _endDate != null
                  ? PickerDateRange(
                      _startDate,
                      _endDate?.subtract(const Duration(days: 1)),
                    )
                  : null,
              onSelectionChanged: _onDateRangeSelected,
              minDate: DateTime(2020),
              maxDate: DateTime.now(),
              showActionButtons: true,
              // 设置选中样式
              selectionColor: Colors.blue,
              rangeSelectionColor: const Color.fromARGB(25, 0, 0, 255),
              onCancel: () {
                Navigator.pop(context);
              },
              onSubmit: (range) {
                if (range is PickerDateRange) {
                  setState(() {
                    _startDate = range.startDate;
                    _endDate = range.endDate?.add(
                      const Duration(days: 1),
                    ); // 包含所选结束日期的整天
                    _applyFilters();
                  });
                  Navigator.pop(context);
                }
              },
            ),
          ),
        );
      },
    );
  }

  // 处理日期范围选择
  void _onDateRangeSelected(DateRangePickerSelectionChangedArgs args) {
    if (args.value is PickerDateRange) {
      final PickerDateRange range = args.value as PickerDateRange;
      setState(() {
        _startDate = range.startDate;
        _endDate = range.endDate?.add(const Duration(days: 1)); // 包含所选结束日期的整天
        _applyFilters();
      });
    }
  }

  // 重置筛选条件
  void _resetFilters() {
    setState(() {
      _selectedCallerId = null;
      _selectedClassId = null;
      _startDate = null;
      _endDate = null;
      _isArchiveFilter = null; // 重置归档筛选
      _applyFilters();
    });
  }

  // 切换分组展开/折叠状态
  void _toggleGroupExpanded(int index) {
    setState(() {
      _filteredRecords.values.toList()[index].isExpanded = !_filteredRecords
          .values
          .toList()[index]
          .isExpanded;
    });
  }

  Future<Map<int, RandomCallerGroupModel>> _getAllRandomCallerGroups() async {
    Map<int, RandomCallerGroupModel> randomCallerGroupsMap = {};
    // 获取所有班级信息，筛选按钮需要
    _allClasses = {
      for (var studentClass in await StudentClassDao().getAllStudentClasses())
        studentClass.id!: studentClass,
    };
    // 获取全部签到点名器
    List<RandomCallerModel> allRandomCallers = await RandomCallerDao()
        .getAllRandomCallers();
    // 保存全部签到点名器
    _allCallers = {
      for (var randomCaller in allRandomCallers) randomCaller.id!: randomCaller,
    };
    for (var selectedCaller in _allCallers.values) {
      // 获取班级信息
      StudentClassModel studentClass = _allClasses[selectedCaller.classId]!;
      // 获取班级学生
      List<StudentModel> students = await StudentDao()
          .getAllStudentsByClassName(studentClass.className);
      // 获取签到记录
      List<RandomCallRecordModel> records = await RandomCallRecordDao()
          .getRecordsByCallerId(callerId: selectedCaller.id!);
      // 构建签到记录映射
      Map<int, List<RandomCallRecordModel>> randomCallRecords = {};
      for (var student in students) {
        randomCallRecords[student.id!] = [];
      }

      for (RandomCallRecordModel record in records) {
        randomCallRecords[record.studentId]!.add(record);
      }
      randomCallerGroupsMap[selectedCaller.id!] = RandomCallerGroupModel(
        randomCallerModel: selectedCaller,
        students: {for (var student in students) student.id!: student},
        studentClassModel: studentClass,
        randomCallRecords: randomCallRecords,
      );
    }
    // 初始筛选记录
    _filteredRecords = randomCallerGroupsMap;
    // 构建并返回分组模型
    return randomCallerGroupsMap;
  }

  void _applyFilters() {
    var filterRecords = _groupedRecords.entries.where((group) {
      // 点名器筛选
      if (_selectedCallerId != null &&
          group.value.randomCallerModel.id != _selectedCallerId) {
        return false;
      }
      // 班级筛选
      if (_selectedClassId != null &&
          group.value.studentClassModel.id != _selectedClassId) {
        return false;
      }
      // 归档状态筛选
      if (_isArchiveFilter != null &&
          (group.value.randomCallerModel.isArchive == 1) != _isArchiveFilter) {
        return false;
      }
      // 时间筛选
      if (_startDate != null || _endDate != null) {
        bool hasMatchingRecord = false;
        for (final record in group.value.randomCallRecords.values.expand(
          (records) => records,
        )) {
          bool matchesStart =
              _startDate == null || record.created.isAfter(_startDate!);
          bool matchesEnd =
              _endDate == null || record.created.isBefore(_endDate!);
          if (matchesStart && matchesEnd) {
            hasMatchingRecord = true;
            break;
          }
        }
        if (!hasMatchingRecord) {
          return false;
        }
      }
      return true;
    });
    setState(() {
      _filteredRecords = Map.fromEntries(filterRecords);
    });
  }

  void _showEditScoreDialog(RandomCallRecordModel record) {
    final TextEditingController scoreController = TextEditingController(
      text: record.score.toString(),
    );

    showDialog(
      context: this.context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('编辑分数'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: scoreController,
                  keyboardType: TextInputType.number,
                  autovalidateMode: AutovalidateMode.onUnfocus,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: '分数',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入分数';
                    }
                    int num = int.tryParse(value)!;
                    if (num <= 0 || num > 10) {
                      return '请输入有效的整数（1-10）';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final newScore = int.tryParse(scoreController.text);
                if (newScore != null) {
                  // 更新分数
                  record.score = newScore;
                  // 保存到数据库
                  RandomCallRecordDao().update(record).then((value) {
                    if (value > 0) {
                      // 刷新数据
                      setState(() {
                        _filteredRecords[record.randomCallerId]!
                                .randomCallRecords[record.studentId]!
                                .where((element) => element.id == record.id)
                                .toList()
                                .first =
                            record;
                        _groupedRecords[record.randomCallerId]!
                                .randomCallRecords[record.studentId]!
                                .where((element) => element.id == record.id)
                                .toList()
                                .first =
                            record;
                      });
                    }
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(RandomCallRecordModel record) {
    showDialog(
      context: this.context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除这条点名记录吗？此操作不可恢复。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                // 删除记录数据
                RandomCallRecordDao().delete(record.id!).then((value) {
                  if (value > 0) {
                    // 刷新数据
                    setState(() {
                      _filteredRecords[record.randomCallerId]!
                          .randomCallRecords[record.studentId]!
                          .removeWhere((element) => element.id == record.id);
                      _groupedRecords[record.randomCallerId]!
                          .randomCallRecords[record.studentId]!
                          .removeWhere((element) => element.id == record.id);
                    });
                  }
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }
  // 显示归档确认对话框

  void _showArchiveConfirmationDialog(RandomCallerModel randomCallerModel) {
    showDialog(
      context: this.context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认归档'),
          content: const Text('归档后该点名器及记录将不可修改且无法撤销，是否继续？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                // 归档点名器
                randomCallerModel.isArchive = 1;
                RandomCallerDao().updateRandomCaller(randomCallerModel).then((
                  value,
                ) {
                  if (value > 0) {
                    // 刷新数据
                    setState(() {
                      _filteredRecords[randomCallerModel.id]!
                              .randomCallerModel
                              .isArchive =
                          1;
                      _groupedRecords[randomCallerModel.id]!
                              .randomCallerModel
                              .isArchive =
                          1;
                    });
                  }
                });
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('确认归档'),
            ),
          ],
        );
      },
    );
  }

  // 选择点名器导出的对话框
  Future<void> _showExportDialog() async {
    // 状态变量用于跟踪选中的点名器
    Set<int> selectedCallerIds = {};

    // 显示选择对话框
    await showDialog(
      context: this.context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择需要导出的点名器'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('请选择要导出的点名器：'),
                    const SizedBox(height: 12),
                    ..._allCallers.values.toList().map((caller) {
                      return CheckboxListTile(
                        title: Text(caller.randomCallerName),
                        subtitle: Text(
                          '班级: ${_allClasses[caller.classId]?.className}',
                        ),
                        value: selectedCallerIds.contains(caller.id),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedCallerIds.add(caller.id!);
                            } else {
                              selectedCallerIds.remove(caller.id);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (selectedCallerIds.isNotEmpty) {
                  _exportToExcel(selectedCallerIds);
                } else {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('请至少选择一个点名器'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('导出'),
            ),
          ],
        );
      },
    );
  }

  // 导出数据到Excel文件
  Future<void> _exportToExcel(Set<int> selectedCallerIds) async {
    try {
      // 创建一个新的Excel文件
      Excel excelFile = Excel.createExcel();
      // 统计导出的记录数量
      int totalExportedRecords = 0;
      // 为每个选中的点名器创建一个工作表
      for (int callerId in selectedCallerIds) {
        // 找到对应的点名器
        RandomCallerModel? caller;
        try {
          caller = _allCallers[callerId];
        } catch (e) {
          // 点名器不存在，跳过
          continue;
        }
        // 获取该点名器的所有记录
        List<RandomCallRecordModel> records =
            _groupedRecords[callerId]!.allRecords;
        // 没有记录跳过，不保存该点名器的工作表
        if (records.isEmpty) continue;

        // 创建工作表，表名使用点名器名称
        String sheetName = caller!.randomCallerName;
        // 确保表名不超过Excel限制的31个字符
        if (sheetName.length > 31) {
          sheetName = sheetName.substring(0, 31);
        }
        // 创建或获取工作表
        Sheet sheet = excelFile[sheetName];
        // 设置表头
        sheet.appendRow([
          TextCellValue('序号'),
          TextCellValue('点名器名称'),
          TextCellValue('班级名称'),
          TextCellValue('学生学号'),
          TextCellValue('学生姓名'),
          TextCellValue('分数'),
          TextCellValue('点名时间'),
          TextCellValue('备注'),
        ]);

        // 导出每条记录
        for (int i = 0; i < records.length; i++) {
          RandomCallRecordModel record = records[i];
          // 获取学生信息
          StudentModel student =
              _groupedRecords[callerId]!.students[record.studentId]!;
          // 获取班级信息
          StudentClassModel cls = _groupedRecords[callerId]!.studentClassModel;

          sheet.appendRow([
            TextCellValue((i + 1).toString()),
            TextCellValue(caller.randomCallerName),
            TextCellValue(cls.className),
            TextCellValue(student.studentNumber),
            TextCellValue(student.studentName),
            TextCellValue(record.score.toString()),
            TextCellValue(record.created.toIso8601String()),
            TextCellValue(record.notes),
          ]);
          totalExportedRecords++;
        }
      }
      // 如果没有导出任何记录，显示提示
      if (totalExportedRecords == 0) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(
            content: Text('没有找到可导出的记录'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      // 保存Excel文件

      String fileName =
          '点名记录_${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().hour}${DateTime.now().minute}${DateTime.now().second}.xlsx';
      String downloadsPath = '';
      // 根据不同平台获取下载路径
      if (Platform.isAndroid || Platform.isIOS) {
        var directory = await getExternalStorageDirectory();
        downloadsPath = join(directory!.path, fileName);
      } else if (Platform.isWindows) {
        downloadsPath = '${Platform.environment['USERPROFILE']}/Downloads/';
      } else if (Platform.isMacOS) {
        downloadsPath = '${Platform.environment['HOME']}/Downloads/';
      }
      excelFile.delete('Sheet1');
      var fileBytes = excelFile.save();
      // 确保目录存在，保存Excel文件
      File(downloadsPath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes!);
      // 显示导出成功信息
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text(
              '导出成功！共导出 $totalExportedRecords 条记录到文件：$fileName',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // 显示导出失败信息
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text(
              '导出失败：${e.toString()}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
