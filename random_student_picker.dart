import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const RandomStudentPickerApp());
}

class RandomStudentPickerApp extends StatelessWidget {
  const RandomStudentPickerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '随机抽取学生',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const RandomStudentPickerScreen(),
    );
  }
}

class RandomStudentPickerScreen extends StatefulWidget {
  const RandomStudentPickerScreen({super.key});

  @override
  State<RandomStudentPickerScreen> createState() => _RandomStudentPickerScreenState();
}

class _RandomStudentPickerScreenState extends State<RandomStudentPickerScreen> with SingleTickerProviderStateMixin {
  // 学生数据列表，添加抽取次数字段和评分记录
  final List<Map<String, dynamic>> _students = [
    {'name': '吴十', 'id': '20230101', 'pickCount': 0, 'scores': []},
    {'name': '张三', 'id': '20230102', 'pickCount': 0, 'scores': []},
    {'name': '李四', 'id': '20230103', 'pickCount': 0, 'scores': []},
    {'name': '王五', 'id': '20230104', 'pickCount': 0, 'scores': []},
    {'name': '赵六', 'id': '20230105', 'pickCount': 0, 'scores': []},
    {'name': '孙七', 'id': '20230106', 'pickCount': 0, 'scores': []},
    {'name': '周八', 'id': '20230107', 'pickCount': 0, 'scores': []},
    {'name': '郑九', 'id': '20230108', 'pickCount': 0, 'scores': []},
    {'name': '钱一', 'id': '20230109', 'pickCount': 0, 'scores': []},
    {'name': '孙二', 'id': '20230110', 'pickCount': 0, 'scores': []},
  ];

  // 当前选中的学生
  late Map<String, dynamic> _currentStudent;
  
  // 动画控制器
  late AnimationController _controller;
  late Animation<double> _animation;
  
  // 是否正在抽取
  bool _isPicking = false;
  
  // 随机数生成器
  final Random _random = Random();
  
  // 评分相关状态
  int _score = 5; // 默认分数5分
  
  // 滚动控制器，用于点击学生后滚动到抽取区域
  final ScrollController _scrollController = ScrollController();
  
  // 学生组折叠状态
  bool _isPickedGroupExpanded = true; // 已抽取学生组默认展开
  bool _isUnpickedGroupExpanded = true; // 未抽取学生组默认展开

  @override
  void initState() {
    super.initState();
    
    // 初始选择第一个学生
    _currentStudent = _students[0];
    
    // 初始化动画控制器 - 速度更快
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100), // 从1000毫秒减少到100毫秒
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
              int index = _random.nextInt(_students.length);
              _currentStudent = _students[index];
            });
          }
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose(); // 释放滚动控制器
    super.dispose();
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
  
  // 保存评分
  void _saveScore() {
    setState(() {
      int index = _students.indexOf(_currentStudent);
      // 更新抽取次数
      _students[index]['pickCount']++;
      // 记录本次评分
      _students[index]['scores'].add(_score);
      
      // 保存评分后，重置分数为默认值5分
      _score = 5;
    });
  }
  
  // 计算学生平均分
  double _calculateAverageScore(List<int> scores) {
    if (scores.isEmpty) return 0.0;
    double sum = scores.fold(0, (sum, score) => sum + score);
    return sum / scores.length;
  }

  // 构建学生组列表
  Widget _buildStudentGroup(List<Map<String, dynamic>> students) {
    if (students.isEmpty) {
      return const Text(
        '暂无学生',
        style: TextStyle(
          color: Colors.black54,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    // 对学生进行排序：已抽取学生按抽取次数降序，未抽取学生按学号升序
    students.sort((a, b) {
      if (a['pickCount'] > 0 && b['pickCount'] > 0) {
        // 已抽取学生按抽取次数降序
        return b['pickCount'].compareTo(a['pickCount']);
      } else {
        // 未抽取学生按学号升序
        return a['id'].compareTo(b['id']);
      }
    });

    return Column(
      children: students.map((student) {
        double average = _calculateAverageScore(List<int>.from(student['scores']));
        return GestureDetector(
          onTap: () {
            // 实现手动抽取功能
            setState(() {
              // 设置当前学生为被点击的学生
              _currentStudent = student;
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
                color: student['pickCount'] > 0 ? Color(0xFF6C4AB6) : Colors.grey.shade200,
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
                      student['name'],
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      student['id'],
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
                          '抽取: ${student['pickCount']}次',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: student['pickCount'] > 0 ? Color(0xFF6C4AB6) : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          '平均分: ${average > 0 ? average.toStringAsFixed(1) : '—'}',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: average > 0 ? Color(0xFF6C4AB6) : Colors.black54,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController, // 添加滚动控制器
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // 学生抽取卡片
              Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // 学生姓名显示 - 取消缩放动画
                      Text(
                        _currentStudent['name']!,
                        style: const TextStyle(
                          fontSize: 48.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      
                      const SizedBox(height: 16.0),
                      
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
                          _currentStudent['id']!,
                          style: const TextStyle(
                            fontSize: 18.0,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40.0),
                      
                      // 开始随机抽取按钮
                      SizedBox(
                        width: double.infinity,
                        height: 56.0,
                        child: ElevatedButton(
                          onPressed: _toggleRandomPick,
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
              
              // 评分组件 - 一直显示
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Card(
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
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
                            const SizedBox(height: 12.0),
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
                            const SizedBox(height: 8.0),
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
                        const SizedBox(height: 32.0),
                        
                        // 评分按钮组
                        SizedBox(
                          width: double.infinity,
                          height: 56.0,
                          child: ElevatedButton(
                            onPressed: _saveScore,
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
              ),
              
              // 学生列表卡片 - 按已抽取和未抽取分组
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Card(
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
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
                                _isPickedGroupExpanded ? Icons.expand_less : Icons.expand_more,
                                color: Color(0xFF6C4AB6),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        AnimatedCrossFade(
                          firstChild: Container(height: 0),
                          secondChild: _buildStudentGroup(_students.where((s) => s['pickCount'] > 0).toList()),
                          crossFadeState: _isPickedGroupExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 300),
                          sizeCurve: Curves.easeInOut,
                        ),
                        
                        const SizedBox(height: 24.0),
                        
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
                                _isUnpickedGroupExpanded ? Icons.expand_less : Icons.expand_more,
                                color: Color(0xFF6C4AB6),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        AnimatedCrossFade(
                          firstChild: Container(height: 0),
                          secondChild: _buildStudentGroup(_students.where((s) => s['pickCount'] == 0).toList()),
                          crossFadeState: _isUnpickedGroupExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 300),
                          sizeCurve: Curves.easeInOut,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

