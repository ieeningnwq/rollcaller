import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'dart:io';

// 班级对象模型
class Class {
  final String classId;
  final String className;
  final DateTime createTime;

  Class({
    required this.classId,
    required this.className,
    required this.createTime,
  });
}

// 学生对象模型
class Student {
  final String studentId;
  final String name;
  final String studentNumber;
  final String className;
  final DateTime createTime;

  Student({
    required this.studentId,
    required this.name,
    required this.studentNumber,
    required this.className,
    required this.createTime,
  });
}

// 点名器对象模型
class Caller {
  final String callerId;
  final String callerName;
  final String classId;
  final DateTime createTime;
  final bool isArchive;

  Caller({
    required this.callerId,
    required this.callerName,
    required this.classId,
    required this.createTime,
    this.isArchive = false,
  });
}

// 点名记录对象模型
class AttendanceRecord {
  final String callerId;
  final String studentId;
  final int score;
  final DateTime createTime;

  AttendanceRecord({
    required this.callerId,
    required this.studentId,
    required this.score,
    required this.createTime,
  });
}

// 分组记录模型
class GroupedRecords {
  final Caller caller;
  final List<AttendanceRecord> records;
  bool isExpanded;

  GroupedRecords({
    required this.caller,
    required this.records,
    this.isExpanded = false,
  });
}

// 主页面组件
class AttendanceRecordsPage extends StatelessWidget {
  const AttendanceRecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '点名记录查看',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AttendanceRecordsView(),
    );
  }
}

// 点名记录查看页面
class AttendanceRecordsView extends StatefulWidget {
  const AttendanceRecordsView({super.key});

  @override
  State<AttendanceRecordsView> createState() => _AttendanceRecordsViewState();
}

class _AttendanceRecordsViewState extends State<AttendanceRecordsView> {
  // 筛选条件
  String? _selectedCallerId;
  String? _selectedClassId;
  DateTime? _startDate;
  DateTime? _endDate;
  bool? _isArchiveFilter; // 是否归档筛选
  bool _isFilterExpanded = true; // 筛选条件是否展开

  // 模拟数据
  final List<Class> _classes = [
    Class(
      classId: 'class1',
      className: '三年级一班',
      createTime: DateTime(2023, 9, 1),
    ),
    Class(
      classId: 'class2',
      className: '三年级二班',
      createTime: DateTime(2023, 9, 1),
    ),
  ];

  final List<Student> _students = [
    Student(
      studentId: 'student1',
      name: '张三',
      studentNumber: '20230001',
      className: '三年级一班',
      createTime: DateTime(2023, 9, 1),
    ),
    Student(
      studentId: 'student2',
      name: '李四',
      studentNumber: '20230002',
      className: '三年级一班',
      createTime: DateTime(2023, 9, 1),
    ),
    Student(
      studentId: 'student3',
      name: '王五',
      studentNumber: '20230003',
      className: '三年级二班',
      createTime: DateTime(2023, 9, 1),
    ),
  ];

  final List<Caller> _callers = [
    Caller(
      callerId: 'caller1',
      callerName: '语文点名器',
      classId: 'class1',
      createTime: DateTime(2023, 9, 10),
      isArchive: false,
    ),
    Caller(
      callerId: 'caller2',
      callerName: '数学点名器',
      classId: 'class1',
      createTime: DateTime(2023, 9, 15),
      isArchive: false,
    ),
    Caller(
      callerId: 'caller3',
      callerName: '英语点名器',
      classId: 'class2',
      createTime: DateTime(2023, 9, 20),
      isArchive: false,
    ),
  ];

  final List<AttendanceRecord> _records = [
    AttendanceRecord(
      callerId: 'caller1',
      studentId: 'student1',
      score: 95,
      createTime: DateTime(2023, 10, 1, 10, 0),
    ),
    AttendanceRecord(
      callerId: 'caller1',
      studentId: 'student2',
      score: 88,
      createTime: DateTime(2023, 10, 1, 10, 15),
    ),
    AttendanceRecord(
      callerId: 'caller2',
      studentId: 'student1',
      score: 92,
      createTime: DateTime(2023, 10, 2, 14, 30),
    ),
    AttendanceRecord(
      callerId: 'caller2',
      studentId: 'student2',
      score: 85,
      createTime: DateTime(2023, 10, 2, 14, 45),
    ),
    AttendanceRecord(
      callerId: 'caller3',
      studentId: 'student3',
      score: 90,
      createTime: DateTime(2023, 10, 3, 9, 15),
    ),
  ];

  // 按点名器分组记录
  List<GroupedRecords> _groupedRecords = [];
  List<GroupedRecords> _filteredRecords = [];

  @override
  void initState() {
    super.initState();
    _groupRecords();
    _applyFilters();
  }

  // 按点名器分组记录
  void _groupRecords() {
    final Map<String, List<AttendanceRecord>> recordsByCaller = {};

    // 按点名器ID分组记录
    for (final record in _records) {
      if (!recordsByCaller.containsKey(record.callerId)) {
        recordsByCaller[record.callerId] = [];
      }
      recordsByCaller[record.callerId]!.add(record);
    }

    // 创建分组记录列表
    _groupedRecords = [];
    for (final caller in _callers) {
      final records = recordsByCaller[caller.callerId] ?? [];
      _groupedRecords.add(GroupedRecords(
        caller: caller,
        records: records,
        isExpanded: false,
      ));
    }
  }

  // 应用筛选条件
  void _applyFilters() {
    setState(() {
      _filteredRecords = _groupedRecords.where((group) {
        // 点名器筛选
        if (_selectedCallerId != null && group.caller.callerId != _selectedCallerId) {
          return false;
        }
        
        // 班级筛选
        if (_selectedClassId != null && group.caller.classId != _selectedClassId) {
          return false;
        }
        
        // 归档状态筛选
        if (_isArchiveFilter != null && group.caller.isArchive != _isArchiveFilter) {
          return false;
        }
        
        // 时间筛选
        if (_startDate != null || _endDate != null) {
          bool hasMatchingRecord = false;
          for (final record in group.records) {
            bool matchesStart = _startDate == null || record.createTime.isAfter(_startDate!);
            bool matchesEnd = _endDate == null || record.createTime.isBefore(_endDate!);
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
      }).map((group) {
        // 过滤每个分组中的记录
        List<AttendanceRecord> filteredGroupRecords = group.records.where((record) {
          bool matchesStart = _startDate == null || record.createTime.isAfter(_startDate!);
          bool matchesEnd = _endDate == null || record.createTime.isBefore(_endDate!);
          return matchesStart && matchesEnd;
        }).toList();
        
        return GroupedRecords(
          caller: group.caller,
          records: filteredGroupRecords,
          isExpanded: group.isExpanded,
        );
      }).toList();
    });
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
              view: DateRangePickerView.month,
              selectionMode: DateRangePickerSelectionMode.range,
              initialSelectedRange: _startDate != null && _endDate != null
                  ? PickerDateRange(
                      _startDate,
                      _endDate?.subtract(const Duration(days: 1))
                    )
                  : null,
              onSelectionChanged: _onDateRangeSelected,
              minDate: DateTime(2020),
              maxDate: DateTime.now(),
              showActionButtons: false,
              // 设置选中样式
              selectionColor: Colors.blue,
              rangeSelectionColor: const Color.fromARGB(25, 0, 0, 255),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  // 切换分组展开/折叠状态
  void _toggleGroupExpanded(int index) {
    setState(() {
      _filteredRecords[index].isExpanded = !_filteredRecords[index].isExpanded;
    });
  }

  // 显示归档确认对话框
  void _showArchiveConfirmationDialog(int groupIndex) {
    showDialog(
      context: context,
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
                Navigator.pop(context);
                _archiveCaller(groupIndex);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('确认归档'),
            ),
          ],
        );
      },
    );
  }

  // 归档点名器
  void _archiveCaller(int groupIndex) {
    setState(() {
      final caller = _filteredRecords[groupIndex].caller;
      
      // 创建新的归档状态的Caller对象
      final archivedCaller = Caller(
        callerId: caller.callerId,
        callerName: caller.callerName,
        classId: caller.classId,
        createTime: caller.createTime,
        isArchive: true,
      );
      
      // 更新过滤后的记录
      _filteredRecords[groupIndex] = GroupedRecords(
        caller: archivedCaller,
        records: _filteredRecords[groupIndex].records,
        isExpanded: _filteredRecords[groupIndex].isExpanded,
      );
      
      // 更新原始_callers列表中的归档状态
      final callerIndex = _callers.indexWhere((c) => c.callerId == caller.callerId);
      if (callerIndex != -1) {
        _callers[callerIndex] = archivedCaller;
      }
    });
  }

  // 根据学生ID获取学生信息
  Student? _getStudentById(String studentId) {
    return _students.firstWhere((student) => student.studentId == studentId);
  }

  // 根据班级ID获取班级信息
  Class? _getClassById(String classId) {
    return _classes.firstWhere((cls) => cls.classId == classId);
  }

  // 显示编辑分数对话框
  void _showEditScoreDialog(int groupIndex, int recordIndex) {
    final record = _filteredRecords[groupIndex].records[recordIndex];
    final TextEditingController scoreController = TextEditingController(text: record.score.toString());
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('编辑分数'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: scoreController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '分数',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入分数';
                    }
                    final score = int.tryParse(value);
                    if (score == null) {
                      return '请输入有效的数字';
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
                  _editRecordScore(groupIndex, recordIndex, newScore);
                  Navigator.pop(context);
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  // 编辑记录分数
  void _editRecordScore(int groupIndex, int recordIndex, int newScore) {
    setState(() {
      // 更新_filteredRecords中的记录
      final record = _filteredRecords[groupIndex].records[recordIndex];
      final updatedRecord = AttendanceRecord(
        callerId: record.callerId,
        studentId: record.studentId,
        score: newScore,
        createTime: record.createTime,
      );
      _filteredRecords[groupIndex].records[recordIndex] = updatedRecord;
      
      // 同时更新原始_records列表中的记录
      final originalIndex = _records.indexWhere(
        (r) => r.callerId == record.callerId && 
               r.studentId == record.studentId && 
               r.createTime == record.createTime
      );
      if (originalIndex != -1) {
        _records[originalIndex] = updatedRecord;
      }
    });
  }

  // 显示删除确认对话框
  void _showDeleteConfirmationDialog(int groupIndex, int recordIndex) {
    showDialog(
      context: context,
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
                _deleteRecord(groupIndex, recordIndex);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  // 删除记录
  void _deleteRecord(int groupIndex, int recordIndex) {
    setState(() {
      // 获取要删除的记录
      final recordToDelete = _filteredRecords[groupIndex].records[recordIndex];
      
      // 从_filteredRecords中删除
      _filteredRecords[groupIndex].records.removeAt(recordIndex);
      
      // 如果该分组下没有记录了，从_filteredRecords中移除该分组
      if (_filteredRecords[groupIndex].records.isEmpty) {
        _filteredRecords.removeAt(groupIndex);
      }
      
      // 从原始_records列表中删除
      _records.removeWhere(
        (r) => r.callerId == recordToDelete.callerId && 
               r.studentId == recordToDelete.studentId && 
               r.createTime == recordToDelete.createTime
      );
      
      // 重新分组记录
      _groupRecords();
    });
  }
  
  // 选择点名器导出的对话框
  Future<void> _showExportDialog() async {
    // 保存BuildContext的副本
    final scaffoldContext = context;
    
    // 状态变量用于跟踪选中的点名器
    List<String> selectedCallerIds = [];
    
    // 显示选择对话框
    await showDialog(
      context: scaffoldContext,
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
                    ..._callers.map((caller) {
                      return CheckboxListTile(
                        title: Text(caller.callerName),
                        subtitle: Text('班级: ${_getClassById(caller.classId)?.className}'),
                        value: selectedCallerIds.contains(caller.callerId),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedCallerIds.add(caller.callerId);
                            } else {
                              selectedCallerIds.remove(caller.callerId);
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
                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
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
  
  // 从Excel文件导入数据
  Future<void> _importFromExcel() async {
    // 保存BuildContext的副本
    final scaffoldContext = context;
    
    try {
      // 选择Excel文件
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      
      if (result == null) return; // 用户取消选择
      
      File file = File(result.files.single.path!);
      
      // 读取Excel文件
      var bytes = file.readAsBytesSync();
      var excelPackage = excel.Excel.decodeBytes(bytes);
      
      // 解析不同工作表的数据
      int classCount = _parseClasses(excelPackage);
      int studentCount = _parseStudents(excelPackage);
      int callerCount = _parseCallers(excelPackage);
      int recordCount = _parseRecords(excelPackage);
      
      // 重新分组记录并应用筛选
      setState(() {
        _groupRecords();
        _applyFilters();
      });
      
      // 显示导入结果
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          content: Text(
            '导入成功！共导入 $classCount 个班级，$studentCount 个学生，$callerCount 个点名器，$recordCount 条点名记录',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // 显示导入失败信息
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          content: Text(
            '导入失败：${e.toString()}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  // 导出数据到Excel文件
  Future<void> _exportToExcel(List<String> selectedCallerIds) async {
    // 保存BuildContext的副本
    final scaffoldContext = context;
    
    try {
      // 创建一个新的Excel文件
      var excelPackage = excel.Excel.createExcel();
      
      // 统计导出的记录数量
      int totalExportedRecords = 0;
      
      // 为每个选中的点名器创建一个工作表
      for (String callerId in selectedCallerIds) {
        // 找到对应的点名器
        Caller? caller;
        try {
          caller = _callers.firstWhere((c) => c.callerId == callerId);
        } catch (e) {
          // 点名器不存在，跳过
          continue;
        }
        
        // 获取该点名器的所有记录
        List<AttendanceRecord> records = _records.where((r) => r.callerId == callerId).toList();
        if (records.isEmpty) continue;
        
        // 创建工作表，表名使用点名器名称
        String sheetName = caller.callerName;
        // 确保表名不超过Excel限制的31个字符
        if (sheetName.length > 31) {
          sheetName = sheetName.substring(0, 31);
        }
        
        // 创建或获取工作表
        excel.Sheet sheet;
        if (excelPackage.tables.containsKey(sheetName)) {
          sheet = excelPackage.tables[sheetName]!;
        } else {
          // 如果工作表不存在，创建一个新的
          // 先获取默认工作表，然后复制它
          sheet = excelPackage.tables['Sheet1']!;
          // 重命名工作表
          excelPackage.rename('Sheet1', sheetName);
        }
        
        // 设置表头
        sheet.appendRow([
          excel.TextCellValue('学生ID'),
          excel.TextCellValue('学生姓名'),
          excel.TextCellValue('学号'),
          excel.TextCellValue('班级'),
          excel.TextCellValue('分数'),
          excel.TextCellValue('点名时间')
        ]);
        
        // 导出每条记录
        for (AttendanceRecord record in records) {
          // 获取学生信息
          Student? student = _getStudentById(record.studentId);
          if (student == null) continue;
          
          // 获取班级信息
          Class? cls = _getClassById(caller.classId);
          
          // 格式化日期时间
          String formattedDate = '${record.createTime.year}-${record.createTime.month.toString().padLeft(2, '0')}-${record.createTime.day.toString().padLeft(2, '0')} ${record.createTime.hour.toString().padLeft(2, '0')}:${record.createTime.minute.toString().padLeft(2, '0')}:${record.createTime.second.toString().padLeft(2, '0')}';
          
          // 添加一行数据
          sheet.appendRow([
            excel.TextCellValue(student.studentId),
            excel.TextCellValue(student.name),
            excel.TextCellValue(student.studentNumber),
            excel.TextCellValue(cls?.className ?? ''),
            excel.TextCellValue(record.score.toString()),
            excel.TextCellValue(formattedDate)
          ]);
          
          totalExportedRecords++;
        }
      }
      
      // 如果没有导出任何记录，显示提示
      if (totalExportedRecords == 0) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            content: Text('没有找到可导出的记录'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      
      // 保存Excel文件
      String fileName = '点名记录_${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().hour}${DateTime.now().minute}${DateTime.now().second}.xlsx';
      String downloadsPath = '';
      
      // 根据不同平台获取下载路径
      if (Platform.isAndroid) {
        downloadsPath = '/storage/emulated/0/Download/';
      } else if (Platform.isIOS) {
        downloadsPath = '/Documents/';
      } else if (Platform.isWindows) {
        downloadsPath = '${Platform.environment['USERPROFILE']}/Downloads/';
      } else if (Platform.isMacOS) {
        downloadsPath = '${Platform.environment['HOME']}/Downloads/';
      }
      
      // 创建文件保存路径
      String filePath = downloadsPath + fileName;
      
      // 确保目录存在
      Directory(downloadsPath).createSync(recursive: true);
      
      // 保存Excel文件
      List<int>? fileBytes = excelPackage.encode();
      if (fileBytes != null) {
        File(filePath).writeAsBytesSync(fileBytes);
      } else {
        throw Exception('无法生成Excel文件');
      }
      
      // 显示导出成功信息
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          content: Text(
            '导出成功！共导出 $totalExportedRecords 条记录到文件：$fileName',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // 显示导出失败信息
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
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
  
  // 解析班级数据
  int _parseClasses(excel.Excel excel) {
    int importedCount = 0;
    
    // 检查是否存在班级工作表
    if (excel.tables['班级'] != null) {
      var sheet = excel.tables['班级']!;
      var rows = sheet.rows;
      
      if (rows.length > 1) { // 至少有表头和一行数据
        // 验证表头
        var header = rows[0];
        if (header.length >= 3 && 
            _cellValue(header[0]) == 'classId' &&
            _cellValue(header[1]) == 'className' &&
            _cellValue(header[2]) == 'createTime') {
          
          // 解析数据行
          for (int i = 1; i < rows.length; i++) {
            var row = rows[i];
            if (row.length >= 3) {
              try {
                String classId = _cellValue(row[0]);
                String className = _cellValue(row[1]);
                DateTime createTime = DateTime.parse(_cellValue(row[2]));
                
                // 检查班级ID是否已存在
                bool exists = _classes.any((c) => c.classId == classId);
                if (!exists) {
                  // 创建新班级并添加到列表
                  var newClass = Class(
                    classId: classId,
                    className: className,
                    createTime: createTime,
                  );
                  _classes.add(newClass);
                  importedCount++;
                }
              } catch (e) {
                // 跳过解析失败的行
                continue;
              }
            }
          }
        }
      }
    }
    
    return importedCount;
  }
  
  // 解析学生数据
  int _parseStudents(excel.Excel excel) {
    int importedCount = 0;
    
    // 检查是否存在学生工作表
    if (excel.tables['学生'] != null) {
      var sheet = excel.tables['学生']!;
      var rows = sheet.rows;
      
      if (rows.length > 1) { // 至少有表头和一行数据
        // 验证表头
        var header = rows[0];
        if (header.length >= 5 && 
            _cellValue(header[0]) == 'studentId' &&
            _cellValue(header[1]) == 'name' &&
            _cellValue(header[2]) == 'studentNumber' &&
            _cellValue(header[3]) == 'className' &&
            _cellValue(header[4]) == 'createTime') {
          
          // 解析数据行
          for (int i = 1; i < rows.length; i++) {
            var row = rows[i];
            if (row.length >= 5) {
              try {
                String studentId = _cellValue(row[0]);
                String name = _cellValue(row[1]);
                String studentNumber = _cellValue(row[2]);
                String className = _cellValue(row[3]);
                DateTime createTime = DateTime.parse(_cellValue(row[4]));
                
                // 检查学生ID是否已存在
                bool exists = _students.any((s) => s.studentId == studentId);
                if (!exists) {
                  // 创建新学生并添加到列表
                  var newStudent = Student(
                    studentId: studentId,
                    name: name,
                    studentNumber: studentNumber,
                    className: className,
                    createTime: createTime,
                  );
                  _students.add(newStudent);
                  importedCount++;
                }
              } catch (e) {
                // 跳过解析失败的行
                continue;
              }
            }
          }
        }
      }
    }
    
    return importedCount;
  }
  
  // 解析点名器数据
  int _parseCallers(excel.Excel excel) {
    int importedCount = 0;
    
    // 检查是否存在点名器工作表
    if (excel.tables['点名器'] != null) {
      var sheet = excel.tables['点名器']!;
      var rows = sheet.rows;
      
      if (rows.length > 1) { // 至少有表头和一行数据
        // 验证表头
        var header = rows[0];
        if (header.length >= 5 && 
            _cellValue(header[0]) == 'callerId' &&
            _cellValue(header[1]) == 'callerName' &&
            _cellValue(header[2]) == 'classId' &&
            _cellValue(header[3]) == 'createTime' &&
            _cellValue(header[4]) == 'isArchive') {
          
          // 解析数据行
          for (int i = 1; i < rows.length; i++) {
            var row = rows[i];
            if (row.length >= 5) {
              try {
                String callerId = _cellValue(row[0]);
                String callerName = _cellValue(row[1]);
                String classId = _cellValue(row[2]);
                DateTime createTime = DateTime.parse(_cellValue(row[3]));
                bool isArchive = _cellValue(row[4]).toLowerCase() == 'true';
                
                // 检查点名器ID是否已存在
                bool exists = _callers.any((c) => c.callerId == callerId);
                if (!exists) {
                  // 创建新点名器并添加到列表
                  var newCaller = Caller(
                    callerId: callerId,
                    callerName: callerName,
                    classId: classId,
                    createTime: createTime,
                    isArchive: isArchive,
                  );
                  _callers.add(newCaller);
                  importedCount++;
                }
              } catch (e) {
                // 跳过解析失败的行
                continue;
              }
            }
          }
        }
      }
    }
    
    return importedCount;
  }
  
  // 解析点名记录数据
  int _parseRecords(excel.Excel excel) {
    int importedCount = 0;
    
    // 检查是否存在点名记录工作表
    if (excel.tables['点名记录'] != null) {
      var sheet = excel.tables['点名记录']!;
      var rows = sheet.rows;
      
      if (rows.length > 1) { // 至少有表头和一行数据
        // 验证表头
        var header = rows[0];
        if (header.length >= 4 && 
            _cellValue(header[0]) == 'callerId' &&
            _cellValue(header[1]) == 'studentId' &&
            _cellValue(header[2]) == 'score' &&
            _cellValue(header[3]) == 'createTime') {
          
          // 解析数据行
          for (int i = 1; i < rows.length; i++) {
            var row = rows[i];
            if (row.length >= 4) {
              try {
                String callerId = _cellValue(row[0]);
                String studentId = _cellValue(row[1]);
                int score = int.parse(_cellValue(row[2]));
                DateTime createTime = DateTime.parse(_cellValue(row[3]));
                
                // 检查记录是否已存在
                bool exists = _records.any((r) => 
                  r.callerId == callerId && 
                  r.studentId == studentId && 
                  r.createTime == createTime
                );
                
                if (!exists) {
                  // 创建新记录并添加到列表
                  var newRecord = AttendanceRecord(
                    callerId: callerId,
                    studentId: studentId,
                    score: score,
                    createTime: createTime,
                  );
                  _records.add(newRecord);
                  importedCount++;
                }
              } catch (e) {
                // 跳过解析失败的行
                continue;
              }
            }
          }
        }
      }
    }
    
    return importedCount;
  }
  
  // 获取单元格值的辅助方法
  String _cellValue(dynamic cell) {
    if (cell == null) return '';
    return cell.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('点名记录查看'),
      ),
      body: Column(
        children: [
          // 筛选条件区域
          GestureDetector(
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
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 点名器筛选
                          Row(
                            children: [
                              const SizedBox(width: 80, child: Text('点名器: ', textAlign: TextAlign.right)),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedCallerId,
                                  hint: const Text('全部'),
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('全部'),
                                    ),
                                    ..._callers.map((caller) => DropdownMenuItem(
                                      value: caller.callerId,
                                      child: Text(caller.callerName),
                                    )),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCallerId = value;
                                      _applyFilters();
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 48), // 添加占位符以保持右侧对齐
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // 班级筛选
                          Row(
                            children: [
                              const SizedBox(width: 80, child: Text('班级: ', textAlign: TextAlign.right)),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedClassId,
                                  hint: const Text('全部'),
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('全部'),
                                    ),
                                    ..._classes.map((cls) => DropdownMenuItem(
                                      value: cls.classId,
                                      child: Text(cls.className),
                                    )),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedClassId = value;
                                      _applyFilters();
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 48), // 添加占位符以保持右侧对齐
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // 时间范围筛选
                          Row(
                            children: [
                              const SizedBox(width: 80, child: Text('时间范围: ', textAlign: TextAlign.right)),
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
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _startDate != null 
                                              ? '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}' 
                                              : '开始',
                                            style: const TextStyle(fontSize: 14, color: Colors.black),
                                          ),
                                          const Text('至', style: TextStyle(fontSize: 14)),
                                          Text(
                                            _endDate != null 
                                              ? '${_endDate!.subtract(const Duration(days: 1)).year}-${_endDate!.subtract(const Duration(days: 1)).month.toString().padLeft(2, '0')}-${_endDate!.subtract(const Duration(days: 1)).day.toString().padLeft(2, '0')}' 
                                              : '结束',
                                            style: const TextStyle(fontSize: 14, color: Colors.black),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 48, // 固定宽度，与IconButton一致
                                child: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _startDate = null;
                                      _endDate = null;
                                      _applyFilters();
                                    });
                                  },
                                  icon: const Icon(Icons.clear),
                                  tooltip: '清除时间范围',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // 归档状态筛选
                          Row(
                            children: [
                              const SizedBox(width: 80, child: Text('是否归档: ', textAlign: TextAlign.right)),
                              Expanded(
                                child: DropdownButtonFormField<bool?>(
                                  initialValue: _isArchiveFilter,
                                  hint: const Text('全部'),
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('全部'),
                                    ),
                                    const DropdownMenuItem(
                                      value: false,
                                      child: Text('未归档'),
                                    ),
                                    const DropdownMenuItem(
                                      value: true,
                                      child: Text('已归档'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _isArchiveFilter = value;
                                      _applyFilters();
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 48), // 添加占位符以保持右侧对齐
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // 导入/导出按钮
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _importFromExcel,
                                icon: const Icon(Icons.file_upload),
                                label: const Text('导入数据'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _showExportDialog,
                                icon: const Icon(Icons.file_download),
                                label: const Text('导出数据'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // 筛选按钮
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: _resetFilters,
                                child: const Text('重置'),
                              ),
                              ElevatedButton(
                                onPressed: _applyFilters,
                                child: const Text('筛选'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    crossFadeState: _isFilterExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                ],
              ),
            ),
          ),
          
          // 记录列表
          Expanded(
            child: _filteredRecords.isEmpty
                ? Center(
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
                  )
                : ListView.builder(
                    itemCount: _filteredRecords.length,
                    itemBuilder: (context, index) {
                      final group = _filteredRecords[index];
                      final cls = _getClassById(group.caller.classId);

                      return Column(
                        children: [
                          // 分组标题
                          ListTile(
                            title: Text(
                              group.caller.callerName,
                              style: group.caller.isArchive ? TextStyle(color: Colors.grey) : null,
                            ),
                            subtitle: Text(
                              '班级: ${cls?.className ?? ''} | 记录数: ${group.records.length}',
                              style: group.caller.isArchive ? TextStyle(color: Colors.grey) : null,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 归档按钮
                                if (!group.caller.isArchive)
                                  IconButton(
                                    icon: const Icon(Icons.archive_outlined, color: Colors.orange),
                                    onPressed: () => _showArchiveConfirmationDialog(index),
                                    tooltip: '归档',
                                  ),
                                if (group.caller.isArchive)
                                  const Text(
                                    '已归档',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                Icon(
                                  group.isExpanded ? Icons.expand_less : Icons.expand_more,
                                  color: group.caller.isArchive ? Colors.grey : null,
                                ),
                              ],
                            ),
                            onTap: () => _toggleGroupExpanded(index),
                            tileColor: Colors.grey[100],
                          ),

                          // 展开时显示记录列表
                          if (group.isExpanded)
                            if (group.records.isEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
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
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: group.records.length,
                                itemBuilder: (context, recordIndex) {
                                  final record = group.records[recordIndex];
                                  final student = _getStudentById(record.studentId);

                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    color: group.caller.isArchive ? Colors.grey[50] : null,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                                textBaseline: TextBaseline.alphabetic,
                                                children: [
                                                  Text(
                                                    student?.name ?? '未知学生',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                      color: group.caller.isArchive ? Colors.grey : null,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    student?.studentNumber ?? '未知',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: group.caller.isArchive ? Colors.grey[500] : Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                '分数: ${record.score}',
                                                style: TextStyle(
                                                  color: group.caller.isArchive ? Colors.grey[500] : (record.score >= 90 ? Colors.green : Colors.orange),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '班级: ${student?.className ?? ''}',
                                            style: TextStyle(
                                              color: group.caller.isArchive ? Colors.grey : null,
                                            ),
                                          ),
                                          Text(
                                            '时间: ${record.createTime.toString().substring(0, 19)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: group.caller.isArchive ? Colors.grey[500] : Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          // 操作按钮（只有未归档的记录才显示）
                                          if (!group.caller.isArchive)
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                TextButton.icon(
                                                  onPressed: () {
                                                    _showEditScoreDialog(index, recordIndex);
                                                  },
                                                  icon: const Icon(Icons.edit, size: 16),
                                                  label: const Text('编辑'),
                                                ),
                                                const SizedBox(width: 8),
                                                TextButton.icon(
                                                  onPressed: () {
                                                    _showDeleteConfirmationDialog(index, recordIndex);
                                                  },
                                                  icon: const Icon(Icons.delete, size: 16),
                                                  label: const Text('删除'),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.red,
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
}

// 主函数，用于测试页面
void main() {
  runApp(const AttendanceRecordsPage());
}