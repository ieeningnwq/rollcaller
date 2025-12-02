import 'package:flutter/material.dart';

void main() {
  runApp(const StudentListApp());
}

class StudentListApp extends StatelessWidget {
  const StudentListApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '学生名单管理',
      theme: ThemeData(primarySwatch: Colors.purple, useMaterial3: true),
      home: const StudentListScreen(),
    );
  }
}

class Student {
  final String id;
  final String name;
  final String studentId;
  final String className;
  final String createTime;

  Student({
    required this.id,
    required this.name,
    required this.studentId,
    required this.className,
    required this.createTime,
  });
}

class ClassGroup {
  final String className;
  final List<Student> students;
  bool isExpanded;

  ClassGroup({
    required this.className,
    required this.students,
    this.isExpanded = true,
  });
}

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({Key? key}) : super(key: key);

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ClassGroup> _classGroups = [];
  List<ClassGroup> _filteredClassGroups = [];

  @override
  void initState() {
    super.initState();
    // 模拟数据
    _classGroups = [
      ClassGroup(
        className: '一年级一班',
        students: [
          Student(
            id: '1',
            name: '赵萨内',
            studentId: '2019821',
            className: '一年级一班',
            createTime: '2025-12-01',
          ),
          Student(
            id: '2',
            name: '张三',
            studentId: '2024001',
            className: '一年级一班',
            createTime: '2024-09-01',
          ),
          Student(
            id: '3',
            name: '李四',
            studentId: '2024002',
            className: '一年级一班',
            createTime: '2024-09-01',
          ),
        ],
      ),
      ClassGroup(
        className: '一年级二班',
        students: [
          Student(
            id: '4',
            name: '王五',
            studentId: '2024003',
            className: '一年级二班',
            createTime: '2024-09-01',
          ),
          Student(
            id: '5',
            name: '赵六',
            studentId: '2024004',
            className: '一年级二班',
            createTime: '2024-09-02',
          ),
        ],
      ),
      ClassGroup(
        className: '二年级一班',
        students: [
          Student(
            id: '6',
            name: '孙七',
            studentId: '2024005',
            className: '二年级一班',
            createTime: '2024-09-02',
          ),
        ],
      ),
    ];
    _filteredClassGroups = _classGroups;

    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredClassGroups = _classGroups;
      });
      return;
    }

    setState(() {
      _filteredClassGroups = _classGroups
          .map((group) {
            final filteredStudents = group.students.where((student) {
              return student.name.toLowerCase().contains(query) ||
                  student.studentId.toLowerCase().contains(query);
            }).toList();
            return ClassGroup(
              className: group.className,
              students: filteredStudents,
              isExpanded: group.isExpanded,
            );
          })
          .where((group) => group.students.isNotEmpty)
          .toList();
    });
  }

  void _toggleClassExpanded(int index) {
    setState(() {
      _filteredClassGroups[index].isExpanded =
          !_filteredClassGroups[index].isExpanded;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              color: Colors.purple,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '学生名单管理',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '管理学生信息，按班级分组查看',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // 搜索栏
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  hintText: '搜索学号或姓名...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.purple),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),

            // 学生列表
            Expanded(
              child: ListView.builder(
                itemCount: _filteredClassGroups.length,
                itemBuilder: (context, groupIndex) {
                  final group = _filteredClassGroups[groupIndex];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 班级标题（可点击展开/折叠）
                      GestureDetector(
                        onTap: () => _toggleClassExpanded(groupIndex),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          color: const Color(0xFFF5F5F5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                group.className,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${group.students.length}人',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    group.isExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 学生列表（根据展开状态显示/隐藏）
                      if (group.isExpanded)
                        Column(
                          children: group.students.map((student) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // 姓名和学号并排显示
                                          Row(
                                            children: [
                                              Text(
                                                student.name,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.purple
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  student.studentId,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        Colors.purple.shade700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '创建时间: ${student.createTime}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () {
                                            // 编辑功能
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () {
                                            // 删除功能
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // 浮动添加按钮
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 添加功能
        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add),
      ),
    );
  }
}
