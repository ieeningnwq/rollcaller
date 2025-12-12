import 'dart:developer';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:rollcall/models/student_class_model.dart';
import 'package:rollcall/utils/attendance_call_record_dao.dart';
import 'package:rollcall/utils/random_call_record_dao.dart';
import 'package:rollcall/utils/student_class_relation_dao.dart';

import '../models/student_class_group.dart';
import '../models/student_model.dart';
import '../utils/student_class_dao.dart';
import '../utils/student_dao.dart';
import '../widgets/student_add_edit_dialog.dart';
import '../widgets/student_view_dialog.dart';

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  // 搜索框
  final TextEditingController _searchController = TextEditingController();
  // 新增学生的学号
  final TextEditingController studentNumberController = TextEditingController();
  // 新增学生的姓名
  final TextEditingController studentNameController = TextEditingController();
  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );
  // [{班级:[学生]}] 班级学生列表
  late Map<int, StudentClassGroup> _classGroups;
  // 过滤后的班级学生列表
  Map<int, StudentClassGroup>? _filterClassGroups;
  // Future
  late Future<Map<int, StudentClassGroup>> _classGroupsFuture;

  @override
  void initState() {
    _classGroupsFuture = _getAllStudentsByClassNames();
    _searchController.addListener(() {
      String filter = _searchController.text;
      Map<int, StudentClassGroup> filterClassGroups = {};
      for (var entry in _classGroups.entries) {
        log(entry.toString());
        List<StudentModel> students = [];
        int classId = entry.key;
        StudentClassGroup group = entry.value;
        for (var student in group.students) {
          if (student.studentNumber.contains(filter) ||
              student.studentName.contains(filter)) {
            students.add(student);
          }
        }
        StudentClassGroup newGroup = StudentClassGroup(
          studentClass: group.studentClass,
          students: students,
          isExpanded: group.isExpanded,
        );
        filterClassGroups.putIfAbsent(classId, () => newGroup);
      }
      setState(() {
        _filterClassGroups = filterClassGroups;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部标题栏
            Container(
              padding: const EdgeInsets.all(12),
              child: Text(
                '学生名单管理',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Row(
              children: [
                // 搜索栏
                _searchWidget(),
                // 导入学生
                IconButton(
                  onPressed: () {
                    _importStudentsFromExcel();
                  },
                  icon: Icon(Icons.download),
                ),
              ],
            ),
            // 班级列表
            Expanded(
              child: FutureBuilder<Map<int, StudentClassGroup>>(
                future: _classGroupsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      _classGroups = snapshot.data ?? {};
                      _filterClassGroups ??= Map.from(_classGroups);

                      return SmartRefresher(
                        // 启用下拉刷新
                        enablePullDown: true,
                        // 启用上拉加载
                        enablePullUp: false,
                        // 水滴效果头部
                        header: WaterDropHeader(),
                        // 经典底部加载
                        footer: ClassicFooter(
                          loadStyle: LoadStyle.ShowWhenLoading,
                        ),
                        controller: _refreshController,
                        onRefresh: _onRefresh,
                        onLoading: _onLoading,
                        child: ListView.builder(
                          itemCount: _filterClassGroups?.length,
                          itemBuilder: (context, groupIndex) {
                            var group =
                                _filterClassGroups?[_filterClassGroups?.keys
                                    .toList()[groupIndex]]!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _classTitleWidget(groupIndex),
                                if (group!.isExpanded)
                                  Column(
                                    children: group.students.map((student) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        child: _studentItemWidget(student),
                                      );
                                    }).toList(),
                                  ),
                              ],
                            );
                          },
                        ),
                      );
                    }
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
          ],
        ),
      ),
      // 浮动添加按钮
      floatingActionButton: FloatingActionButton(
        onPressed: () => {
          showDialog(
            context: context,
            builder: (context) => StudentAddEditDialog(
              student: StudentModel(
                studentName: '',
                studentNumber: '',
                created: DateTime.now(),
              ),
              title: '添加学生',
            ),
          ).then((value) {
            if (value == true) {
              _refreshClassGroupData();
            }
          }),
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<Map<int, StudentClassGroup>> _getAllStudentsByClassNames() async {
    WidgetsFlutterBinding.ensureInitialized(); // 确保初始化Flutter绑定。对于插件很重要。
    var studentDao = StudentDao(); // 创建StudentDao实例。
    Map<int, StudentClassGroup> classGroups = {};
    final List<StudentClassModel> studentClasses = [];
    // 获取所有班级数据
    WidgetsFlutterBinding.ensureInitialized(); // 确保初始化Flutter绑定。对于插件很重要。
    var classDao = StudentClassDao(); // 创建StudentClassDao实例。
    await classDao.getAllStudentClasses().then(
      (value) => studentClasses.addAll(value),
    );
    for (StudentClassModel classModel in studentClasses) {
      List<StudentModel> students = [];
      List<int> studentIds = await StudentClassRelationDao()
          .getAllStudentIdsByClassId(classModel.id!);
      for (int studentId in studentIds) {
        var student = await studentDao.getStudentById(studentId);
        // 添加学生班级信息
        var classIds = await StudentClassRelationDao()
            .getAllClassIdsByStudentId(studentId);
        for (int classId in classIds) {
          student!.classesMap[classId] = await classDao.getStudentClass(classId);
        }
        if (student != null) {
          students.add(student);
        }
      }
      StudentClassGroup classGroup = StudentClassGroup(
        studentClass: classModel,
        students: students,
      );
      classGroups[classModel.id!] = classGroup;
    }
    // 查询有的学生没有班级
    // 所有学生
    var allStudents = await studentDao.getAllStudents();
    // 所有有班级学生
    var allStudentClassIds = Set.from(
      await StudentClassRelationDao().getAllStudentIds(),
    );
    allStudents.removeWhere(
      (student) => allStudentClassIds.contains(student.id),
    );

    var studentClass = StudentClassModel(
      className: '无班级学生',
      studentQuantity: allStudents.length,
      teacherName: '',
      notes: '',
      classQuantity: allStudents.length,
      created: DateTime.now(),
    );
    studentClass.id = -1;
    StudentClassGroup classGroup = StudentClassGroup(
      studentClass: studentClass,
      students: allStudents,
    );
    classGroups[-1] = classGroup;
    _filterClassGroups = classGroups;
    return classGroups;
  }

  @override
  dispose() {
    studentNumberController.dispose();
    studentNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _refreshClassGroupData() async {
    setState(() {
      _classGroupsFuture = _getAllStudentsByClassNames();
    });
  }

  void _onRefresh() async {
    _refreshClassGroupData();
    // 刷新完成
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    // _refreshClassGroupData();
    // 加载完成
    _refreshController.loadComplete();
  }

  Expanded _searchWidget() => Expanded(
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: '搜索学号或姓名...',
          hintStyle: TextStyle(fontSize: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 4,
          ),
          filled: true,
        ),
      ),
    ),
  );

  GestureDetector _classTitleWidget(int groupIndex) {
    StudentClassGroup group =
        _filterClassGroups![_filterClassGroups?.keys.toList()[groupIndex]]!;
    return GestureDetector(
      onTap: () => setState(() {
        _filterClassGroups![_filterClassGroups!.keys.toList()[groupIndex]]!
                .isExpanded =
            !_filterClassGroups![_filterClassGroups!.keys.toList()[groupIndex]]!
                .isExpanded;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              group.studentClass.className,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${group.students.length}人',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _studentItemWidget(StudentModel student) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      student.studentName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        student.studentNumber,
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '创建时间: ${'${student.created.year}-${student.created.month.toString().padLeft(2, '0')}-${student.created.day.toString().padLeft(2, '0')}'}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, color: Colors.grey),
                onPressed: () {
                  // 查看功能
                  showDialog(
                    context: context,
                    builder: (context) => StudentViewDialog(student: student),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.grey),
                onPressed: () {
                  // 编辑功能
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return StudentAddEditDialog(
                        student: student,
                        title: '编辑学生',
                      );
                    },
                  ).then((value) {
                    if (value == true) {
                      _refreshClassGroupData();
                    }
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.grey),
                onPressed: () {
                  // 删除功能
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('确认删除'),
                      content: const Text('确定删除该学生吗？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () async {
                            // 校验是否有随机点名记录
                            RandomCallRecordDao randomCallRecordDao =
                                RandomCallRecordDao();
                            var randomCallRecords = await randomCallRecordDao
                                .getRandomCallRecordsByStudentId(student.id!);
                            // 校验是否有签到点名记录
                            AttendanceCallRecordDao attendanceCallRecordDao =
                                AttendanceCallRecordDao();
                            var attendanceCallRecords =
                                await attendanceCallRecordDao
                                    .getAttendanceCallRecordsByStudentId(
                                      student.id!,
                                    );
                            if (randomCallRecords.isNotEmpty ||
                                attendanceCallRecords.isNotEmpty) {
                              // 有随机点名记录，提示用户先删除随机点名记录
                              Fluttertoast.showToast(
                                msg:
                                    '该学生下有随机点名记录或签到点名记录，无法删除。请先删除该学生下的所有随机点名记录或签到点名记录。',
                              );
                              return;
                            }
                            await StudentDao().deleteStudentById(student.id);
                            if (context.mounted) {
                              // 刷新学生列表
                              _refreshClassGroupData();
                              Navigator.of(context).pop();
                            }
                          },
                          child: const Text('删除'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _importStudentsFromExcel() async {
    try {
      // 选择Excel文件
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      if (result == null) return; // 用户取消选择
      // 读取文件
      var bytes = File(result.files.single.path!).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);
      int totalCount = 0;
      // 解析学生工作表
      for (var table in excel.tables.keys) {
        // 读取第一列，确认 学号	姓名	班级 行号
        var firstColumn = excel.tables[table]!.rows[0];
        // 确认 学号	姓名	班级 行号
        int studentNumberIndex = -1;
        int nameIndex = -1;
        int classNameIndex = -1;
        for (var i = 0; i < firstColumn.length; i++) {
          if (firstColumn[i]?.value?.toString() == '学号') {
            studentNumberIndex = i;
          } else if (firstColumn[i]?.value?.toString() == '姓名') {
            nameIndex = i;
          } else if (firstColumn[i]?.value?.toString() == '班级') {
            classNameIndex = i;
          }
        }
        // 从第2行开始读取学生数据
        for (var row in excel.tables[table]!.rows.skip(1)) {
          String studentNumber =
              row[studentNumberIndex]?.value?.toString() ?? '';
          String name = row[nameIndex]?.value?.toString() ?? '';
          String className = row[classNameIndex]?.value?.toString() ?? '';
          if (studentNumber.isEmpty || name.isEmpty || className.isEmpty) {
            // 如果有为空的信息
            continue;
          }
          // 确保班级存在
          int classId = -1;
          var studentClass = await StudentClassDao().getStudentClassByClassName(
            className,
          );
          if (studentClass == null) {
            // 班级不存在，创建新班级
            studentClass = StudentClassModel(
              className: className,
              created: DateTime.now(),
              studentQuantity: 0,
              teacherName: '',
              notes: '',
            );
            classId = await StudentClassDao().insertStudentClass(studentClass);
          } else {
            classId = studentClass.id!;
          }
          // 判断学生是否存在
          if (await StudentDao().isStudentNumberExist(studentNumber)) {
            // 获取学生信息
            var student = await StudentDao().getStudentByStudentNumber(
              studentNumber,
            );
            // 确认学生班级不包含该班级
            if (await StudentClassRelationDao().isStudentClassRelationExist(
              student?.id!,
              classId,
            )) {
              // 如果存在，跳过
              continue;
            }
            // 更新学生班级关系信息
            await StudentClassRelationDao().insertStudentClassRelation({
              'student_id': student?.id!,
              'class_id': classId,
            });
          } else {
            // 创建新学生
            var student = StudentModel(
              studentNumber: studentNumber,
              studentName: name,
              created: DateTime.now(),
            );
            int studentId = await StudentDao().insertStudent(student);
            // 更新学生班级关系信息
            await StudentClassRelationDao().insertStudentClassRelation({
              'student_id': studentId,
              'class_id': classId,
            });
          }
          totalCount++;
        }
      }
      Fluttertoast.showToast(msg: '成功导入 $totalCount 个学生');
      _refreshClassGroupData();
    } catch (e) {
      Fluttertoast.showToast(msg: '导入学生错误：${e.toString()}');
    }
  }
}
