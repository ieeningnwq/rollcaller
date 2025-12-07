import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/student_model.dart';
import '../providers/random_caller_provider.dart';

class RandomCallerCallWidget extends StatefulWidget {
  const RandomCallerCallWidget({super.key});

  @override
  State<RandomCallerCallWidget> createState() => _RandomCallerCallWidgetState();
}

class _RandomCallerCallWidgetState extends State<RandomCallerCallWidget>
    with SingleTickerProviderStateMixin {
  // 是否正在抽取
  bool _isPicking = false;
  // 随机数生成器
  final Random _random = Random();
  // 动画控制器
  late AnimationController _controller;
  late Animation<double> _animation;

  StudentModel? _currentStudent;
  List<StudentModel> _students = [];

  @override
  void initState() {
    super.initState();
    // 初始化动画控制器 - 速度更快
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
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
    // 初始化数据
    Provider.of<RandomCallerProvider>(
      context,
      listen: false,
    ).getSelectorCallerClassStudents().then((value) {
      _students = value.students;
      _currentStudent = _students.isNotEmpty
          ? _students[_random.nextInt(_students.length)]
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: [
            // 学生姓名显示
            Text(
              _currentStudent?.studentName ?? '没有学生',
              style: const TextStyle(
                fontSize: 20,
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
                style: const TextStyle(fontSize: 16.0, color: Colors.black54),
              ),
            ),

            const SizedBox(height: 8.0),

            // 开始随机抽取按钮
            SizedBox(
              width: double.infinity,
              height: 40.0,
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
        // 评分相关状态
      } else {
        // 开始抽取
        _isPicking = true;
        _controller.forward();
      }
    });
  }

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }
}
