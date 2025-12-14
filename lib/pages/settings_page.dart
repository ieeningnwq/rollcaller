import 'dart:convert';
import 'dart:io' show File;

import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart' show MaterialPicker;
import 'package:flutter_screenutil/flutter_screenutil.dart' show SizeExtension;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:provider/provider.dart';
import 'package:rollcall/configs/back_up_type.dart';
import 'package:rollcall/utils/student_class_dao.dart';
import 'package:webdav_client/webdav_client.dart' show Client, newClient;

import '../configs/strings.dart';
import '../configs/theme_style_option_enum.dart';
import '../models/back_up_model.dart';
import '../providers/them_switcher_provider.dart';
import '../utils/attendance_call_record_dao.dart';
import '../utils/attendance_caller_dao.dart';
import '../utils/random_call_record_dao.dart';
import '../utils/random_caller_dao.dart';
import '../utils/student_class_relation_dao.dart';
import '../utils/student_dao.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsPage> {
  // 上次备份数据，如果为null 则表示从未备份过
  BackUpModel? _lastBackUpModel;
  // WebDav配置服务器输入框
  final TextEditingController _webDavServerController = TextEditingController();
  // WebDav配置用户名输入框
  final TextEditingController _webDavUsernameController =
      TextEditingController();
  // WebDav配置密码输入框
  final TextEditingController _webDavPasswordController =
      TextEditingController();

  // 备份设置状态
  bool _autoBackupEnabled = false;
  // 所有备份信息
  Map<String, BackUpModel> _allBackUpModels = {};
  // 选中待回退的备份数据
  BackUpModel? _selectedBackUpModel;
  // WebDav连接客户端
  late Client _client;
  // 安全存储
  final _storage = const FlutterSecureStorage();

  // 获取WebDav配置
  late Future<void> _getWebDavConfigFuture;
  // 备份进度
  double _procedureProgress = 0;

  ThemeMode _selectedThemeMode = ThemeMode.system;

  ThemeStyleOption _selectedThemeStyle = ThemeStyleOption.values.first;

  @override
  dispose() {
    super.dispose();
    _webDavServerController.dispose();
    _webDavUsernameController.dispose();
    _webDavPasswordController.dispose();
  }

  @override
  initState() {
    super.initState();
    _getWebDavConfigFuture = _getWebDavConfig();
    // 获取主题模式
    _storage.read(key: KString.themeModeStyleOptionKey).then((onValue) {
      if (onValue != null) {
        List<String> themeData = onValue.trim().split(',');
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
          if (mounted) {
            context.read<ThemeSwitcherProvider>().setModelAndStyle(mode, style);
          }
        }
      }
    });
  }

  Future<void> _getWebDavConfig() async {
    // 获取WebDav配置服务器
    _webDavServerController.text =
        (await _storage.read(key: KString.webDavServerKey)) ?? '';
    // 获取WebDav配置用户名
    _webDavUsernameController.text =
        (await _storage.read(key: KString.webDavUsernameKey)) ?? '';
    // 获取WebDav配置密码
    _webDavPasswordController.text =
        (await _storage.read(key: KString.webDavPasswordKey)) ?? '';
    // 设置WebDav连接客户端
    _client = newClient(
      _webDavServerController.text,
      user: _webDavUsernameController.text,
      password: _webDavPasswordController.text,
      debug: false,
    );
    // 获取是否自动备份
    _autoBackupEnabled =
        ((await _storage.read(key: KString.autoBackUpKey)) ?? 'false') ==
        'true';
    try {
      await _client.ping();
      // 获取历史备份数据，从服务器获取数据
      var list = await _client.readDir('/${KString.webDavServerFolder}');
      // 过滤出备份文件，并排序
      list = list
          .where(
            (f) =>
                f.isDir == false &&
                f.name!.startsWith(KString.backupFileName) &&
                f.name!.endsWith('.json'),
          )
          .toList();
      list.sort((a, b) => a.name!.compareTo(b.name!));
      // 转换为备份模型
      var backUpModels = list
          .map(
            (f) => BackUpModel.fromMap({
              'type': BackUpTypeExtension.fromString(f.name!.split('_')[2]),
              'dateTimeKey': f.name!.split('_')[3].replaceAll('.json', ''),
              'result': true,
              'fileName': f.name!,
            }),
          )
          .toList();
      // 转换为Map
      _allBackUpModels = backUpModels.fold(
        {},
        (map, e) => map..addAll({e.dateTimeKey: e}),
      );
      // 获取上次备份数据
      if (list.isNotEmpty) {
        _lastBackUpModel =
            _allBackUpModels[list.last.name!
                .split('_')[3]
                .replaceAll('.json', '')];
        // 获取选中待回退的备份数据
        _selectedBackUpModel = _lastBackUpModel;
      } else {
        _selectedBackUpModel = null;
        _lastBackUpModel = null;
      }
    } catch (e) {
      ;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部标题栏
            Container(
              padding: EdgeInsets.all(12.w),
              child: Text(
                '设置',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            // 主题选择
            _buildThemeSelectWidget(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: FutureBuilder(
                  future: _getWebDavConfigFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      return Column(
                        children: [
                          _buildLastBackUpStatus(),
                          const SizedBox(height: 24),
                          _buildWebDavInfo(),
                          const SizedBox(height: 24),
                          _buildBackUpSetting(),
                          const SizedBox(height: 24),
                          _buildBackUpHistory(),
                        ],
                      );
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Visibility _buildLastBackUpStatus() {
    // 备份状态显示
    return Visibility(
      visible: _lastBackUpModel != null,
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: _lastBackUpModel?.result == true
              ? Colors.green[100]
              : Colors.red[100],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: _lastBackUpModel?.result == true
                  ? Colors.green
                  : Colors.red,
              size: 20,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _lastBackUpModel?.result == true ? '上次备份成功' : '上次备份失败',
                  style: TextStyle(
                    color: _lastBackUpModel?.result == true
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${_lastBackUpModel?.dateTimeText.substring(0, 4)}-${_lastBackUpModel?.dateTimeText.substring(4, 6)}-${_lastBackUpModel?.dateTimeText.substring(6, 8)} ${_lastBackUpModel?.dateTimeText.substring(8, 10)}:${_lastBackUpModel?.dateTimeText.substring(10, 12)}:${_lastBackUpModel?.dateTimeText.substring(12, 14)}',
                  style: TextStyle(
                    color: _lastBackUpModel?.result == true
                        ? Colors.green
                        : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Column _buildWebDavInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // WebDAV配置标题
        const Text(
          'WebDAV配置',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),

        // 输入框容器
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(10),
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // WebDAV服务器地址输入框
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _webDavServerController,
                      decoration: InputDecoration(
                        labelText: 'WebDAV服务器地址',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(
                            color: Colors.purple,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 14.0,
                        ),
                      ),
                    ),
                  ),
                  Text('/rollCaller/'),
                ],
              ),
              SizedBox(height: 16),

              // 用户名输入框
              TextField(
                controller: _webDavUsernameController,
                decoration: InputDecoration(
                  labelText: '用户名',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(
                      color: Colors.purple,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 14.0,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 密码输入框
              TextField(
                controller: _webDavPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '密码',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(
                      color: Colors.purple,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 14.0,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 按钮行
              Row(
                children: [
                  // 测试连接按钮
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        // 将信息保存到_storage
                        _storage.write(
                          key: KString.webDavServerKey,
                          value: _webDavServerController.text,
                        );
                        _storage.write(
                          key: KString.webDavUsernameKey,
                          value: _webDavUsernameController.text,
                        );
                        _storage.write(
                          key: KString.webDavPasswordKey,
                          value: _webDavPasswordController.text,
                        );
                        // 更新_client
                        _client = newClient(
                          _webDavServerController.text,
                          user: _webDavUsernameController.text,
                          password: _webDavPasswordController.text,
                          debug: false,
                        );
                        try {
                          await _client.ping();
                          Fluttertoast.showToast(msg: '连接成功');
                        } catch (e) {
                          // 连接失败处理逻辑
                          // 可以显示错误提示、更新UI状态等
                          Fluttertoast.showToast(msg: '连接失败');
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        side: const BorderSide(color: Colors.purple, width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.network_check,
                            color: Colors.purple,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '测试连接',
                            style: TextStyle(
                              color: Colors.purple,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 保存配置按钮
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // 保存配置的逻辑
                        _storage.write(
                          key: KString.webDavServerKey,
                          value: _webDavServerController.text,
                        );
                        _storage.write(
                          key: KString.webDavUsernameKey,
                          value: _webDavUsernameController.text,
                        );
                        _storage.write(
                          key: KString.webDavPasswordKey,
                          value: _webDavPasswordController.text,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        elevation: 10.w,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.save, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            '保存配置',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Container _buildBackUpSetting() {
    // 备份设置
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(10),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 备份设置标题
          const Text(
            '备份设置',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // 自动备份选项
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '自动备份',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              Switch(
                value: _autoBackupEnabled,
                onChanged: (value) {
                  setState(() {
                    _autoBackupEnabled = value;
                    _storage.write(
                      key: KString.autoBackUpKey,
                      value: value.toString(),
                    );
                  });
                },
                activeThumbColor: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 提示语句
          Text(
            '若打开自动备份则每次推出app时自动备份',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Column _buildBackUpHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 备份和恢复按钮
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // 手动备份逻辑
                  setState(() {
                    _procedureProgress = 0;
                  });
                  _backupData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  elevation: 10.w,
                ),
                child: const Text(
                  '手动备份',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // 恢复数据逻辑
                  if (_selectedBackUpModel != null) {
                    // 这里可以添加实际的恢复逻辑，使用_selectedBackUpModel
                    _restoreFromWebDav(_selectedBackUpModel!);
                  } else {
                    // 可以显示提示信息
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('请先选择要恢复的备份'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  side: const BorderSide(color: Colors.grey, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.restore, color: Colors.black87, size: 18),
                    SizedBox(width: 8),
                    Text(
                      '恢复数据',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // 备份进度条
        LinearProgressIndicator(
          value: _procedureProgress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
        ),
        const SizedBox(height: 12),
        // 备份历史标题
        const Text(
          '备份历史',
          textAlign: TextAlign.left,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        // 备份历史列表容器
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(10),
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: _allBackUpModels.isNotEmpty
              ? RadioGroup<String>(
                  groupValue: _selectedBackUpModel?.dateTimeText,
                  onChanged: (value) {
                    setState(() {
                      _selectedBackUpModel = _allBackUpModels[value];
                    });
                  },
                  child: Column(
                    children: _allBackUpModels.values
                        .toList()
                        .reversed
                        .map(
                          (backUpModel) => RadioListTile<String>(
                            value: backUpModel.dateTimeText,
                            title: Text(
                              '${backUpModel.dateTimeText.substring(0, 4)}-${backUpModel.dateTimeText.substring(4, 6)}-${backUpModel.dateTimeText.substring(6, 8)} ${backUpModel.dateTimeText.substring(8, 10)}:${backUpModel.dateTimeText.substring(10, 12)}:${backUpModel.dateTimeText.substring(12, 14)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              backUpModel.type.typeText,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                )
              : const Center(child: Text('暂无备份历史')),
        ),
      ],
    );
  }

  Future<void> _backupData({BackUpType backUpType = BackUpType.manual}) async {
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
    bool result = false;
    try {
      CancelToken c = CancelToken();
      await _client.writeFromFile(
        tempFilePath,
        '/${KString.webDavServerFolder}/$fileName',
        onProgress: (c, t) {
          setState(() {
            _procedureProgress = c / t;
          });
        },
        cancelToken: c,
      );
      if (c.isCancelled) {
        result = false;
      } else {
        result = true;
      }
    } catch (e) {
      result = false;
      Fluttertoast.showToast(msg: '备份失败：$e');
    }
    // ! 5、删除临时文件
    await tempFile.delete();
    // ! 6、刷新备份历史
    setState(() {
      _allBackUpModels[timeKey] = BackUpModel()
        ..type = BackUpType.manual
        ..dateTimeKey = timeKey
        ..fileName = fileName
        ..result = result;
      _selectedBackUpModel = _allBackUpModels[timeKey];
      _lastBackUpModel = _allBackUpModels[timeKey];
    });
    // ! 7、反馈结果
    if (result) {
      Fluttertoast.showToast(msg: '备份成功');
    } else {
      Fluttertoast.showToast(msg: '备份失败');
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

  Future<void> _restoreFromWebDav(BackUpModel backUpModel) async {
    try {
      // 1、确定文件路径
      final filePath = join(
        '/${KString.webDavServerFolder}',
        backUpModel.fileName,
      );
      // 2、从WebDAV下载文件
      final tempDir = await getTemporaryDirectory();
      final tempFilePath = join(tempDir.path, backUpModel.fileName);
      await _client.read2File(
        filePath,
        tempFilePath,
        onProgress: (c, t) {
          setState(() {
            _procedureProgress = c / t - 0.1;
          });
        },
      );
      // 2、读取文件内容，转为json
      final jsonString = await File(tempFilePath).readAsString();
      final backupData = json.decode(jsonString) as Map<String, dynamic>;
      // 3、删除现有所有数据
      await StudentClassDao().deleteAllStudentClasses();
      await StudentDao().deleteAllStudents();
      await StudentClassRelationDao().deleteAllClassStudentIds();
      await RandomCallerDao().deleteAllRandomCallers();
      await RandomCallRecordDao().deleteAllRandomCallerRecords();
      await AttendanceCallerDao().deleteAllAttendanceCallers();
      await AttendanceCallRecordDao().deleteAllAttendanceCallerRecords();
      // 4、插入新的班级数据
      await StudentClassDao().insertStudentClasses(
        backupData[KString.studentClassTableName],
      );
      // 5、插入新的学生数据
      await StudentDao().insertStudents(backupData[KString.studentTableName]);
      // 6、插入新的班级学生关系数据
      await StudentClassRelationDao().insertClassStudentIds(
        backupData[KString.studentClassRelationTableName],
      );
      // 7、插入新的随机调用数据
      await RandomCallerDao().insertRandomCallers(
        backupData[KString.randomCallerTableName],
      );
      // 8、插入新的随机调用记录数据
      await RandomCallRecordDao().insertRandomCallRecords(
        backupData[KString.randomCallerRecordTableName],
      );
      // 9、插入新的出勤调用数据
      await AttendanceCallerDao().insertAttendanceCallers(
        backupData[KString.attendanceCallerTableName],
      );
      // 10、插入新的出勤调用记录数据
      await AttendanceCallRecordDao().insertAttendanceCallRecords(
        backupData[KString.attendanceCallerRecordTableName],
      );
      // 11、刷新数据
      setState(() {
        _procedureProgress = 1.0;
        Fluttertoast.showToast(msg: '恢复成功');
      });
    } catch (e) {
      Fluttertoast.showToast(msg: '恢复失败：$e');
    }
  }

  // 主题设置
  // 主题控制组件
  Widget _buildThemeSelectWidget() {
    return Container(
      padding: EdgeInsets.all(8.w),
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6.w),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withAlpha(100),
            spreadRadius: 1.w,
            blurRadius: 2.w,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 主题控制标题
          Text('主题控制', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 12.h),
          // 主题模式
          Text('主题模式:', style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 8.h),
          Row(
            children: [
              // 跟随系统
              Expanded(
                child: GestureDetector(
                  onTap: () => _changeThemeMode(ThemeMode.system),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 8.h,
                      horizontal: 12.w,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedThemeMode == ThemeMode.system
                          ? _selectedThemeStyle.color
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: _selectedThemeMode == ThemeMode.system
                            ? Colors.transparent
                            : Theme.of(context).colorScheme.outline,
                        width: 1.w,
                      ),
                    ),
                    child: Text(
                      '跟随系统',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _selectedThemeMode == ThemeMode.system
                            ? ThemeStyleOptionExtension.getContrastColor(
                                _selectedThemeStyle.color,
                              )
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),

              // 浅色
              Expanded(
                child: GestureDetector(
                  onTap: () => _changeThemeMode(ThemeMode.light),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 8.h,
                      horizontal: 12.w,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedThemeMode == ThemeMode.light
                          ? _selectedThemeStyle.color
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(6.w),
                      border: Border.all(
                        color: _selectedThemeMode == ThemeMode.light
                            ? Colors.transparent
                            : Theme.of(context).colorScheme.outline,
                        width: 1.w,
                      ),
                    ),
                    child: Text(
                      '浅色',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _selectedThemeMode == ThemeMode.light
                            ? ThemeStyleOptionExtension.getContrastColor(
                                _selectedThemeStyle.color,
                              )
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),

              // 深色
              Expanded(
                child: GestureDetector(
                  onTap: () => _changeThemeMode(ThemeMode.dark),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 8.h,
                      horizontal: 12.w,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedThemeMode == ThemeMode.dark
                          ? _selectedThemeStyle.color
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(6.w),
                      border: Border.all(
                        color: _selectedThemeMode == ThemeMode.dark
                            ? Colors.transparent
                            : Theme.of(context).colorScheme.outline,
                        width: 1.w,
                      ),
                    ),
                    child: Text(
                      '深色',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _selectedThemeMode == ThemeMode.dark
                            ? ThemeStyleOptionExtension.getContrastColor(
                                _selectedThemeStyle.color,
                              )
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // 主题风格
          Text('主题风格:', style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 8.h),
          Column(
            children: [
              Row(
                children: [
                  // 红色
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _changeThemeStyle(ThemeStyleOption.red),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 8.h,
                          horizontal: 12.w,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedThemeStyle == ThemeStyleOption.red
                              ? _selectedThemeStyle.color
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(6.w),
                          border: Border.all(
                            color: _selectedThemeStyle == ThemeStyleOption.red
                                ? Colors.transparent
                                : Theme.of(context).colorScheme.outline,
                            width: 1.w,
                          ),
                        ),
                        child: Text(
                          '红色',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color:
                                    _selectedThemeStyle == ThemeStyleOption.red
                                    ? ThemeStyleOptionExtension.getContrastColor(
                                        _selectedThemeStyle.color,
                                      )
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 8.w),

                  Expanded(
                    child: GestureDetector(
                      onTap: () => _changeThemeStyle(ThemeStyleOption.orange),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 8.h,
                          horizontal: 12.w,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedThemeStyle == ThemeStyleOption.orange
                              ? _selectedThemeStyle.color
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(6.w),
                          border: Border.all(
                            color:
                                _selectedThemeStyle == ThemeStyleOption.orange
                                ? Colors.transparent
                                : Theme.of(context).colorScheme.outline,
                            width: 1.w,
                          ),
                        ),
                        child: Text(
                          '橙色',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color:
                                    _selectedThemeStyle ==
                                        ThemeStyleOption.orange
                                    ? ThemeStyleOptionExtension.getContrastColor(
                                        _selectedThemeStyle.color,
                                      )
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),

                  Expanded(
                    child: // 黄色
                    GestureDetector(
                      onTap: () => _changeThemeStyle(ThemeStyleOption.yellow),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 8.h,
                          horizontal: 12.w,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedThemeStyle == ThemeStyleOption.yellow
                              ? _selectedThemeStyle.color
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(6.w),
                          border: Border.all(
                            color:
                                _selectedThemeStyle == ThemeStyleOption.yellow
                                ? Colors.transparent
                                : Theme.of(context).colorScheme.outline,
                            width: 1.w,
                          ),
                        ),
                        child: Text(
                          '黄色',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color:
                                    _selectedThemeStyle ==
                                        ThemeStyleOption.yellow
                                    ? ThemeStyleOptionExtension.getContrastColor(
                                        _selectedThemeStyle.color,
                                      )
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),

                  // 绿色
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _changeThemeStyle(ThemeStyleOption.green),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 8.h,
                          horizontal: 12.w,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedThemeStyle == ThemeStyleOption.green
                              ? _selectedThemeStyle.color
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(6.w),
                          border: Border.all(
                            color: _selectedThemeStyle == ThemeStyleOption.green
                                ? Colors.transparent
                                : Theme.of(context).colorScheme.outline,
                            width: 1.w,
                          ),
                        ),
                        child: Text(
                          '绿色',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color:
                                    _selectedThemeStyle ==
                                        ThemeStyleOption.green
                                    ? ThemeStyleOptionExtension.getContrastColor(
                                        _selectedThemeStyle.color,
                                      )
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _changeThemeStyle(ThemeStyleOption.blue),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 8.h,
                          horizontal: 12.w,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedThemeStyle == ThemeStyleOption.blue
                              ? _selectedThemeStyle.color
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(6.w),
                          border: Border.all(
                            color: _selectedThemeStyle == ThemeStyleOption.blue
                                ? Colors.transparent
                                : Theme.of(context).colorScheme.outline,
                            width: 1.w,
                          ),
                        ),
                        child: Text(
                          '蓝色',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color:
                                    _selectedThemeStyle == ThemeStyleOption.blue
                                    ? ThemeStyleOptionExtension.getContrastColor(
                                        _selectedThemeStyle.color,
                                      )
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),

                  Expanded(
                    child: GestureDetector(
                      onTap: () => _changeThemeStyle(ThemeStyleOption.indigo),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 8.h,
                          horizontal: 12.w,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedThemeStyle == ThemeStyleOption.indigo
                              ? _selectedThemeStyle.color
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(6.w),
                          border: Border.all(
                            color:
                                _selectedThemeStyle == ThemeStyleOption.indigo
                                ? Colors.transparent
                                : Theme.of(context).colorScheme.outline,
                            width: 1.w,
                          ),
                        ),
                        child: Text(
                          '青色',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color:
                                    _selectedThemeStyle ==
                                        ThemeStyleOption.indigo
                                    ? ThemeStyleOptionExtension.getContrastColor(
                                        _selectedThemeStyle.color,
                                      )
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),

                  Expanded(
                    child: GestureDetector(
                      onTap: () => _changeThemeStyle(ThemeStyleOption.purple),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 8.h,
                          horizontal: 12.w,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedThemeStyle == ThemeStyleOption.purple
                              ? _selectedThemeStyle.color
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(6.w),
                          border: Border.all(
                            color:
                                _selectedThemeStyle == ThemeStyleOption.purple
                                ? Colors.transparent
                                : Theme.of(context).colorScheme.outline,
                            width: 1.w,
                          ),
                        ),
                        child: Text(
                          '紫色',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color:
                                    _selectedThemeStyle ==
                                        ThemeStyleOption.purple
                                    ? ThemeStyleOptionExtension.getContrastColor(
                                        _selectedThemeStyle.color,
                                      )
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _changeThemeStyle(ThemeStyleOption.diy),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 8.h,
                          horizontal: 12.w,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedThemeStyle == ThemeStyleOption.diy
                              ? _selectedThemeStyle.color
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(6.w),
                          border: Border.all(
                            color: _selectedThemeStyle == ThemeStyleOption.diy
                                ? Colors.transparent
                                : Theme.of(context).colorScheme.outline,
                            width: 1.w,
                          ),
                        ),
                        child: Text(
                          '自定义',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _selectedThemeStyle == ThemeStyleOption.diy
                                ? ThemeStyleOptionExtension.getContrastColor(
                                    _selectedThemeStyle.color,
                                  )
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 切换主题模式
  void _changeThemeMode(ThemeMode mode) {
    setState(() {
      _selectedThemeMode = mode;
    });
    if (mounted) {
      context.read<ThemeSwitcherProvider>().setThemeMode(mode);
    }
  }

  // 切换主题风格
  Future<void> _changeThemeStyle(ThemeStyleOption style) async {
    if(style==ThemeStyleOption.diy){
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('自定义主题'),
          content: SingleChildScrollView(
            child: MaterialPicker(
              pickerColor: _selectedThemeStyle.color,
              onColorChanged: (color) => ThemeStyleOptionExtension.pickedColor = color),
            ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('确定'),
            ),
          ],
        ),
      );
    }
    setState(() {
      _selectedThemeStyle = style;
    });
    if (mounted) {
      context.read<ThemeSwitcherProvider>().setThemeStyle(style);
    }
  }
}
