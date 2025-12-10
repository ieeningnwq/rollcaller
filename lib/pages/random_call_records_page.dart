import 'package:flutter/material.dart';
import 'package:rollcall/models/random_caller_group.dart';
import 'package:rollcall/models/student_class_model.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../models/random_caller_model.dart';

class RandomCallRecordsPage extends StatefulWidget {
  const RandomCallRecordsPage({super.key});

  @override
  State<StatefulWidget> createState() => _RandomRecordsState();
}

class _RandomRecordsState extends State<RandomCallRecordsPage> {
  // 筛选条件是否展开
  bool _isFilterExpanded = true;
  // 选中的点名器名称（有全部选项）
  String? _selectedCallerName;
  // 全部点名器
  final Map<int, RandomCallerModel> _allCallers = {};
  // 全部班级
  final Map<int, StudentClassModel> _allClasses = {};
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 筛选区域
        _buildSelectersWidget(),
      ],
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
                  TextButton(onPressed: _resetFilters, child: const Text('重置')),
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
                                // _applyFilters();
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
                                // _applyFilters();
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
                                // _applyFilters();
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
      context: context,
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
                    // _applyFilters();
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
        // _applyFilters();
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
      // _applyFilters();
    });
  }
}
