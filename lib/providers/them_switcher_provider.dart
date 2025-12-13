import 'package:flutter/material.dart'
    show ChangeNotifier, ThemeData, ThemeMode, Colors, Brightness, ColorScheme;

class ThemeSwitcherProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeData _theme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
  );
  ThemeData _darkTheme= ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
  );

  ThemeMode get themeMode => _themeMode;

  ThemeData get theme => _theme;
  ThemeData get darkTheme => _darkTheme;

  void setThemeMode(ThemeMode themeMode) {
    _themeMode = themeMode;
    notifyListeners();
  }

  void setTheme(ThemeData theme) {
    _theme = theme;
    notifyListeners();
  }

  void setDarkTheme(ThemeData darkTheme) {
    _darkTheme = darkTheme;
    notifyListeners();
  }





}
