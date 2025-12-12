import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' hide context;
import 'package:path_provider/path_provider.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

/// WebDAV备份恢复工具
class WebDavBackupRestore {
  static const String backupFileName = 'sqlite_backup.json';
  
  /// 备份所有数据表到WebDAV
  static Future<void> backupToWebDav({
    required Database db,
    required String webdavUrl,
    required String username,
    required String password,
  }) async {
    try {
      // 1. 导出所有数据表
      final backupData = await _exportAllTables(db);
      
      // 2. 转换为JSON字符串
      final jsonString = json.encode(backupData);
      
      // 3. 保存到临时文件
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$backupFileName');
      await tempFile.writeAsString(jsonString);
      
      // 4. 上传到WebDAV
      await _uploadToWebDav(
        file: tempFile,
        webdavUrl: webdavUrl,
        username: username,
        password: password,
      );
      
      print('备份成功！');
    } catch (e) {
      print('备份失败: $e');
      rethrow;
    }
  }
  
  /// 从WebDAV恢复所有数据表
  static Future<void> restoreFromWebDav({
    required Database db,
    required String webdavUrl,
    required String username,
    required String password,
  }) async {
    try {
      // 1. 从WebDAV下载备份文件
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$backupFileName');
      
      await _downloadFromWebDav(
        savePath: tempFile.path,
        webdavUrl: webdavUrl,
        username: username,
        password: password,
      );
      
      // 2. 读取并解析JSON
      final jsonString = await tempFile.readAsString();
      final backupData = json.decode(jsonString);
      
      // 3. 恢复所有数据表
      await _restoreAllTables(db, backupData);
      
      print('恢复成功！');
    } catch (e) {
      print('恢复失败: $e');
      rethrow;
    }
  }
  
  /// 导出所有数据表
  static Future<Map<String, List<Map<String, dynamic>>>> _exportAllTables(Database db) async {
    final backupData = <String, List<Map<String, dynamic>>>{};
    
    // 导出各个数据表
    backupData['student_class'] = await db.query('student_class');
    backupData['student'] = await db.query('student');
    backupData['random_caller'] = await db.query('random_caller');
    backupData['random_caller_record'] = await db.query('random_caller_record');
    backupData['attendance_caller'] = await db.query('attendance_caller');
    backupData['attendance_caller_record'] = await db.query('attendance_caller_record');
    
    return backupData;
  }
  
  /// 恢复所有数据表
  static Future<void> _restoreAllTables(
    Database db,
    Map<String, dynamic> backupData,
  ) async {
    // 开始事务
    await db.transaction((txn) async {
      // 清空所有数据表（按依赖顺序）
      await txn.execute('DELETE FROM attendance_caller_record');
      await txn.execute('DELETE FROM random_caller_record');
      await txn.execute('DELETE FROM attendance_caller');
      await txn.execute('DELETE FROM random_caller');
      await txn.execute('DELETE FROM student');
      await txn.execute('DELETE FROM student_class');
      
      // 重置自增ID
      await txn.execute('DELETE FROM sqlite_sequence');
      
      // 恢复各个数据表（按依赖顺序）
      await _restoreTable(txn, 'student_class', backupData['student_class']);
      await _restoreTable(txn, 'student', backupData['student']);
      await _restoreTable(txn, 'random_caller', backupData['random_caller']);
      await _restoreTable(txn, 'random_caller_record', backupData['random_caller_record']);
      await _restoreTable(txn, 'attendance_caller', backupData['attendance_caller']);
      await _restoreTable(txn, 'attendance_caller_record', backupData['attendance_caller_record']);
    });
  }
  
  /// 恢复单个数据表
  static Future<void> _restoreTable(
    Transaction txn,
    String tableName,
    dynamic data,
  ) async {
    if (data == null || !(data is List)) return;
    
    final batch = txn.batch();
    
    for (final Map<String, dynamic> row in data) {
      batch.insert(tableName, row);
    }
    
    await batch.commit(noResult: true);
  }
  
  /// 上传文件到WebDAV
  static Future<void> _uploadToWebDav({
    required File file,
    required String webdavUrl,
    required String username,
    required String password,
  }) async {
    // 初始化WebDAV客户端
    final client = webdav.newClient(webdavUrl, user: username, password: password);
    
    // 上传文件
    // await client.writeFromFile(file.path, '/$backupFileName', cancelToken: c);
    
    // 关闭客户端
    // client.close();
  }
  
  /// 从WebDAV下载文件
  static Future<void> _downloadFromWebDav({
    required String savePath,
    required String webdavUrl,
    required String username,
    required String password,
  }) async {
    // 初始化WebDAV客户端
    final client = webdav.newClient(webdavUrl, user: username, password: password);
    
    // 下载文件
    await client.read2File('/$backupFileName', savePath);
    
    // 关闭客户端
    // client.close();
  }
  
  /// 测试WebDAV连接
  static Future<bool> testConnection({
    required String webdavUrl,
    required String username,
    required String password,
  }) async {
    try {
      final client = webdav.newClient(webdavUrl, user: username, password: password);
      
      // 尝试获取目录列表
      await client.readDir('/');
      
      // client.close();
      return true;
    } catch (e) {
      print('WebDAV连接失败: $e');
      return false;
    }
  }
  
  /// 获取备份文件信息
  static Future<DateTime?> getBackupFileInfo({
    required String webdavUrl,
    required String username,
    required String password,
  }) async {
    try {
      final client = webdav.newClient(webdavUrl, user: username, password: password);
      
      // 获取文件属性
      final prop = await client.readProps('/$backupFileName');


      client.c.close();
      
      // client.close();
      
      // return prop.mtime;
    } catch (e) {
      print('获取备份文件信息失败: $e');
      return null;
    }
  }
}

/// 示例用法
void main() {
  runApp(const MaterialApp(
    home: BackupRestoreExample(),
  ));
}

/// 示例界面
class BackupRestoreExample extends StatefulWidget {
  const BackupRestoreExample({Key? key}) : super(key: key);
  
  @override
  State<BackupRestoreExample> createState() => _BackupRestoreExampleState();
}

class _BackupRestoreExampleState extends State<BackupRestoreExample> {
  final _webdavUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  Database? _db;
  bool _isLoading = false;
  DateTime? _lastBackupDate;
  
  @override
  void initState() {
    super.initState();
    _initDatabase();
  }
  
  @override
  void dispose() {
    _webdavUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _db?.close();
    super.dispose();
  }
  
  /// 初始化示例数据库
  Future<void> _initDatabase() async {
    final dbPath = join(await getDatabasesPath(), 'example.db');
    
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) {
        // 创建示例数据表
        db.execute('''
          CREATE TABLE student_class (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            class_name TEXT NOT NULL,
            student_quantity INTEGER NOT NULL,
            teacher_name TEXT,
            notes TEXT,
            created TEXT NOT NULL
          )
        ''');
        
        db.execute('''
          CREATE TABLE student (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_number TEXT NOT NULL,
            student_name TEXT NOT NULL,
            class_name TEXT,
            created TEXT NOT NULL
          )
        ''');
        
        db.execute('''
          CREATE TABLE random_caller (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            random_caller_name TEXT NOT NULL,
            is_duplicate INTEGER NOT NULL DEFAULT 0,
            class_id INTEGER NOT NULL,
            is_archive INTEGER NOT NULL DEFAULT 0,
            notes TEXT,
            created TEXT NOT NULL
          )
        ''');
        
        db.execute('''
          CREATE TABLE random_caller_record (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            random_caller_id INTEGER NOT NULL,
            student_id INTEGER NOT NULL,
            score INTEGER NOT NULL,
            notes TEXT,
            created TEXT NOT NULL
          )
        ''');
        
        db.execute('''
          CREATE TABLE attendance_caller (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            attendance_caller_name TEXT NOT NULL,
            class_id INTEGER NOT NULL,
            is_archive INTEGER NOT NULL DEFAULT 0,
            notes TEXT,
            created TEXT NOT NULL
          )
        ''');
        
        db.execute('''
          CREATE TABLE attendance_caller_record (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            attendance_caller_id INTEGER NOT NULL,
            student_id INTEGER NOT NULL,
            present INTEGER NOT NULL,
            notes TEXT,
            created TEXT NOT NULL
          )
        ''');
      },
    );
  }
  
  /// 备份操作
  Future<void> _backup() async {
    if (_db == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      await WebDavBackupRestore.backupToWebDav(
        db: _db!,
        webdavUrl: _webdavUrlController.text,
        username: _usernameController.text,
        password: _passwordController.text,
      );
      
      // 更新最后备份日期
      _lastBackupDate = await WebDavBackupRestore.getBackupFileInfo(
        webdavUrl: _webdavUrlController.text,
        username: _usernameController.text,
        password: _passwordController.text,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('备份成功！')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('备份失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  /// 恢复操作
  Future<void> _restore() async {
    if (_db == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      await WebDavBackupRestore.restoreFromWebDav(
        db: _db!,
        webdavUrl: _webdavUrlController.text,
        username: _usernameController.text,
        password: _passwordController.text,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('恢复成功！')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('恢复失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  /// 测试连接
  Future<void> _testConnection() async {
    setState(() => _isLoading = true);
    
    try {
      final isConnected = await WebDavBackupRestore.testConnection(
        webdavUrl: _webdavUrlController.text,
        username: _usernameController.text,
        password: _passwordController.text,
      );
      
      if (isConnected) {
        // 获取备份文件信息
        _lastBackupDate = await WebDavBackupRestore.getBackupFileInfo(
          webdavUrl: _webdavUrlController.text,
          username: _usernameController.text,
          password: _passwordController.text,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WebDAV连接成功！')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WebDAV连接失败！')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('连接测试失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebDAV备份恢复示例')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _webdavUrlController,
              decoration: const InputDecoration(
                labelText: 'WebDAV地址',
                hintText: 'https://example.com/webdav',
              ),
            ),
            
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: '用户名',
              ),
            ),
            
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: '密码',
              ),
              obscureText: true,
            ),
            
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _testConnection,
              child: const Text('测试连接'),
            ),
            
            ElevatedButton(
              onPressed: _backup,
              child: const Text('备份到WebDAV'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
            
            ElevatedButton(
              onPressed: _restore,
              child: const Text('从WebDAV恢复'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
            ),
            
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            
            if (_lastBackupDate != null)
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text('最后备份时间: $_lastBackupDate'),
              ),
          ],
        ),
      ),
    );
  }
}


