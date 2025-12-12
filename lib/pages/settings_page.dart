import 'package:flutter/material.dart';
import 'package:rollcall/configs/back_up_type.dart';

import '../models/back_up_model.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsPage> {
  // 上次备份数据，如果为null 则表示从未备份过
  BackUpModel? _lastBackUpModel;
  // WebDav配置输入框
  final TextEditingController _webDavServerController = TextEditingController();

  final TextEditingController _webDavUsernameController =
      TextEditingController();

  final TextEditingController _webDavPasswordController =
      TextEditingController();

  // 备份设置状态
  bool _autoBackupEnabled = true;
  // 所有备份信息
  late Map<String, BackUpModel> _allBackUpModels;
  // 选中待回退的备份数据
  BackUpModel? _selectedBackUpModel;

  @override
  initState() {
    super.initState();
    _allBackUpModels = {
      '2023-12-12 12:00:00': BackUpModel()
        ..type = BackUpType.auto
        ..backUpTime = DateTime(2023, 12, 12, 12, 0, 0)
        ..result = true,

      '2023-12-12 13:00:00': BackUpModel()
        ..type = BackUpType.auto
        ..backUpTime = DateTime(2023, 12, 12, 13, 0, 0)
        ..result = true,

      '2023-12-12 14:00:00': BackUpModel()
        ..type = BackUpType.manual
        ..backUpTime = DateTime(2023, 12, 12, 14, 0, 0)
        ..result = true,

      '2023-11-12 14:00:00': BackUpModel()
        ..type = BackUpType.manual
        ..backUpTime = DateTime(2023, 11, 12, 14, 0, 0)
        ..result = true,

      '2023-10-12 14:00:00': BackUpModel()
        ..type = BackUpType.manual
        ..backUpTime = DateTime(2023, 10, 12, 14, 0, 0)
        ..result = true,

      '2023-09-12 14:00:00': BackUpModel()
        ..type = BackUpType.manual
        ..backUpTime = DateTime(2023, 9, 12, 14, 0, 0)
        ..result = true,

      '2023-08-12 14:00:00': BackUpModel()
        ..type = BackUpType.manual
        ..backUpTime = DateTime(2023, 8, 12, 14, 0, 0)
        ..result = true,

      '2023-07-12 14:00:00': BackUpModel()
        ..type = BackUpType.manual
        ..backUpTime = DateTime(2023, 7, 12, 14, 0, 0)
        ..result = true,

      '2023-06-12 14:00:00': BackUpModel()
        ..type = BackUpType.manual
        ..backUpTime = DateTime(2023, 6, 12, 14, 0, 0)
        ..result = true,
    };
    _selectedBackUpModel = _allBackUpModels.values.first;
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
                child: Column(
                  children: [
                    _buildLastBackUpStatus(),
                    const SizedBox(height: 24),
                    _buildWebDavInfo(),
                    const SizedBox(height: 24),
                    _buildBackUpSetting(),
                    const SizedBox(height: 24),
                    _buildBackUpHistory(),
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
                  _lastBackUpModel?.backUpTime.toString() ?? '从未备份过',
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
              TextField(
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
              const SizedBox(height: 16),

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
                      onPressed: () {
                        // 测试连接的逻辑
                        // 可以添加连接测试逻辑，例如显示加载状态、检查连接是否成功等
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
                    print('恢复数据: $_selectedBackUpModel');
                    // 这里可以添加实际的恢复逻辑，使用_selectedBackUpModel
                  } else {
                    print('请先选择要恢复的备份');
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
          child: RadioGroup<String>(
            groupValue: _selectedBackUpModel?.dateTimeText,
            onChanged: (value) {
              setState(() {
                _selectedBackUpModel = _allBackUpModels[value];
              });
            },
            child: Column(
              children: _allBackUpModels.values
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
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
