import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../configs/strings.dart';
import 'attendence_page.dart';
import 'random_call_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 0表示随机点名，1表示签到点名
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部标题栏
              Container(
                padding:  EdgeInsets.all(12.w),
                child: Text(
                  KString.homeAppBarTitle,
                  style: Theme.of(context).textTheme.headlineLarge,
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
              _selectedIndex == 0 ? RandomCallPage() : AttendencePage(),
            ],
          ),
        ),
      ),
    );
  }

  Expanded _buildRandomRollCallButton() {
    return Expanded(
      flex: 1,
      child: Container(
        margin: EdgeInsets.only(left: 8.w, right: 4.w),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedIndex = 0;
            });
            // 随机点名功能
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedIndex == 0 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onPrimary,
            foregroundColor: _selectedIndex == 0 ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary,
            side: BorderSide(
              color:  Theme.of(context).colorScheme.onPrimary,
            ),
            padding: EdgeInsets.symmetric(vertical: 12.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0.r),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shuffle,
                size: Theme.of(context).textTheme.titleLarge?.fontSize,
                color: _selectedIndex == 0 ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 8.w),
              Text(
                '随机点名',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _selectedIndex == 0 ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary,
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
        margin: EdgeInsets.only(left: 4.w, right: 8.w),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedIndex = 1;
            });
            // 签到点名功能
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedIndex == 1 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onPrimary,
            foregroundColor: _selectedIndex == 1 ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary,
            side: BorderSide(
              color: _selectedIndex == 1 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onPrimary,
            ),
            padding: EdgeInsets.symmetric(vertical: 12.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0.r),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                size: Theme.of(context).textTheme.titleLarge?.fontSize,
                color: _selectedIndex == 1 ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 8.w),
              Text(
                '签到点名',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _selectedIndex == 1 ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
