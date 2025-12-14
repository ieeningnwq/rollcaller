class KString {
  // ! 1、导航页 index_page.dart
  // tab 标题
  static const String homeTitle = '首页';
  static const String studentClassTitle = '班级';
  static const String studentTitle = '学生';
  static const String recordsTitle = '记录';
  static const String settingsTitle = '设置';
  // ! 2、主页 home_page.dart
  // 应用栏标题
  static const String homeAppBarTitle = '点名系统';
  // 主页随机点名功能开关按钮标题
  static const String callFunctionSwitchButtonTitle = '随机点名';
  // 主页签到点名功能开关按钮标题
  static const String attendanceCallFunctionSwitchButtonTitle = '签到点名';
  // ! 3、随机点名功能页面 random_call_page.dart
  static const String noStudent = '暂无学生';
  static const String noStudentNumber = '没有学号';
  static const String stopCallButtonLabel = '停止抽取';
  static const String startCallButtonLabel = '开始随机抽取';
  static const String chooseACaller = '选择点名器';
  static const String notChooseACaller = '无选中点名器';
  static const String notDuplicateSuffix = '：不可重复';
  static const String duplicateSuffix = '：可重复';
  static const String pleaseChooseACaller = '请先选择点名器';
  static const String editCaller = '编辑点名器';
  static const String addCaller = '新增点名器';
  static const String forbitDeleteCallerInfo =
      '该点名器下有随机点名记录，无法删除。请先删除该点名器下的所有随机点名记录。';
  static const String confirmDeleteCallerContent = '确定要删除选中的点名器吗？此操作不可撤销。';
  static const String minScore = '1分';
  static const String maxScore = '10分';
  static const String scoreSuffix = '分';
  static const String saveScore = '保存评分';
  static const String noDoubleCalling = '已抽取，不可重复选择';
  static const String callPrefix = '抽取：'; // '抽取'
  static const String callSuffix = '次'; // '次'
  static const String averageScorePrefix = '平均分: '; // '平均分：'
  static const String studentList = '学生列表';
    static const String pickedStudent = '已抽取学生';
  static const String notPickedStudent = '未抽取学生';
  // ! 4、签到点名功能页面 attendance_page.dart
  static const String searchStudent = '搜索学生'; // '搜索学生'
  static const String attendanceStatus = '签到状态'; // '签到状态'
  static const String totalCountPrefix = '共'; // '共'
  static const String peopleountSuffix = '人'; // '人'
  static const String attendanceStatistics = '签到统计'; // '签到统计'
  static const String forbitDeleteAttendanceCallerInfo =
      '该点名器下有签到点名记录，无法删除。请先删除该点名器下的所有签到点名记录。';
  // ! 5、学生班级页面 student_class_page.dart
  static const String studentClassAppBarTitle = '教学班级';
  static const String noStudentClass = '暂无班级'; // '暂无班级'
  static const String addStudentClass = '添加班级'; // '添加班级'
  static const String studentClassCount = '班级现有人数'; // '班级现有人数'
  static const String studentCount = '学生现有人数'; // '学生现有人数'
  static const String teacher = '教师'; // '教师现有人数'
  static const String editStudentClass = '编辑班级'; // '编辑班级'
  static const String deleteClassWarnning =
      '确定要删除班级吗？此操作不可恢复。'; // '确定要删除班级吗？此操作不可恢复。'
  static const String forbitDeleteClassWarnningDetail =
      '该班级下还有学生、随机点名器、签到点名器，无法删除。请先删除班级下的所有学生、随机点名器、签到点名器。'; // '该班级下还有学生、随机点名器、签到点名器，无法删除。请先删除班级下的所有学生、随机点名器、签到点名器。'
  static const String classFull = '班级人数已满'; // '班级人数已满'
  static const String classNotFull = '班级人数未满'; // '班级人数未满'
  static const String classOverQuantity = '班级人数超员'; // '班级人数超员'
  // ! 6、学生页面 student_page.dart
  static const String studentAppBarTitle = '学生名单管理';
  static const String addStudent = '添加学生'; // '添加学生'
  static const String noClassStudent = '无班级学生'; // '无班级学生'
  static const String searchStudentNumberOrName = '搜索学号或姓名...'; // '搜索学号或姓名...'
  static const String createTimePrefix = '创建时间：'; // '创建时间'
  static const String editStudent = '编辑学生'; // '编辑学生'
  static const String confirmDeleteStudentContent =
      '确定要删除该学生吗？此操作不可恢复。'; // '确定要删除该学生吗？此操作不可恢复。'
  static const String confirmDeleteStudentWarnningDetail =
      '该学生下有随机点名记录或签到点名记录，无法删除。请先删除该学生下的所有随机点名记录或签到点名记录。'; // '该学生下有随机点名记录或签到点名记录，无法删除。请先删除该学生下的所有随机点名记录或签到点名记录。'
  static const String studentNumber = '学号'; // '学号'
  static const String name = '姓名'; // '姓名'
  static const String className = '班级'; // '班级'
  static const String importSuccessPrefix = '成功导入 '; // '成功导入'
  static const String importSuccessSuffix = '个学生'; // '个学生'
  static const String importStudentsError = '导入学生错误'; // '导入学生错误'
  static const String pleaseGrantStoragePermission = '请授予存储权限'; // '请授予存储权限'
  static const String templateFilePathPrefix = '模板文件已复制到：'; // '模板文件已复制到：'
  // ! 7、记录页面 records_page.dart
  static const String recordAppBarTitle = '点名记录管理';
  static const String randomCallRecord = '随机点名记录';
  static const String attendanceCallRecord = '签到点名记录';
  // ! 8、随机点名记录详情页面 random_call_records_page.dart
  static const String noRandomCallRecord = '暂无随机点名记录'; // '暂无随机点名记录'
  static const String tryAdjustFilter = '请尝试调整筛选条件'; // '请尝试调整筛选条件'
  static const String classPrefix = '班级: '; // '班级：'
  static const String recordCountPrefix = '记录数：'; // '记录数：'
  static const String archive = '归档'; // '归档'
  static const String unarchived = '未归档'; // '未归档'
  static const String archived = '已归档'; // '已归档'
  static const String unknownStudent = '未知学生'; // '未知学生'
  static const String unknownStudentNumber = '未知学号'; // '未知学号'
  static const String scorePrefix = '分数: '; // '分数: '
  static const String timePrefix = '时间：'; // '时间：'
  static const String filterCondition = '筛选条件'; // '筛选条件'
  static const String resetFilter = '重置'; // '重置筛选条件'
  static const String export = '导出'; // '导出'
  static const String randomCallerPrefix= '点名器: '; // '点名器: '
  static const String all = '全部'; // '全部'
  static const String timeRangePrefix = '时间范围: '; // '时间范围'
  static const String startTime = '开始时间'; // '开始时间'
  static const String endTime = '结束时间'; // '结束时间'
  static const String to = '至'; // '至'
  static const String isArchivedPrefix = '是否归档: '; // '是否归档'
  static const String dateRangePickerTitle = '选择时间范围'; // '选择时间范围'
  static const String editScore = '编辑分数'; // '编辑分数'
  static const String score = '分数'; // '分数'
  static const String pleaseInputScore = '请输入分数'; // '请输入分数'
  static const String pleaseInputValidScore = '请输入有效的整数（1-10）'; // '请输入有效的整数（1-10）'
  static const String confirmDeleteCallerRecordContent =
      '确定要删除这条点名记录吗？此操作不可恢复。'; // '确定要删除这条点名记录吗？此操作不可恢复。'
      static const String confirmArchive = '确认归档'; // '确认归档'
  static const String confirmArchiveContent = '归档后该点名器及记录将不可修改且无法撤销，是否继续？'; // '归档后该点名器及记录将不可修改且无法撤销，是否继续？'
  static const String selectRandomCallerToExport = '选择需要导出的点名器'; // '选择需要导出的点名器'
  static const String pleaseSelectRandomCallerToExportPrefix = '请选择需要导出的点名器: '; // '请选择需要导出的点名器: '
  static const String pleaseSelectAtLeastOneRandomCaller = '请至少选择一个点名器'; // '请至少选择一个点名器'
  static const String exportColumnOrder = '序号'; // '序号'
  static const String exportColumnName = '点名器名称'; // '点名器名称'
  static const String exportColumnClassName = '班级名称'; // '班级名称'
  static const String exportColumnStudentNumber = '学生学号'; // '学生学号'
  static const String exportColumnStudentName = '学生姓名'; // '学生姓名'
  static const String exportColumnScore = '分数'; // '分数'
  static const String exportColumnTime = '点名时间'; // '时间'
  static const String exportColumnRemark = '备注'; // '备注'
  static const String noExportableRecords = '没有找到可导出的记录'; // '没有找到可导出的记录'
  static const String pleaseGrantStoragePermissionToExport = '请授予存储权限才能导出文件'; // '请授予存储权限才能导出文件'
  static const String exportFileNamePrefix = '点名记录_'; // '点名记录_'
  static const String exportSuccessPrefix = '导出成功！共导出 '; // '导出成功！共导出 '
  static const String exportSuccessSuffix = '条记录到文件: '; // '条记录'
  static const String exportFailPrefix = '导出失败：'; // '导出失败：'
  // ! 9、签到点名记录详情页面 attendance_call_records_page.dart
  static const String noAttendanceCallRecord = '暂无签到点名记录'; // '暂无签到点名记录'
  static const String exportColumnAttendanceStatus = '出席情况'; // '出席情况'
  // ! 10、设置页面 settings_page.dart











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
  // ! 公共部分
  static const String errorPrefix = '失败: ';
  static const String delete = '删除';
  static const String cancel = '取消';
  static const String deleteSuccess = '删除成功'; // '删除成功'
  static const String deleteFail = '删除失败'; // '删除失败'
  static const String studentNumberPrefix = '学号：'; // '学号'
  static const String confirmDeleteCallerTitle = '确认删除';
  static const String noData = '暂无数据...'; // '暂无数据...'
  static const String createTime = '创建时间'; // '创建时间'
  static const String edit = '编辑';
  static const String confirm = '确定'; // '确定'
  static const String save = '保存';



}
