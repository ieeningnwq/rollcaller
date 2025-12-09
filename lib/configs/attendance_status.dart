import 'dart:ui';
// 签到状态枚举

enum AttendanceStatus {
  present, // 已签到
  late, // 迟到
  excused, // 请假
  absent, // 未签到
}

// 签到状态扩展
extension AttendanceStatusExtension on AttendanceStatus {
  String get statusText {
    switch (this) {
      case AttendanceStatus.present:
        return '已签到';
      case AttendanceStatus.late:
        return '迟到';
      case AttendanceStatus.excused:
        return '请假';
      case AttendanceStatus.absent:
        return '未签到';
    }
  }

  Color get statusColor {
    switch (this) {
      case AttendanceStatus.present:
        return const Color(0xFF81C784); // 绿色
      case AttendanceStatus.late:
        return const Color(0xFFFFD54F); // 黄色
      case AttendanceStatus.excused:
        return const Color(0xFF64B5F6); // 蓝色
      case AttendanceStatus.absent:
        return const Color(0xFFEF5350); // 红色
    }
  }
}
