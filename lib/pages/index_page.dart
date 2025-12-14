import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../configs/strings.dart';
import 'home_page.dart';
import 'records_page.dart';
import 'settings_page.dart';
import 'student_class_page.dart';
import '../providers/current_index_provider.dart';
import 'student_page.dart';

class IndexPage extends StatelessWidget {
  const IndexPage({super.key});

  static const List<BottomNavigationBarItem> bottomTabs = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: KString.homeTitle, // 首页
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.group),
      label: KString.studentClassTitle, // 班级
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: KString.studentTitle, // 学生
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.access_time),
      label: KString.recordsTitle, // 记录
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: KString.settingsTitle, // 设置
    ),
  ];
  static const List<Widget> tabBodies = [
    HomePage(),
    StudentClassPage(),
    StudentPage(),
    RecordPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentIndexProvider>(
      builder:
          (
            BuildContext context,
            CurrentIndexProvider currentIndexProvider,
            Widget? child,
          ) {
            final int currentIndex = currentIndexProvider.currentIndex;
            return Scaffold(
              bottomNavigationBar: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: currentIndex,
                items: bottomTabs,
                onTap: (index) => {currentIndexProvider.currentIndex = index},
              ),
              body: tabBodies[currentIndex],
            );
          },
    );
  }
}
