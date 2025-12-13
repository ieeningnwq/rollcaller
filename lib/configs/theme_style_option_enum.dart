// 主题风格枚举
import 'package:flutter/material.dart'
    show Colors, ThemeMode, ThemeData, MaterialColor, TextTheme, FontWeight, TextStyle, Brightness;
import 'package:flutter_screenutil/flutter_screenutil.dart' show SizeExtension;

enum ThemeStyleOption { blue, purple, green, orange, diy }

extension ThemeStyleOptionExtension on ThemeStyleOption {
  static MaterialColor pickedColor = Colors.blue;
  String get name {
    switch (this) {
      case ThemeStyleOption.blue:
        return '蓝色';
      case ThemeStyleOption.purple:
        return '紫色';
      case ThemeStyleOption.green:
        return '绿色';
      case ThemeStyleOption.orange:
        return '橙色';
      case ThemeStyleOption.diy:
        return '自定义';
    }
  }

  MaterialColor get color {
    switch (this) {
      case ThemeStyleOption.blue:
        return Colors.blue;
      case ThemeStyleOption.purple:
        return Colors.purple;
      case ThemeStyleOption.green:
        return Colors.green;
      case ThemeStyleOption.orange:
        return Colors.orange;
      case ThemeStyleOption.diy:
        return pickedColor;
    }
  }

  static ThemeStyleOption fromString(String? value) {
    switch (value) {
      case 'blue':
        return ThemeStyleOption.blue;
      case 'purple':
        return ThemeStyleOption.purple;
      case 'green':
        return ThemeStyleOption.green;
      case 'orange':
        return ThemeStyleOption.orange;
      case 'diy':
        return ThemeStyleOption.diy;
      default:
        return ThemeStyleOption.blue;
    }
  }

  static ThemeMode fromStringToThemeMode(String value) {
    switch (value) {
      case 'system':
        return ThemeMode.system;
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static ThemeData getDarkThemeData(ThemeStyleOption themeStyleOption) => ThemeData(
        brightness: Brightness.dark,
        primarySwatch: themeStyleOption.color,
        textTheme: textTheme,
      );

  static ThemeData getLightThemeData(ThemeStyleOption themeStyleOption) => ThemeData(
        brightness: Brightness.light,
        primarySwatch: themeStyleOption.color,
        textTheme: textTheme,
      );


  static TextTheme get textTheme => TextTheme(
    headlineLarge: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
    headlineSmall: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
    titleLarge: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.bold),
    titleMedium: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
    titleSmall: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
    bodyLarge: TextStyle(fontSize: 24.sp),
    bodyMedium: TextStyle(fontSize: 22.sp),
    bodySmall: TextStyle(fontSize: 20.sp),
    labelLarge: TextStyle(fontSize: 22.sp),
    labelMedium: TextStyle(fontSize: 18.sp),
    labelSmall: TextStyle(fontSize: 16.sp),
  );
}
