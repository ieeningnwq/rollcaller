import 'package:flutter/material.dart';

void main() {
  runApp(const AddStudentApp());
}

class AddStudentApp extends StatelessWidget {
  const AddStudentApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '添加学生',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const AddStudentScreen(),
    );
  }
}

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({Key? key}) : super(key: key);

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _studentIdController = TextEditingController();
  final _studentNameController = TextEditingController();
  final List<String> _classOptions = [
    '一年级一班',
    '一年级二班',
    '二年级一班',
    '二年级二班',
    '三年级一班',
  ];
  final List<bool> _selectedClasses = List<bool>.filled(5, false);

  @override
  void dispose() {
    _studentIdController.dispose();
    _studentNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加学生'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 学号输入框
            const Text('学号', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _studentIdController,
              decoration: InputDecoration(
                hintText: '请输入学号',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 姓名输入框
            const Text('姓名', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _studentNameController,
              decoration: InputDecoration(
                hintText: '请输入姓名',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 班级选择
            const Text('所在班级', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Column(
              children: List.generate(_classOptions.length, (index) {
                return CheckboxListTile(
                  title: Text(_classOptions[index]),
                  value: _selectedClasses[index],
                  onChanged: (value) {
                    setState(() {
                      _selectedClasses[index] = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              }),
            ),
            const SizedBox(height: 40),

            // 按钮区域
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // 取消按钮逻辑
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '取消',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // 保存按钮逻辑
                      final studentId = _studentIdController.text;
                      final studentName = _studentNameController.text;
                      final selectedClasses = _classOptions
                          .where(
                            (index) =>
                                _selectedClasses[_classOptions.indexOf(index)],
                          )
                          .toList();
                      print('学号: $studentId');
                      print('姓名: $studentName');
                      print('选择的班级: $selectedClasses');
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '保存',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
