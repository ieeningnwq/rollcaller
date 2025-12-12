import 'dart:convert';
import 'dart:io' show File;

import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:rollcall/configs/back_up_type.dart';
import 'package:rollcall/utils/student_class_dao.dart';
import 'package:webdav_client/webdav_client.dart' show Client, newClient;

import '../configs/strings.dart';
import '../models/back_up_model.dart';
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
  bool _autoBackupEnabled = true;
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

  @override
  initState() {
    super.initState();
    _getWebDavConfigFuture = _getWebDavConfig();
  }

  Future<void> _getWebDavConfig() async {
    // 获取WebDav配置服务器
    _webDavServerController.text = (await _storage.read(
      key: KString.webDavServerKey,
    ))!;
    // 获取WebDav配置用户名
    _webDavUsernameController.text = (await _storage.read(
      key: KString.webDavUsernameKey,
    ))!;
    // 获取WebDav配置密码
    _webDavPasswordController.text = (await _storage.read(
      key: KString.webDavPasswordKey,
    ))!;
    // 设置WebDav连接客户端
    _client = newClient(
      _webDavServerController.text,
      user: _webDavUsernameController.text,
      password: _webDavPasswordController.text,
      debug: false,
    );
    // 获取是否自动备份
    _autoBackupEnabled =
        (await _storage.read(key: KString.autoBackUpKey))! == 'true';
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
              padding: const EdgeInsets.all(12),
              child: Text(
                '设置',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
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
                  _lastBackUpModel?.dateTimeText ?? '从未备份过',
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
                        elevation: 0,
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
                  elevation: 0,
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
                              backUpModel.dateTimeText,
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

  Future<void> _backupData() async {
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
        '${KString.backupFileName}_${BackUpType.manual.typeText}_$timeKey.json';
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
}
