import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 学生模型
class Student {
  final String name;
  final String studentId;
  AttendanceStatus status;

  Student({
    required this.name,
    required this.studentId,
    this.status = AttendanceStatus.absent,
  });
}

// 签到状态枚举
enum AttendanceStatus {
  present, // 已签到
  late,    // 迟到
  excused, // 请假
  absent,  // 未签到
}

// 签到状态扩展
extension AttendanceStatusExtension on AttendanceStatus {
  String get statusText {
    switch (this) {
      case AttendanceStatus.present:
        return '已签到';
      case AttendanceStatus.late:
        return '迟到';
      case AttendanceStatus.excused:
        return '请假';
      case AttendanceStatus.absent:
        return '未签到';
    }
  }

  Color get statusColor {
    switch (this) {
      case AttendanceStatus.present:
        return const Color(0xFF81C784); // 绿色
      case AttendanceStatus.late:
        return const Color(0xFFFFD54F); // 黄色
      case AttendanceStatus.excused:
        return const Color(0xFF64B5F6); // 蓝色
      case AttendanceStatus.absent:
        return const Color(0xFFEF5350); // 红色
    }
  }
}

class StudentAttendanceManager extends StatelessWidget {
  const StudentAttendanceManager({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(480, 954),
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: '学生签到管理',
          theme: ThemeData(
            primarySwatch: Colors.purple,
            textTheme: TextTheme(
              bodyLarge: TextStyle(fontSize: 16.sp),
              bodyMedium: TextStyle(fontSize: 14.sp),
            ),
          ),
          home: const StudentAttendancePage(),
        );
      },
    );
  }
}

class StudentAttendancePage extends StatefulWidget {
  const StudentAttendancePage({Key? key}) : super(key: key);

  @override
  State<StudentAttendancePage> createState() => _StudentAttendancePageState();
}

class _StudentAttendancePageState extends State<StudentAttendancePage> {
  final TextEditingController _searchController = TextEditingController();
  List<Student> _students = [];
  List<Student> _filteredStudents = [];

  // 初始化学生数据
  @override
  void initState() {
    super.initState();
    _initializeStudents();
    _sortStudents();
    _filteredStudents = _students;
  }

  // 模拟学生数据
  void _initializeStudents() {
    _students = List.generate(45, (index) {
      // 随机生成签到状态
      final statuses = [
        AttendanceStatus.present,
        AttendanceStatus.late,
        AttendanceStatus.excused,
        AttendanceStatus.absent,
      ];
      // 大部分学生已签到
      final randomIndex = index < 36 
          ? 0 
          : (index < 39 ? 1 : (index < 42 ? 2 : 3));
      
      return Student(
        name: '学生${index + 1}',
        studentId: '2021${(index + 1).toString().padLeft(4, '0')}',
        status: statuses[randomIndex],
      );
    });
    
    // 添加几个具体姓名的学生以便测试
    _students[0] = Student(name: '张三', studentId: '2021001', status: AttendanceStatus.present);
    _students[1] = Student(name: '李四', studentId: '2021002', status: AttendanceStatus.late);
    _students[2] = Student(name: '王五', studentId: '2021003', status: AttendanceStatus.excused);
    _students[3] = Student(name: '赵六', studentId: '2021004', status: AttendanceStatus.absent);
    _students[4] = Student(name: '钱七', studentId: '2021005', status: AttendanceStatus.absent);
  }

  // 学生排序方法：按学号排序
  void _sortStudents() {
    _students.sort((a, b) {
      // 直接按学号排序
      return a.studentId.compareTo(b.studentId);
    });
  }

  // 搜索学生
  void _searchStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = _students;
      } else {
        _filteredStudents = _students.where((student) {
          return student.name.contains(query) || student.studentId.contains(query);
        }).toList();
        // 搜索结果按学号排序
        _filteredStudents.sort((a, b) {
          // 直接按学号排序
          return a.studentId.compareTo(b.studentId);
        });
      }
    });
  }

  // 切换签到状态
  void _toggleAttendanceStatus(int index) {
    setState(() {
      final currentStatus = _filteredStudents[index].status;
      final statuses = [
        AttendanceStatus.present,
        AttendanceStatus.late,
        AttendanceStatus.excused,
        AttendanceStatus.absent,
      ];
      final currentIndex = statuses.indexOf(currentStatus);
      final nextIndex = (currentIndex + 1) % statuses.length;
      
      // 获取当前学生的学号用于后续查找
      final studentId = _filteredStudents[index].studentId;
      
      // 更新原始列表中的状态
      final originalIndex = _students.indexWhere(
        (s) => s.studentId == studentId
      );
      if (originalIndex != -1) {
        _students[originalIndex].status = statuses[nextIndex];
        
        // 重新排序原始列表
        _sortStudents();
        
        // 更新筛选列表
        if (_searchController.text.isEmpty) {
          _filteredStudents = _students;
        } else {
          _filteredStudents = _students.where((student) {
            return student.name.contains(_searchController.text) || 
                   student.studentId.contains(_searchController.text);
          }).toList();
          // 搜索结果重新按学号排序
          _filteredStudents.sort((a, b) {
            // 直接按学号排序
            return a.studentId.compareTo(b.studentId);
          });
        }
      }
    });
  }

  // 保存签到记录
  void _saveAttendanceRecords() {
    // 这里可以实现保存逻辑，比如保存到本地存储或发送到服务器
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('签到记录已保存')),
    );
  }

  // 获取签到统计数据
  Map<AttendanceStatus, int> _getAttendanceStats() {
    final stats = {
      AttendanceStatus.present: 0,
      AttendanceStatus.late: 0,
      AttendanceStatus.excused: 0,
      AttendanceStatus.absent: 0,
    };
    
    for (final student in _students) {
      stats[student.status] = (stats[student.status] ?? 0) + 1;
    }
    
    return stats;
  }

  @override
  Widget build(BuildContext context) {
    final stats = _getAttendanceStats();
    final presentCount = stats[AttendanceStatus.present] ?? 0;
    final totalCount = _students.length;
    final attendanceRate = totalCount > 0 ? (presentCount / totalCount) * 100 : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          // 主容器使用Column
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 搜索框 - 固定在顶部
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _searchStudents,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: '搜索学生',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12.w),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // 签到状态列表 - 扩展以填充剩余空间
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 标题行 - 固定在顶部
                      Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '签到状态',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  '共${totalCount}人',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            // 保存按钮
                            SizedBox(
                              height: 32.h,
                              child: ElevatedButton(
                                onPressed: _saveAttendanceRecords,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6200EE),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 4.h,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.save, size: 16),
                                    SizedBox(width: 4.w),
                                    Text(
                                      '保存',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                        
                      // 学生列表 - 可滚动
                      Expanded(
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = _filteredStudents[index];
                            return Column(
                              children: [
                                ListTile(
                                  onTap: () => _toggleAttendanceStatus(index),
                                  title: Text(
                                    student.name,
                                    style: TextStyle(fontSize: 16.sp),
                                  ),
                                  subtitle: Text(
                                    '学号: ${student.studentId}',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  trailing: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: student.status.statusColor,
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Text(
                                      student.status.statusText,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                if (index < _filteredStudents.length - 1)
                                  Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // 签到统计 - 固定在底部
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题和出勤率
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '签到统计',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${attendanceRate.round()}%',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: const Color(0xFF6200EE),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),

                      // 进度条
                      Container(
                        height: 8.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: FractionallySizedBox(
                          widthFactor: attendanceRate / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF6200EE),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // 各状态统计
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: stats.entries.map((entry) {
                          return Row(
                            children: [
                              Container(
                                width: 12.w,
                                height: 12.h,
                                decoration: BoxDecoration(
                                  color: entry.key.statusColor,
                                  borderRadius: BorderRadius.circular(2.r),
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '${entry.key.statusText}',
                                style: TextStyle(fontSize: 12.sp),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '${entry.value}',
                                style: TextStyle(fontSize: 12.sp),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(const StudentAttendanceManager());
}