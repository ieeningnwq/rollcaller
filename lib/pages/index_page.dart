import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../configs/strings.dart';
import 'home_page.dart';
import 'records.dart';
import '../pages/settings.dart';
import 'student_class_page.dart';
import '../providers/current_index_provider.dart';
import 'student_page.dart';

class IndexPage extends StatelessWidget {
  const IndexPage({super.key});

  static const List<BottomNavigationBarItem> bottomTabs = [
    BottomNavigationBarItem(
      icon: FaIcon(FontAwesomeIcons.house),
      label: KString.homeTitle, // 首页
    ),
    BottomNavigationBarItem(
      icon: FaIcon(FontAwesomeIcons.users),
      label: KString.studentClassTitle, // 班级
    ),
    BottomNavigationBarItem(
      icon: FaIcon(FontAwesomeIcons.user),
      label: KString.studentTitle, // 学生
    ),
    BottomNavigationBarItem(
      icon: FaIcon(FontAwesomeIcons.clockRotateLeft),
      label: KString.recordTitle, // 记录
    ),
    BottomNavigationBarItem(
      icon: FaIcon(FontAwesomeIcons.gear),
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
                onTap: (index) => {currentIndexProvider.changeIndex(index)},
              ),
              body: tabBodies[currentIndex],
            );
          },
    );
  }
}
