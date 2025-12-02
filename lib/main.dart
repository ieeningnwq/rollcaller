import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:rollcall/providers/student_class_provider.dart';
import './configs/color.dart';
import './pages/index.dart';
import './providers/current_index_provider.dart';
import 'providers/class_selected_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CurrentIndexProvider>(
          create: (_) => CurrentIndexProvider(),
        ),
        ChangeNotifierProvider<StudentClassProvider>(
          create: (_) => StudentClassProvider(),
        ),
        ChangeNotifierProvider<StudentClassSelectedProvider>(
          create: (_) => StudentClassSelectedProvider(),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(480, 954),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp(
          // title: KString.appTitle, // 点名
          debugShowCheckedModeBanner: false,
          // 定制主题
          theme: ThemeData(colorScheme: .fromSeed(seedColor: KColor.seedColor)),
          home: IndexPage(),
        );
      },
    );
  }
}
