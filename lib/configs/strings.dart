class KString {
  static const String homeAppBarTitle = '点名系统';
  static const String homeTitle = '首页';
  static const String studentClassTitle = '班级';
  static const String studentClassAppBarTitle = '教学班级';
  static const String studentTitle = '学生';
  static const String studentAppBarTitle = '学生名单';
  static const String recordTitle = '记录';
  static const String recordAppBarTitle = '点名记录';
  static const String settingsTitle = '设置';
  // ! 数据库相关配置
  static const String databaseName = 'rollcall.db';
  static const String studentClassTableName = 'student_class';
  static const String studentTableName = 'student';
  static const String randomCallerTableName = 'random_caller';
  static const String randomCallerRecordTableName = 'random_caller_record';
  static const String attendanceCallerTableName = 'attendance_caller';
  static const String attendanceCallerRecordTableName =
      'attendance_caller_record';
  static const String studentClassRelationTableName = 'student_class_relation';
  // ! WebDav相关配置
  // WebDav配置服务器键
  static const String webDavServerKey = 'webDavServer';
  // WebDav配置用户名键
  static const String webDavUsernameKey = 'webDavUsername';
  // WebDav配置密码键
  static const String webDavPasswordKey = 'webDavPassword';
  // 备份历史记录键
  static const String backUpHistoryKey = 'backUpHistory';
  // 是否自动备份
  static const String autoBackUpKey = 'autoBackUp';
  // 备份文件名
  static const String backupFileName = 'rollcaller_backup';
  // 备份文件夹
  static const String webDavServerFolder = 'rollCaller';
  // ! SharedPreferences 主题模式样式选项键
  static const String themeModeStyleOptionKey = 'themeModeStyleOption';
}
