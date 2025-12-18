import 'dart:convert';
import 'dart:io' show File;

import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart'
    show MaterialPicker;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:provider/provider.dart';
import 'package:webdav_client/webdav_client.dart' show Client, newClient;

import '../configs/back_up_type.dart';
import '../configs/strings.dart';
import '../configs/theme_style_option_enum.dart';
import '../models/back_up_model.dart';
import '../providers/them_switcher_provider.dart';
import '../utils/attendance_call_record_dao.dart';
import '../utils/attendance_caller_dao.dart';
import '../utils/random_call_record_dao.dart';
import '../utils/random_caller_dao.dart';
import '../utils/student_class_dao.dart';
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
  static Map<String, BackUpModel> _allBackUpModels = {};
  // 选中待回退的备份数据
  static BackUpModel? _selectedBackUpModel;
  // WebDav连接客户端
  Client? _client;
  // 安全存储
  final _storage = SharedPreferences.getInstance();

  // 获取WebDav配置

  // 获取WebDav配置
  late Future<void> _getBackUpDataFuture;
  // 备份进度
  double _procedureProgress = 0;

  ThemeMode? _selectedThemeMode;

  ThemeStyleOption? _selectedThemeStyle;

  bool _isThemeSettingsExpanded = false;

  // 备份数据刷新
  bool _isRefreshingBackUpData = false;

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
    // 读取webdav设置
    _getWebDavConfig().then((onValue) {
      setState(() {
        _autoBackupEnabled = onValue;
      });
    });
    _getBackUpDataFuture = _getBackUpData();
  }

  Future<bool> _getWebDavConfig() async {
    // 获取WebDav配置服务器
    _webDavServerController.text =
        (await _storage.then(
          (storage) => storage.getString(KString.webDavServerKey),
        )) ??
        '';
    // 获取WebDav配置用户名
    _webDavUsernameController.text =
        (await _storage.then(
          (storage) => storage.getString(KString.webDavUsernameKey),
        )) ??
        '';
    // 获取WebDav配置密码
    _webDavPasswordController.text =
        (await _storage.then(
          (storage) => storage.getString(KString.webDavPasswordKey),
        )) ??
        '';
    // 设置WebDav连接客户端
    _client = newClient(
      _webDavServerController.text,
      user: _webDavUsernameController.text,
      password: _webDavPasswordController.text,
      debug: false,
    );
    // 获取是否自动备份
    bool autoBackupEnabled =
        ((await _storage.then(
          (storage) => storage.getBool(KString.autoBackUpKey),
        )) ??
        false);
    return autoBackupEnabled;
  }

  Future<void> _getBackUpData() async {
    while (_client == null) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (_allBackUpModels.isEmpty) {
      await _refreshBackUpData();
    }
  }

  @override
  Widget build(BuildContext context) {
    _selectedThemeStyle ??= context.read<ThemeSwitcherProvider>().themeStyle;
    _selectedThemeMode ??= context.read<ThemeSwitcherProvider>().themeMode;
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
                padding: EdgeInsets.all(8.0.w),
                child: Column(
                  children: [
                    _buildLastBackUpStatus(),
                    SizedBox(height: 8.h),
                    _buildWebDavInfo(),
                    SizedBox(height: 8.h),
                    _buildBackUpSetting(),
                    SizedBox(height: 8.h),
                    _buildBackUpButtons(),
                    FutureBuilder(
                      future: _getBackUpDataFuture,
                      builder: (context, snapshot) {
                        if (_isRefreshingBackUpData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.connectionState == ConnectionState.done) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }
                          return _buildBackUpHistory();
                        } else {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                      },
                    ),
                  ],
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
        margin: EdgeInsets.only(top: 8.h),
        padding: EdgeInsets.all(16.0.w),
        decoration: BoxDecoration(
          color: _lastBackUpModel?.result == true
              ? Colors.green[100]
              : Colors.red[100],
          borderRadius: BorderRadius.circular(8.0.r),
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
            SizedBox(width: 8.0.w),
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _lastBackUpModel?.result == true
                        ? Colors.green
                        : Colors.red,
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
        SizedBox(height: 8.h),
        // WebDAV配置标题
        Text('WebDAV配置', style: Theme.of(context).textTheme.headlineMedium),
        SizedBox(height: 4.h),
        // 输入框容器
        Container(
          padding: EdgeInsets.only(top: 20.0.h, left: 8.0.w, right: 8.0.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8.0.r),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withAlpha(100),
                spreadRadius: 1.r,
                blurRadius: 2.r,
                offset: const Offset(0, 1),
              ),
            ],
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              width: 1.0,
            ),
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
                        labelStyle: Theme.of(context).textTheme.labelLarge,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0.r),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0.r),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0.r),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.0.w,
                          vertical: 14.0.h,
                        ),
                      ),
                    ),
                  ),
                  Text('/rollCaller/'),
                ],
              ),
              SizedBox(height: 16.h),

              // 用户名输入框
              TextField(
                controller: _webDavUsernameController,
                decoration: InputDecoration(
                  labelText: '用户名',
                  labelStyle: Theme.of(context).textTheme.labelLarge,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0.r),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0.r),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0.r),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2.0,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.0.w,
                    vertical: 14.0.h,
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // 密码输入框
              TextField(
                controller: _webDavPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '密码',
                  labelStyle: Theme.of(context).textTheme.labelLarge,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0.r),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0.r),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0.r),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2.0,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.0.w,
                    vertical: 14.0.h,
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // 按钮行
              Row(
                children: [
                  // 测试连接按钮
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        // 将信息保存到_storage
                        await _storage.then(
                          (value) => value.setString(
                            KString.webDavServerKey,
                            _webDavServerController.text,
                          ),
                        );
                        await _storage.then(
                          (value) => value.setString(
                            KString.webDavUsernameKey,
                            _webDavUsernameController.text,
                          ),
                        );
                        await _storage.then(
                          (value) => value.setString(
                            KString.webDavPasswordKey,
                            _webDavPasswordController.text,
                          ),
                        );
                        // 更新_client
                        _client = newClient(
                          _webDavServerController.text,
                          user: _webDavUsernameController.text,
                          password: _webDavPasswordController.text,
                          debug: false,
                        );
                        try {
                          await _client!.ping();
                          // 连接成功处理逻辑
                          // 可以显示成功提示、更新UI状态等
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '连接成功',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onInverseSurface,
                                  ),
                                ),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.inverseSurface,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                            // 刷新备份数据
                            setState(() {
                              _getBackUpDataFuture = _getBackUpData();
                            });
                          }
                        } catch (e) {
                          // 连接失败处理逻辑
                          // 可以显示错误提示、更新UI状态等
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '连接失败：$e',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onInverseSurface,
                                  ),
                                ),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.inverseSurface,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: EdgeInsets.symmetric(vertical: 14.0.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0.r),
                        ),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.onPrimary,
                          width: 1.0.w,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.network_check,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size:
                                Theme.of(
                                  context,
                                ).textTheme.titleMedium?.fontSize ??
                                24.0.sp,
                          ),
                          SizedBox(width: 8.0.w),
                          Text(
                            '测试连接',
                            style: Theme.of(context).textTheme.titleMedium!
                                .copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),

                  // 保存配置按钮
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // 保存配置的逻辑
                        _storage.then(
                          (value) => value.setString(
                            KString.webDavServerKey,
                            _webDavServerController.text,
                          ),
                        );
                        _storage.then(
                          (value) => value.setString(
                            KString.webDavUsernameKey,
                            _webDavUsernameController.text,
                          ),
                        );
                        _storage.then(
                          (value) => value.setString(
                            KString.webDavPasswordKey,
                            _webDavPasswordController.text,
                          ),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '配置已保存',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onInverseSurface,
                                ),
                              ),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.inverseSurface,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: EdgeInsets.symmetric(vertical: 14.0.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0.r),
                        ),
                        elevation: 10.w,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.save,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size:
                                Theme.of(
                                  context,
                                ).textTheme.titleMedium?.fontSize ??
                                24.0.sp,
                          ),
                          SizedBox(width: 8.0.w),
                          Text(
                            '保存配置',
                            style: Theme.of(context).textTheme.titleMedium!
                                .copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
        SizedBox(height: 8.h),
      ],
    );
  }

  Container _buildBackUpSetting() {
    // 备份设置
    return Container(
      padding: EdgeInsets.all(8.0.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withAlpha(100),
            spreadRadius: 1.r,
            blurRadius: 2.r,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 备份设置标题
          Text(
            '备份设置',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8.r),

          // 自动备份选项
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '自动备份',
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Switch(
                value: _autoBackupEnabled,
                onChanged: (value) {
                  setState(() {
                    _autoBackupEnabled = value;
                    _storage.then(
                      (storage) =>
                          storage.setBool(KString.autoBackUpKey, value),
                    );
                  });
                },
                // activeThumbColor: Theme.of(context).colorScheme.secondary,
              ),
            ],
          ),
          SizedBox(height: 4.r),
          // 提示语句
          Text(
            '若打开自动备份则每次应用置于后台时自动备份',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Column _buildBackUpButtons() {
    return Column(
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
                style: OutlinedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: EdgeInsets.symmetric(vertical: 14.0.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0.r),
                  ),
                  elevation: 10.w,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.backup,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '手动备份',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 12.w),
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
                      SnackBar(
                        content: Text(
                          '请先选择要恢复的备份',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onInverseSurface,
                          ),
                        ),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.inverseSurface,
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: EdgeInsets.symmetric(vertical: 14.0.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0.r),
                  ),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.onPrimary,
                    width: 1.w,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restore,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '恢复数据',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 24.h),
        // 备份进度条
        LinearProgressIndicator(
          value: _procedureProgress,
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
        // 备份历史标题
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '备份历史',
              textAlign: TextAlign.left,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton.icon(
              label: Text('刷新'),
              icon: Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _isRefreshingBackUpData = true;
                  _getBackUpDataFuture = _getBackUpData();
                });
                _refreshBackUpData().then(
                  (value) => setState(() {
                    _isRefreshingBackUpData = false;
                  }),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Column _buildBackUpHistory() {
    var backUpModels = _allBackUpModels.values.toList();
    backUpModels.sort((a, b) => b.dateTimeKey.compareTo(a.dateTimeKey));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 备份历史列表容器
        Container(
          padding: EdgeInsets.all(8.0.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8.0.r),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withAlpha(100),
                spreadRadius: 1.r,
                blurRadius: 2.r,
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
                    children: backUpModels
                        .map(
                          (backUpModel) => Dismissible(
                            key: Key(backUpModel.toString()),
                            background: Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.secondaryContainer,
                            ),
                            secondaryBackground: Container(
                              color: Theme.of(context).colorScheme.error,
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.symmetric(horizontal: 16.0.w),
                              child: Icon(
                                Icons.delete,
                                color: Theme.of(context).colorScheme.onError,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.endToStart) {
                                return await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('确认删除'),
                                    content: const Text('确定要删除此备份吗？此操作不可撤销。'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('取消'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          if (_selectedBackUpModel
                                                  ?.dateTimeText ==
                                              backUpModel.dateTimeText) {
                                            Navigator.of(context).pop(false);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text('当前选中备份不能删除'),
                                              ),
                                            );
                                            return;
                                          } else {
                                            // 删除文件
                                            try {
                                              _client?.remove(
                                                '/${KString.webDavServerFolder}/${backUpModel.fileName}',
                                              );
                                              setState(() {
                                                _allBackUpModels.remove(
                                                  backUpModel.dateTimeText,
                                                );
                                                // 更新最后备份模型
                                                _lastBackUpModel =
                                                    _allBackUpModels.values
                                                        .toList()
                                                        .reversed
                                                        .first;
                                              });
                                              Navigator.of(context).pop(true);
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text('删除文件成功'),
                                                ),
                                              );
                                            } catch (e) {
                                              Navigator.of(context).pop(false);

                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text('删除文件失败：$e'),
                                                ),
                                              );
                                              return;
                                            }
                                          }
                                        },
                                        child: const Text('确认'),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                return false;
                              }
                            },
                            child: RadioListTile<String>(
                              value: backUpModel.dateTimeText,
                              title: Text(
                                '${backUpModel.dateTimeText.substring(0, 4)}-${backUpModel.dateTimeText.substring(4, 6)}-${backUpModel.dateTimeText.substring(6, 8)} ${backUpModel.dateTimeText.substring(8, 10)}:${backUpModel.dateTimeText.substring(10, 12)}:${backUpModel.dateTimeText.substring(12, 14)}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSecondaryContainer,
                                    ),
                              ),
                              subtitle: Text(
                                backUpModel.type.typeText,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSecondaryContainer,
                                    ),
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
      await _client!.writeFromFile(
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
      // 显示SnackBar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '备份失败：$e',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onInverseSurface,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.inverseSurface,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
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
      // 显示SnackBar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '备份成功',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onInverseSurface,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.inverseSurface,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      // 显示SnackBar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '备份失败',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onInverseSurface,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.inverseSurface,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
      await _client!.read2File(
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
        // 显示SnackBar
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '恢复成功',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                ),
              ),
              backgroundColor: Theme.of(context).colorScheme.inverseSurface,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    } catch (e) {
      // 显示SnackBar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '恢复失败：$e',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onInverseSurface,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.inverseSurface,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // 主题设置
  // 主题控制组件
  Widget _buildThemeSelectWidget() {
    return GestureDetector(
      onTap: () =>
          setState(() => _isThemeSettingsExpanded = !_isThemeSettingsExpanded),
      child: Container(
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
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 2.w,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 顶部标题和管理链接
                  Text('主题设置', style: Theme.of(context).textTheme.titleLarge),
                  Icon(
                    _isThemeSettingsExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: Theme.of(context).textTheme.titleLarge?.fontSize,
                  ),
                ],
              ),
            ),
            // 主题控制标题
            SizedBox(height: 8.h),
            AnimatedCrossFade(
              firstChild: const SizedBox(height: 0, width: 0),
              secondChild: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '主题模式:',
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
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
                                    ? _selectedThemeStyle?.color ?? Colors.blue
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
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color:
                                          _selectedThemeMode == ThemeMode.system
                                          ? ThemeStyleOptionExtension.getContrastColor(
                                              _selectedThemeStyle?.color ??
                                                  Colors.blue,
                                            )
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
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
                                    ? _selectedThemeStyle?.color ?? Colors.blue
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
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color:
                                          _selectedThemeMode == ThemeMode.light
                                          ? ThemeStyleOptionExtension.getContrastColor(
                                              _selectedThemeStyle?.color ??
                                                  Colors.blue,
                                            )
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
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
                                    ? _selectedThemeStyle?.color ?? Colors.blue
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
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color:
                                          _selectedThemeMode == ThemeMode.dark
                                          ? ThemeStyleOptionExtension.getContrastColor(
                                              _selectedThemeStyle?.color ??
                                                  Colors.blue,
                                            )
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // 主题风格
                    Text(
                      '主题风格:',
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8.h),
                    Column(
                      children: [
                        Row(
                          children: [
                            // 红色
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    _changeThemeStyle(ThemeStyleOption.red),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 8.h,
                                    horizontal: 12.w,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _selectedThemeStyle ==
                                            ThemeStyleOption.red
                                        ? _selectedThemeStyle!.color
                                        : Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(6.w),
                                    border: Border.all(
                                      color:
                                          _selectedThemeStyle ==
                                              ThemeStyleOption.red
                                          ? Colors.transparent
                                          : Theme.of(
                                              context,
                                            ).colorScheme.outline,
                                      width: 1.w,
                                    ),
                                  ),
                                  child: Text(
                                    '红色',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color:
                                              _selectedThemeStyle ==
                                                  ThemeStyleOption.red
                                              ? ThemeStyleOptionExtension.getContrastColor(
                                                  _selectedThemeStyle!.color,
                                                )
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                        ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(width: 8.w),

                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    _changeThemeStyle(ThemeStyleOption.orange),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 8.h,
                                    horizontal: 12.w,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _selectedThemeStyle ==
                                            ThemeStyleOption.orange
                                        ? _selectedThemeStyle!.color
                                        : Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(6.w),
                                    border: Border.all(
                                      color:
                                          _selectedThemeStyle ==
                                              ThemeStyleOption.orange
                                          ? Colors.transparent
                                          : Theme.of(
                                              context,
                                            ).colorScheme.outline,
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
                                                  _selectedThemeStyle!.color,
                                                )
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),

                            Expanded(
                              child: // 黄色
                              GestureDetector(
                                onTap: () =>
                                    _changeThemeStyle(ThemeStyleOption.yellow),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 8.h,
                                    horizontal: 12.w,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _selectedThemeStyle ==
                                            ThemeStyleOption.yellow
                                        ? _selectedThemeStyle!.color
                                        : Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(6.w),
                                    border: Border.all(
                                      color:
                                          _selectedThemeStyle ==
                                              ThemeStyleOption.yellow
                                          ? Colors.transparent
                                          : Theme.of(
                                              context,
                                            ).colorScheme.outline,
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
                                                  _selectedThemeStyle!.color,
                                                )
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),

                            // 绿色
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    _changeThemeStyle(ThemeStyleOption.green),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 8.h,
                                    horizontal: 12.w,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _selectedThemeStyle ==
                                            ThemeStyleOption.green
                                        ? _selectedThemeStyle!.color
                                        : Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(6.w),
                                    border: Border.all(
                                      color:
                                          _selectedThemeStyle ==
                                              ThemeStyleOption.green
                                          ? Colors.transparent
                                          : Theme.of(
                                              context,
                                            ).colorScheme.outline,
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
                                                  _selectedThemeStyle!.color,
                                                )
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
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
                                onTap: () =>
                                    _changeThemeStyle(ThemeStyleOption.blue),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 8.h,
                                    horizontal: 12.w,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _selectedThemeStyle ==
                                            ThemeStyleOption.blue
                                        ? _selectedThemeStyle!.color
                                        : Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(6.w),
                                    border: Border.all(
                                      color:
                                          _selectedThemeStyle ==
                                              ThemeStyleOption.blue
                                          ? Colors.transparent
                                          : Theme.of(
                                              context,
                                            ).colorScheme.outline,
                                      width: 1.w,
                                    ),
                                  ),
                                  child: Text(
                                    '蓝色',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color:
                                              _selectedThemeStyle ==
                                                  ThemeStyleOption.blue
                                              ? ThemeStyleOptionExtension.getContrastColor(
                                                  _selectedThemeStyle!.color,
                                                )
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),

                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    _changeThemeStyle(ThemeStyleOption.indigo),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 8.h,
                                    horizontal: 12.w,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _selectedThemeStyle ==
                                            ThemeStyleOption.indigo
                                        ? _selectedThemeStyle!.color
                                        : Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(6.w),
                                    border: Border.all(
                                      color:
                                          _selectedThemeStyle ==
                                              ThemeStyleOption.indigo
                                          ? Colors.transparent
                                          : Theme.of(
                                              context,
                                            ).colorScheme.outline,
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
                                                  _selectedThemeStyle!.color,
                                                )
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),

                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    _changeThemeStyle(ThemeStyleOption.purple),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 8.h,
                                    horizontal: 12.w,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _selectedThemeStyle ==
                                            ThemeStyleOption.purple
                                        ? _selectedThemeStyle!.color
                                        : Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(6.w),
                                    border: Border.all(
                                      color:
                                          _selectedThemeStyle ==
                                              ThemeStyleOption.purple
                                          ? Colors.transparent
                                          : Theme.of(
                                              context,
                                            ).colorScheme.outline,
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
                                                  _selectedThemeStyle!.color,
                                                )
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    _changeThemeStyle(ThemeStyleOption.diy),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 8.h,
                                    horizontal: 12.w,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _selectedThemeStyle ==
                                            ThemeStyleOption.diy
                                        ? _selectedThemeStyle!.color
                                        : Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(6.w),
                                    border: Border.all(
                                      color:
                                          _selectedThemeStyle ==
                                              ThemeStyleOption.diy
                                          ? Colors.transparent
                                          : Theme.of(
                                              context,
                                            ).colorScheme.outline,
                                      width: 1.w,
                                    ),
                                  ),
                                  child: Text(
                                    '自定义',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color:
                                              _selectedThemeStyle ==
                                                  ThemeStyleOption.diy
                                              ? ThemeStyleOptionExtension.getContrastColor(
                                                  _selectedThemeStyle!.color,
                                                )
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
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
              ),
              crossFadeState: _isThemeSettingsExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),

            // 主题模式
          ],
        ),
      ),
    );
  }

  // 切换主题模式
  Future<void> _changeThemeMode(ThemeMode mode) async {
    setState(() {
      _selectedThemeMode = mode;
    });
    if (mounted) {
      context.read<ThemeSwitcherProvider>().setThemeMode(mode);
      // 将主题风格数据写入安全存储
      if (_selectedThemeStyle != ThemeStyleOption.diy) {
        await _storage.then(
          (value) => value.setString(
            KString.themeModeStyleOptionKey,
            '${context.read<ThemeSwitcherProvider>().themeMode.toString()},${context.read<ThemeSwitcherProvider>().themeStyle.toString()}',
          ),
        );
      } else {
        await _storage.then(
          (value) => value.setString(
            KString.themeModeStyleOptionKey,
            '${context.read<ThemeSwitcherProvider>().themeMode.toString()},${context.read<ThemeSwitcherProvider>().themeStyle.toString()},${ThemeStyleOptionExtension.pickedColor.toARGB32()}',
          ),
        );
      }
    }
  }

  // 切换主题风格
  Future<void> _changeThemeStyle(ThemeStyleOption style) async {
    Color materialPickerColor = _selectedThemeStyle!.color;
    if (style == ThemeStyleOption.diy) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('自定义主题'),
          content: SingleChildScrollView(
            child: MaterialPicker(
              pickerColor: _selectedThemeStyle!.color,
              onColorChanged: (color) => materialPickerColor = color,
              onPrimaryChanged: (color) => materialPickerColor = color,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ThemeStyleOptionExtension.pickedColor = materialPickerColor;
              },
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
      // 将主题风格数据写入安全存储
      if (style != ThemeStyleOption.diy) {
        _storage.then(
          (value) => value.setString(
            KString.themeModeStyleOptionKey,
            '${context.read<ThemeSwitcherProvider>().themeMode.toString()},${context.read<ThemeSwitcherProvider>().themeStyle.toString()}',
          ),
        );
      } else {
        _storage.then(
          (value) => value.setString(
            KString.themeModeStyleOptionKey,
            '${context.read<ThemeSwitcherProvider>().themeMode.toString()},${context.read<ThemeSwitcherProvider>().themeStyle.toString()},${ThemeStyleOptionExtension.pickedColor.toARGB32()}',
          ),
        );
      }
    }
  }

  Future<void> _refreshBackUpData() async {
    try {
      await _client!.ping();
      // 获取历史备份数据，从服务器获取数据
      var list = await _client!.readDir('/${KString.webDavServerFolder}');
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
      // 显示SnackBar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '获取WebDav配置失败：$e',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onInverseSurface,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.inverseSurface,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
