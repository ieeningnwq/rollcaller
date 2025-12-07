import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/random_caller_group.dart';
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

  @override
  void initState() {
    super.initState();
    // 初始化动画控制器 - 速度更快
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
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
              // int index = _random.nextInt(_students.length);
              // _currentStudent = _students[index];
            });
          }
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RandomCallerGroupModel>(
      future: Provider.of<RandomCallerProvider>(
        context,
        listen: false,
      ).getSelectorCallerClassStudents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('No random caller found.'));
        } else {
          final randomCaller = snapshot.data!;
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Text(
              randomCaller.toString(),
              style: const TextStyle(
                fontSize: 10.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }
      },
    );
  }
}
