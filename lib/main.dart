import 'dart:convert' show json;
import 'dart:developer';
import 'dart:io' show File;

import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;
import 'package:webdav_client/webdav_client.dart' show Client, newClient;

import './providers/current_index_provider.dart';
import 'configs/back_up_type.dart' show BackUpType, BackUpTypeExtension;
import 'configs/strings.dart';
import 'configs/theme_style_option_enum.dart'
    show ThemeStyleOptionExtension, ThemeStyleOption;
import 'pages/index_page.dart';
import 'providers/them_switcher_provider.dart';
import 'utils/attendance_call_record_dao.dart';
import 'utils/attendance_caller_dao.dart';
import 'utils/random_call_record_dao.dart';
import 'utils/random_caller_dao.dart';
import 'utils/student_class_dao.dart';
import 'utils/student_class_relation_dao.dart';
import 'utils/student_dao.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CurrentIndexProvider>(
          create: (_) => CurrentIndexProvider(),
        ),
        ChangeNotifierProvider<ThemeSwitcherProvider>(
          create: (_) => ThemeSwitcherProvider(),
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
  final _storage = SharedPreferences.getInstance();

  Future<void> _getThemeInfo() async {
    // 获取主题模式
    final storage = await _storage;
    final themeModeStyleOption = storage.getString(
      KString.themeModeStyleOptionKey,
    );
    if (themeModeStyleOption != null) {
      List<String> themeData = themeModeStyleOption.trim().split(',');
      ThemeMode mode = ThemeStyleOptionExtension.fromStringToThemeMode(
        themeData[0],
      );
      ThemeStyleOption style = ThemeStyleOptionExtension.fromString(
        themeData[1],
      );
      if (style == ThemeStyleOption.diy) {
        int argb = int.parse(themeData[2]);
        ThemeStyleOptionExtension.pickedColor = Color.fromARGB(
          (argb >> 24) & 0xFF,
          (argb >> 16) & 0xFF,
          (argb >> 8) & 0xFF,
          argb & 0xFF,
        );
      }
      if (mounted) {
        context.read<ThemeSwitcherProvider>().setModelAndStyleWithoutNotify(
          mode,
          style,
        );
      }
    } else {
      if (mounted) {
        context.read<ThemeSwitcherProvider>().setModelAndStyleWithoutNotify(
          ThemeMode.system,
          ThemeStyleOption.blue,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(540, 960),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return FutureBuilder(
          future: _getThemeInfo(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                // 定制主题
                theme: context.watch<ThemeSwitcherProvider>().theme,
                darkTheme: context.watch<ThemeSwitcherProvider>().darkTheme,
                themeMode: context.watch<ThemeSwitcherProvider>().themeMode,
                home: IndexPage(),
              );
            } else {
              return CircularProgressIndicator();
            }
          },
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
          ((await _storage.then(
            (storage) => storage.getBool(KString.autoBackUpKey),
          )) ??
          false);
      if (autoBackupEnabled) {
        // 获取WebDav配置服务器
        final webDavServer =
            (await _storage.then(
              (storage) => storage.getString(KString.webDavServerKey),
            )) ??
            '';
        // 获取WebDav配置用户名
        final webDavUsername =
            (await _storage.then(
              (storage) => storage.getString(KString.webDavUsernameKey),
            )) ??
            '';
        // 获取WebDav配置密码
        final webDavPassword =
            (await _storage.then(
              (storage) => storage.getString(KString.webDavPasswordKey),
            )) ??
            '';
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
          // ! 8、自动备份失败
          log('WebDav连接失败');
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
      // ! 7、自动备份失败
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
