import 'dart:convert' show json;
import 'dart:developer';
import 'dart:io' show File;

import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'
    show FlutterSecureStorage;
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:provider/provider.dart';
import 'package:rollcall/configs/back_up_type.dart'
    show BackUpType, BackUpTypeExtension;
import 'package:rollcall/configs/strings.dart' show KString;
import 'package:rollcall/utils/attendance_call_record_dao.dart'
    show AttendanceCallRecordDao;
import 'package:rollcall/utils/attendance_caller_dao.dart'
    show AttendanceCallerDao;
import 'package:rollcall/utils/random_call_record_dao.dart'
    show RandomCallRecordDao;
import 'package:rollcall/utils/random_caller_dao.dart' show RandomCallerDao;
import 'package:rollcall/utils/student_class_dao.dart' show StudentClassDao;
import 'package:rollcall/utils/student_class_relation_dao.dart'
    show StudentClassRelationDao;
import 'package:rollcall/utils/student_dao.dart' show StudentDao;
import 'package:webdav_client/webdav_client.dart' show Client, newClient;
import './configs/color.dart';
import 'pages/index_page.dart';
import './providers/current_index_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CurrentIndexProvider>(
          create: (_) => CurrentIndexProvider(),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // 安全存储
  final _storage = const FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(480, 954),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          // 定制主题
          theme: ThemeData(colorScheme: .fromSeed(seedColor: KColor.seedColor)),
          home: IndexPage(),
        );
      },
    );
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      // 获取是否自动备份
      bool autoBackupEnabled =
          ((await _storage.read(key: KString.autoBackUpKey)) ?? 'false') ==
          'true';
      if (autoBackupEnabled) {
        // 获取WebDav配置服务器
        final webDavServer =
            (await _storage.read(key: KString.webDavServerKey)) ?? '';
        // 获取WebDav配置用户名
        final webDavUsername =
            (await _storage.read(key: KString.webDavUsernameKey)) ?? '';
        // 获取WebDav配置密码
        final webDavPassword =
            (await _storage.read(key: KString.webDavPasswordKey)) ?? '';
        // 设置WebDav连接客户端
        Client client = newClient(
          webDavServer,
          user: webDavUsername,
          password: webDavPassword,
          debug: false,
        );
        try {
          await client.ping();
          // 开始备份
          await _backupData(client: client, backUpType: BackUpType.auto);
        } catch (e) {
          log('WebDav连接失败：$e');
          return;
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  Future<void> _backupData({
    required Client client,
    BackUpType backUpType = BackUpType.manual,
  }) async {
    // ! 1、获取所有表格数据
    final backupData = await _exportAllTables();
    // ! 2、转换为JSON字符串
    // 2. 转换为JSON字符串
    final jsonString = json.encode(backupData);
    // ! 3、保存到临时文件
    final tempDir = await getTemporaryDirectory();
    final t = DateTime.now();
    final timeKey =
        '${t.year}${t.month.toString().padLeft(2, '0')}${t.day.toString().padLeft(2, '0')}${t.hour.toString().padLeft(2, '0')}${t.minute.toString().padLeft(2, '0')}${t.second.toString().padLeft(2, '0')}';
    final fileName =
        '${KString.backupFileName}_${backUpType.typeText}_$timeKey.json';
    final tempFilePath = join(tempDir.path, fileName);
    final tempFile = File(tempFilePath);
    await tempFile.writeAsString(jsonString);
    // ! 4、上传到WebDAV
    try {
      CancelToken c = CancelToken();
      await client.writeFromFile(
        tempFilePath,
        '/${KString.webDavServerFolder}/$fileName',

        cancelToken: c,
      );
      // ! 5、删除临时文件
      await tempFile.delete();
      // ! 6、自动备份成功
      log('备份成功：$fileName');
    } catch (e) {
      log('备份失败：$e');
    }
  }

  static Future<Map<String, List<Map<String, dynamic>>>>
  _exportAllTables() async {
    final backupData = <String, List<Map<String, dynamic>>>{};

    // 导出各个数据表
    backupData[KString.studentClassTableName] = await StudentClassDao()
        .getAllStudentClassesMap();
    backupData[KString.studentTableName] = await StudentDao()
        .getAllStudentsMap();
    backupData[KString.studentClassRelationTableName] =
        await StudentClassRelationDao().getAllClassStudentIds();
    backupData[KString.randomCallerTableName] = await RandomCallerDao()
        .getAllRandomCallersMap();
    backupData[KString.randomCallerRecordTableName] =
        await RandomCallRecordDao().getAllRandomCallerRecordsMap();
    backupData[KString.attendanceCallerTableName] = await AttendanceCallerDao()
        .getAllAttendanceCallersMap();
    backupData[KString.attendanceCallerRecordTableName] =
        await AttendanceCallRecordDao().getAllAttendanceCallerRecordsMap();

    return backupData;
  }
}
