import 'package:flutter/material.dart';

class StudentScoreWidget extends StatefulWidget {
  const StudentScoreWidget({super.key});

  @override
  State<StudentScoreWidget> createState() => _StudentScoreWidgetState();
}

class _StudentScoreWidgetState extends State<StudentScoreWidget> {
  int _score = 5;

  @override
  Widget build(BuildContext context) {
    // 评分组件 - 一直显示
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
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
                  const SizedBox(height: 8.0),
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
              const SizedBox(height: 8.0),

              // 评分按钮组
              SizedBox(
                width: double.infinity,
                height: 40.0,
                child: ElevatedButton(
                  onPressed: () => {},
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
    );
  }
}
