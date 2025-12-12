enum BackUpType {
  auto,
  manual,
}

// 签到状态扩展
extension BackUpTypeExtension on BackUpType {
  String get typeText {
    switch (this) {
      case BackUpType.auto:
        return '自动备份';
      case BackUpType.manual:
        return '手动备份';
      }
  }

  int get toInt {
    switch (this) {
      case BackUpType.auto:
        return 1;
      case BackUpType.manual:
        return 2;
    }
  }

  static BackUpType fromInt(int value) {
    switch (value) {
      case 1:
        return BackUpType.auto;
      case 2:
        return BackUpType.manual;
      
      default:
        return BackUpType.auto;
    }
  }

  static BackUpType fromString(String value) {
    switch (value) {
      case '手动备份':
        return BackUpType.auto;
      case '自动备份':
        return BackUpType.manual;
      
      default:
        return BackUpType.auto;
    }
  }
}