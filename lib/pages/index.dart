import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../configs/strings.dart';
import '../pages/home.dart';
import '../pages/record.dart';
import '../pages/settings.dart';
import '../pages/student_class.dart';
import '../providers/current_index_provider.dart';

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
              body: IndexedStack(index: currentIndex, children: tabBodies),
            );
          },
    );
  }
}
