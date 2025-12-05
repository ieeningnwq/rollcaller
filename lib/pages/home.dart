import 'package:flutter/material.dart';

import '../configs/strings.dart';
import '../models/roll_caller_model.dart';
import '../widgets/roll_caller_add_edit_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 0表示随机点名，1表示签到点名
  int _selectedIndex = 0;

  // 点名器名称控制器
  final TextEditingController _randomCallerNameController = TextEditingController();
  // 点名器备注控制器
  final TextEditingController _notesController = TextEditingController();

  // 班级列表
  final List<String> _classes = [
    '高三(1)班',
    '高三(2)班',
    '高三(3)班',
    '高二(1)班',
    '高二(2)班',
    '高一(1)班',
  ];

  // 当前选中的班级
  String _selectedClass = '高三(1)班';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text(KString.homeAppBarTitle)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部标题栏
            Container(
              padding: const EdgeInsets.all(12),
              child: Text(
                KString.homeAppBarTitle,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 随机点名按钮
                _buildRandomRollCallButton(),
                _buildAttendenceButton(),
              ],
            ),
            Container(
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
                      IconButton(
                        onPressed: () => {
                          // 新增点名器功能
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return RollCallerAddEditDialog(
                                title: '添加点名器',
                                rollCaller: RollCallerModel(
                                  classId: -1,
                                  randomCallerName: '',
                                  notes: '',
                                  created: DateTime.now(),
                                ),
                                randomCallerNameController: _randomCallerNameController,
                                notesController: _notesController,
                              );
                            },
                          ),
                        },
                        icon: Icon(Icons.add, color: Colors.green),
                      ),
                      IconButton(
                        onPressed: () {
                          // 管理班级功能
                        },
                        icon: const Icon(Icons.edit, color: Colors.blue),
                      ),
                      IconButton(
                        onPressed: () {
                          // 管理班级功能
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 班级下拉选择框
                  DropdownButtonFormField<String>(
                    initialValue: _selectedClass,
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
                    items: _classes.map((String className) {
                      return DropdownMenuItem<String>(
                        value: className,
                        child: Text(className),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedClass = newValue;
                        });
                      }
                    },
                    style: const TextStyle(fontSize: 16.0, color: Colors.black),
                    dropdownColor: Colors.white,
                    icon: const Icon(Icons.arrow_drop_down),
                    iconSize: 24.0,
                    iconEnabledColor: Colors.grey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Expanded _buildRandomRollCallButton() {
    return Expanded(
      flex: 1,
      child: Container(
        margin: const EdgeInsets.only(left: 4, right: 3),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedIndex = 0;
            });
            // 随机点名功能
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedIndex == 0 ? Colors.blue : Colors.white,
            foregroundColor: _selectedIndex == 0 ? Colors.white : Colors.blue,
            side: BorderSide(
              color: _selectedIndex == 0 ? Colors.blue : Colors.blue,
            ),
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shuffle,
                color: _selectedIndex == 0 ? Colors.white : Colors.blue,
              ),
              const SizedBox(width: 8.0),
              Text(
                '随机点名',
                style: TextStyle(
                  fontSize: 16.0,
                  color: _selectedIndex == 0 ? Colors.white : Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Expanded _buildAttendenceButton() {
    return Expanded(
      flex: 1,
      child: Container(
        margin: const EdgeInsets.only(left: 3, right: 4),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedIndex = 1;
            });
            // 签到点名功能
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedIndex == 1 ? Colors.blue : Colors.white,
            foregroundColor: _selectedIndex == 1 ? Colors.white : Colors.blue,
            side: BorderSide(
              color: _selectedIndex == 1 ? Colors.blue : Colors.blue,
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                color: _selectedIndex == 1 ? Colors.white : Colors.blue,
              ),
              const SizedBox(width: 8.0),
              Text(
                '签到点名',
                style: TextStyle(
                  fontSize: 16.0,
                  color: _selectedIndex == 1 ? Colors.white : Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _randomCallerNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
