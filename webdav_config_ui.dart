import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  runApp(
    ScreenUtilInit(
      designSize: const Size(540, 960),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return const MaterialApp(
          home: WebDavConfigPage(),
          debugShowCheckedModeBanner: false,
        );
      },
    ),
  );
}

class WebDavConfigPage extends StatefulWidget {
  const WebDavConfigPage({Key? key}) : super(key: key);

  @override
  State<WebDavConfigPage> createState() => _WebDavConfigPageState();
}

class _WebDavConfigPageState extends State<WebDavConfigPage> {
  // 存储选中的备份时间
  String? _selectedBackupTime;
  
  // 备份设置状态
  bool _autoBackupEnabled = true;
  String _backupFrequency = '每天备份';
  bool _backupOnExit = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebDAV配置'),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
        titleTextStyle: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 备份状态显示
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(6.w),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 18.w,
                  ),
                  SizedBox(width: 6.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '上次备份成功',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                          fontSize: 14.sp,
                        ),
                      ),
                      Text(
                        '2024-05-20 22:00',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // WebDAV配置标题
            Text(
              'WebDAV配置',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16.h),

            // 输入框容器
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6.w),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1.w,
                    blurRadius: 2.w,
                    offset: Offset(0, 1.w),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // WebDAV服务器地址输入框
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'WebDAV服务器地址',
                      labelStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14.sp,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.w),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.w),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.w),
                        borderSide: BorderSide(
                          color: Colors.purple,
                          width: 2.w,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 12.h,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // 用户名输入框
                  TextField(
                    decoration: InputDecoration(
                      labelText: '用户名',
                      labelStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14.sp,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.w),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.w),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.w),
                        borderSide: BorderSide(
                          color: Colors.purple,
                          width: 2.w,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 12.h,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // 密码输入框
                  TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: '密码',
                      labelStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14.sp,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.w),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.w),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.w),
                        borderSide: BorderSide(
                          color: Colors.purple,
                          width: 2.w,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 12.h,
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
                          onPressed: () {
                            // 测试连接的逻辑
                            print('测试连接');
                            // 可以添加连接测试逻辑，例如显示加载状态、检查连接是否成功等
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: 12.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.w),
                            ),
                            side: BorderSide(
                              color: Colors.purple,
                              width: 1.w,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.network_check,
                                color: Colors.purple,
                                size: 16.w,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                '测试连接',
                                style: TextStyle(
                                  color: Colors.purple,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                       
                      // 保存配置按钮
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // 保存配置的逻辑
                            print('保存配置');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            padding: EdgeInsets.symmetric(
                              vertical: 12.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.w),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.save,
                                color: Colors.white,
                                size: 16.w,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                '保存配置',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.sp,
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
            SizedBox(height: 16.h),
            
            // 备份设置
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6.w),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1.w,
                    blurRadius: 2.w,
                    offset: Offset(0, 1.w),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 备份设置标题
                  Text(
                    '备份设置',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12.h),
                   
                  // 自动备份选项
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '自动备份',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black87,
                        ),
                      ),
                      Switch(
                        value: _autoBackupEnabled,
                        onChanged: (value) {
                          setState(() {
                            _autoBackupEnabled = value;
                          });
                        },
                        activeColor: Colors.purple,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  // 提示语句
                  Text(
                    '若打开自动备份则每次推出app时自动备份',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey[500],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  
                  // 备份频率下拉选择
                  if (_autoBackupEnabled) // 只有开启自动备份时显示
                    Padding(
                      padding: EdgeInsets.only(left: 0),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(6.w),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _backupFrequency,
                            onChanged: (String? newValue) {
                              setState(() {
                                _backupFrequency = newValue!;
                              });
                            },
                            items: <String>['每天备份', '每周备份', '每月备份']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.black87,
                                  ),
                                ),
                              );
                            }).toList(),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: Colors.black87,
                              size: 20.w,
                            ),
                            isExpanded: true,
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: 10.h),
                   
                  // 退出时备份选项
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '退出时备份',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black87,
                        ),
                      ),
                      Checkbox(
                        value: _backupOnExit,
                        onChanged: (bool? value) {
                          setState(() {
                            _backupOnExit = value!;
                          });
                        },
                        activeColor: Colors.purple,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // 备份和恢复按钮
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // 手动备份逻辑
                      print('手动备份');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: EdgeInsets.symmetric(
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.w),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      '手动备份',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // 恢复数据逻辑
                      if (_selectedBackupTime != null) {
                        print('恢复数据: $_selectedBackupTime');
                        // 这里可以添加实际的恢复逻辑，使用_selectedBackupTime
                      } else {
                        print('请先选择要恢复的备份');
                        // 可以显示提示信息
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('请先选择要恢复的备份'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.w),
                      ),
                      side: BorderSide(
                        color: Colors.grey,
                        width: 1.w,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restore,
                          color: Colors.black87,
                          size: 16.w,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '恢复数据',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 备份历史标题
            const Text(
              '备份历史',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 10.h),

            // 备份历史列表容器
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6.w),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1.w,
                    blurRadius: 2.w,
                    offset: Offset(0, 1.w),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 备份历史记录项
                  buildBackupHistoryItem('2024-05-20 22:00', '自动备份'),
                  Divider(height: 20.h, thickness: 1.w, color: Colors.grey),
                  buildBackupHistoryItem('2024-05-19 22:00', '自动备份'),
                  Divider(height: 20.h, thickness: 1.w, color: Colors.grey),
                  buildBackupHistoryItem('2024-05-18 15:30', '手动备份'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建备份历史记录项的方法
  Widget buildBackupHistoryItem(String time, String type) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              time,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              type,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        Radio(
          value: time,
          groupValue: _selectedBackupTime,
          onChanged: (String? value) {
            setState(() {
              _selectedBackupTime = value;
            });
          },
          activeColor: Colors.purple,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}