// 主题风格枚举
import 'dart:ui' show Color;

import 'package:flutter/material.dart' show Colors, ThemeMode;

enum ThemeStyleOption { red, orange, yellow, green, blue, indigo, purple, diy }

extension ThemeStyleOptionExtension on ThemeStyleOption {
  static Color pickedColor = Colors.white;
  String get name {
    switch (this) {
      case ThemeStyleOption.red:
        return '红色';
      case ThemeStyleOption.orange:
        return '橙色';
      case ThemeStyleOption.yellow:
        return '黄色';
      case ThemeStyleOption.green:
        return '绿色';
      case ThemeStyleOption.blue:
        return '蓝色';
      case ThemeStyleOption.indigo:
        return '青色';
      case ThemeStyleOption.purple:
        return '紫色';
      case ThemeStyleOption.diy:
        return '自定义';
    }
  }

  Color get color {
    switch (this) {
      case ThemeStyleOption.red:
        return Colors.red;
      case ThemeStyleOption.orange:
        return Colors.orange;
      case ThemeStyleOption.yellow:
        return Colors.yellow;
      case ThemeStyleOption.green:
        return Colors.green;
      case ThemeStyleOption.blue:
        return Colors.blue;
      case ThemeStyleOption.indigo:
        return Colors.indigo;
      case ThemeStyleOption.purple:
        return Colors.purple;
      case ThemeStyleOption.diy:
        return pickedColor;
    }
  }

  static ThemeStyleOption fromString(String? value) {
    switch (value) {
      case 'red':
        return ThemeStyleOption.red;
      case 'orange':
        return ThemeStyleOption.orange;
      case 'yellow':
        return ThemeStyleOption.yellow;
      case 'green':
        return ThemeStyleOption.green;
      case 'blue':
        return ThemeStyleOption.blue;
      case 'indigo':
        return ThemeStyleOption.indigo;
      case 'purple':
        return ThemeStyleOption.purple;
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

  
static Color getContrastColor(Color color) {
  double brightness = 0.299 * (color.r * 255.0).round().clamp(0, 255) + 0.587 * (color.g * 255.0).round().clamp(0, 255) + 0.114 * (color.b * 255.0).round().clamp(0, 255); 
  return brightness > 128 ? Colors.black : Colors.white;
}

}
