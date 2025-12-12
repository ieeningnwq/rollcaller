# WebDAV备份恢复功能说明

## 功能介绍

这是一个独立的Flutter WebDAV备份恢复工具，用于备份和恢复SQLite数据库中的数据表。该工具支持以下六个数据表的完整备份和恢复：

1. `student_class` - 班级信息表
2. `student` - 学生信息表
3. `random_caller` - 随机点名器表
4. `random_caller_record` - 随机点名记录表
5. `attendance_caller` - 考勤点名器表
6. `attendance_caller_record` - 考勤点名记录表

## 依赖项

要使用此功能，您需要在Flutter项目的`pubspec.yaml`文件中添加以下依赖：

```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0
  path_provider: ^2.1.1
  path: ^1.8.3
  webdav_client: ^1.2.2
```

## 使用方法

### 1. 添加文件

将`webdav_backup_restore.dart`文件添加到您的Flutter项目中。

### 2. 初始化数据库

确保您的项目已经初始化了SQLite数据库，并且包含了所需的数据表结构。

### 3. 备份数据到WebDAV

```dart
import 'package:sqflite/sqflite.dart';
import 'webdav_backup_restore.dart';

// 备份数据到WebDAV
await WebDavBackupRestore.backupToWebDav(
  db: yourDatabaseInstance,
  webdavUrl: 'https://example.com/webdav',
  username: 'your_username',
  password: 'your_password',
);
```

### 4. 从WebDAV恢复数据

```dart
// 从WebDAV恢复数据
await WebDavBackupRestore.restoreFromWebDav(
  db: yourDatabaseInstance,
  webdavUrl: 'https://example.com/webdav',
  username: 'your_username',
  password: 'your_password',
);
```

### 5. 测试WebDAV连接

```dart
// 测试WebDAV连接
final isConnected = await WebDavBackupRestore.testConnection(
  webdavUrl: 'https://example.com/webdav',
  username: 'your_username',
  password: 'your_password',
);

if (isConnected) {
  print('WebDAV连接成功！');
} else {
  print('WebDAV连接失败！');
}
```

### 6. 获取备份文件信息

```dart
// 获取备份文件信息
final lastBackupDate = await WebDavBackupRestore.getBackupFileInfo(
  webdavUrl: 'https://example.com/webdav',
  username: 'your_username',
  password: 'your_password',
);

if (lastBackupDate != null) {
  print('最后备份时间: $lastBackupDate');
}
```

## 数据结构

### 备份文件格式

备份文件以JSON格式存储，结构如下：

```json
{
  "student_class": [
    {
      "id": 1,
      "class_name": "高三(1)班",
      "student_quantity": 50,
      "teacher_name": "张老师",
      "notes": "重点班",
      "created": "2024-01-01 10:00:00"
    }
  ],
  "student": [
    {
      "id": 1,
      "student_number": "20210001",
      "student_name": "张三",
      "class_name": "高三(1)班",
      "created": "2024-01-01 10:05:00"
    }
  ],
  "random_caller": [
    {
      "id": 1,
      "random_caller_name": "数学课堂",
      "is_duplicate": 0,
      "class_id": 1,
      "is_archive": 0,
      "notes": "",
      "created": "2024-01-01 10:10:00"
    }
  ],
  "random_caller_record": [
    {
      "id": 1,
      "random_caller_id": 1,
      "student_id": 1,
      "score": 95,
      "notes": "回答正确",
      "created": "2024-01-01 10:15:00"
    }
  ],
  "attendance_caller": [
    {
      "id": 1,
      "attendance_caller_name": "周一考勤",
      "class_id": 1,
      "is_archive": 0,
      "notes": "",
      "created": "2024-01-01 10:20:00"
    }
  ],
  "attendance_caller_record": [
    {
      "id": 1,
      "attendance_caller_id": 1,
      "student_id": 1,
      "present": 1,
      "notes": "",
      "created": "2024-01-01 10:25:00"
    }
  ]
}
```

### 数据表结构

#### student_class表
- id: 班级ID（主键，自增）
- class_name: 班级名称
- student_quantity: 学生数量
- teacher_name: 班主任姓名
- notes: 备注
- created: 创建时间

#### student表
- id: 学生ID（主键，自增）
- student_number: 学号
- student_name: 学生姓名
- class_name: 所属班级
- created: 创建时间

#### random_caller表
- id: 点名器ID（主键，自增）
- random_caller_name: 点名器名称
- is_duplicate: 是否允许重复点名（0: 不允许，1: 允许）
- class_id: 所属班级ID
- is_archive: 是否归档（0: 未归档，1: 已归档）
- notes: 备注
- created: 创建时间

#### random_caller_record表
- id: 记录ID（主键，自增）
- random_caller_id: 关联的点名器ID
- student_id: 被点名学生ID
- score: 得分
- notes: 备注
- created: 创建时间

#### attendance_caller表
- id: 考勤器ID（主键，自增）
- attendance_caller_name: 考勤器名称
- class_id: 所属班级ID
- is_archive: 是否归档（0: 未归档，1: 已归档）
- notes: 备注
- created: 创建时间

#### attendance_caller_record表
- id: 考勤记录ID（主键，自增）
- attendance_caller_id: 关联的考勤器ID
- student_id: 学生ID
- present: 出勤状态（0: 缺勤，1: 出勤）
- notes: 备注
- created: 创建时间

## 示例应用

`webdav_backup_restore.dart`文件中包含了一个完整的示例应用，您可以直接运行该文件来测试WebDAV备份和恢复功能：

```bash
flutter run webdav_backup_restore.dart
```

## 注意事项

1. 确保您的WebDAV服务器支持文件上传和下载功能
2. 备份和恢复操作会覆盖现有数据，请谨慎操作
3. 建议在执行恢复操作前先备份当前数据库
4. 恢复操作会重置所有表的自增ID
5. 网络不稳定时可能会导致备份或恢复失败

## 错误处理

所有方法都抛出异常，建议使用try-catch进行错误处理：

```dart
try {
  await WebDavBackupRestore.backupToWebDav(
    db: yourDatabaseInstance,
    webdavUrl: 'https://example.com/webdav',
    username: 'your_username',
    password: 'your_password',
  );
  print('备份成功！');
} catch (e) {
  print('备份失败: $e');
}
```
