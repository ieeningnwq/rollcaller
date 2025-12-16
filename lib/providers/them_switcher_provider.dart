import 'package:flutter/material.dart'
    show
        Brightness,
        ChangeNotifier,
        ColorScheme,
        FontWeight,
        TextStyle,
        TextTheme,
        ThemeData,
        ThemeMode,
        Colors;
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../configs/theme_style_option_enum.dart';

class ThemeSwitcherProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeStyleOption _themeStyle = ThemeStyleOption.blue;

  ThemeMode get themeMode => _themeMode;
  ThemeStyleOption get themeStyle => _themeStyle;

  ThemeData? get theme =>
      _themeDataMap[_themeStyle]![Brightness.light];
  ThemeData? get darkTheme =>
      _themeDataMap[_themeStyle]![Brightness.dark];

  // 主题数据
  static final TextTheme textTheme = TextTheme(
    headlineLarge: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold),
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
  static final _themeDataMap = {
    ThemeStyleOption.blue: {
      Brightness.light: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        textTheme: textTheme,
      ),
      Brightness.dark: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        textTheme: textTheme,   
      ),
    },
    ThemeStyleOption.red: {
      Brightness.light: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.light,
        ),
        textTheme: textTheme,
      ),
      Brightness.dark: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
        textTheme: textTheme,
      ),
    },
    ThemeStyleOption.green: {
      Brightness.light: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        textTheme: textTheme,
      ),
      Brightness.dark: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        textTheme: textTheme,
      ),
    },
    ThemeStyleOption.yellow: {
      Brightness.light: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.yellow,
          brightness: Brightness.light,
        ),
        textTheme: textTheme,
      ),
      Brightness.dark: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.yellow,
          brightness: Brightness.dark,
        ),
        textTheme: textTheme,
      ),
    },
    ThemeStyleOption.purple: {
      Brightness.light: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.light,
        ),
        textTheme: textTheme,
      ),
      Brightness.dark: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.dark,
        ),
        textTheme: textTheme,
      ),
    },
    ThemeStyleOption.orange: {
      Brightness.light: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.light,
        ),
        textTheme: textTheme,
      ),
      Brightness.dark: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.dark,
        ),
        textTheme: textTheme,
      ),
    },
    ThemeStyleOption.indigo: {
      Brightness.light: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        textTheme: textTheme,
      ),
      Brightness.dark: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        textTheme: textTheme,
      ),
    },
    ThemeStyleOption.diy: {
      Brightness.light: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ThemeStyleOption.diy.color,
          brightness: Brightness.light,
        ),
        textTheme: textTheme,
      ),
      Brightness.dark: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ThemeStyleOption.diy.color,
          brightness: Brightness.dark,
        ),
        textTheme: textTheme,
      ),
    },
  };

  void setThemeMode(ThemeMode themeMode) {
    _themeMode = themeMode;
    notifyListeners();
  }

  void setThemeStyle(ThemeStyleOption themeStyle) {
    _themeStyle = themeStyle;
    if (themeStyle == ThemeStyleOption.diy) {
      _updateDiyThemeData();
    }
    notifyListeners();
  }

  void _updateDiyThemeData() {
    _themeDataMap[ThemeStyleOption.diy]![Brightness.light] = ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ThemeStyleOption.diy.color,
        brightness: Brightness.light,
      ),
      textTheme: textTheme,
    );
    _themeDataMap[ThemeStyleOption.diy]![Brightness.dark] = ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ThemeStyleOption.diy.color,
        brightness: Brightness.dark,
      ),
      textTheme: textTheme, 
    );
  }

  void setModelAndStyle(ThemeMode themeMode, ThemeStyleOption themeStyle) {
    _themeMode = themeMode;
    _themeStyle = themeStyle;
    if (themeStyle == ThemeStyleOption.diy) {
      _updateDiyThemeData();
    }

    notifyListeners();
  }

  void setModelAndStyleWithoutNotify(ThemeMode themeMode, ThemeStyleOption themeStyle) {
    _themeMode = themeMode;
    _themeStyle = themeStyle;
    if (themeStyle == ThemeStyleOption.diy) {
      _updateDiyThemeData();
    }
  }
}
