import 'package:flutter/material.dart'
    show
        Brightness,
        ChangeNotifier,
        ColorScheme,
        FontWeight,
        Material,
        TextStyle,
        TextTheme,
        ThemeData,
        ThemeMode;
import 'package:flutter_screenutil/flutter_screenutil.dart' show SizeExtension;
import 'package:rollcall/configs/theme_style_option_enum.dart';

class ThemeSwitcherProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeStyleOption _themeStyle = ThemeStyleOption.blue;

  static final TextTheme _textTheme = TextTheme(
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

  ThemeMode get themeMode => _themeMode;
  ThemeStyleOption get themeStyle => _themeStyle;

  ThemeData get theme => ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _themeStyle.color,
      brightness: Brightness.light,
    ),
    textTheme: _textTheme,
  );
  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _themeStyle.color,
      brightness: Brightness.dark,
    ),
    textTheme: _textTheme,
  );

  void setThemeMode(ThemeMode themeMode) {
    _themeMode = themeMode;
    notifyListeners();
  }

  void setThemeStyle(ThemeStyleOption themeStyle) {
    _themeStyle = themeStyle;
    notifyListeners();
  }

  void setModelAndStyle(ThemeMode themeMode, ThemeStyleOption themeStyle) {
    _themeMode = themeMode;
    _themeStyle = themeStyle;

    notifyListeners();
  }
}
