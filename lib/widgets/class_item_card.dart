import 'package:flutter/material.dart';
import 'package:rollcall/models/student_class_model.dart';

import '../providers/student_class_provider.dart';
import '../utils/student_class_dao.dart';
import '../utils/student_dao.dart';
import 'student_class_add_edit_dialog.dart';

class ClassItemCard extends StatelessWidget {
  final StudentClassProvider studentClassProvider;
  final int index;
    final TextEditingController classNameController;
  final TextEditingController studentQuantityController ;
  final TextEditingController teacherNameController;
  final TextEditingController notesController;
  const ClassItemCard({super.key, required this.studentClassProvider, required this.index, required this.classNameController, required this.studentQuantityController, required this.teacherNameController, required this.notesController});
  @override
  Widget build(BuildContext context) {
    var studentClass = studentClassProvider.studentClassesList[index];

    return Card(
      elevation: 2.0,
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),

      child:  Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部：班级名称和人数已满标签
            _classNameQuantityStatusWidget(
              studentClass,
              studentClassProvider.icon[index],
              studentClassProvider.color[index],
              studentClassProvider.quantityInfo[index],
              studentClassProvider.deprecationColor[index],
            ),
            // 中间：班级信息
            _classInfoWidget(studentClass),
            SizedBox(height: 16.0),
            // 班级备注
            Text(
              studentClass.notes,
              style: TextStyle(fontSize: 14.0, color: Colors.grey.shade700),
            ),
            SizedBox(height: 16.0),
            // 底部操作按钮
            _actionsWidget(context,studentClass),
          ],
        ),
      ),
    );
  }

  Row _actionsWidget(BuildContext context,StudentClassModel studentClass)=>Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // 编辑按钮点击事件
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return StudentClassAddEditDialog(studentClass: studentClass, title: '编辑班级', studentClassProvider: studentClassProvider, classNameController: classNameController, teacherNameController: teacherNameController, notesController: notesController, studentQuantityController: studentQuantityController,);
                      },
                    );
                  },
                  icon: Icon(Icons.edit, color: Colors.blue),
                  label: Text('编辑', style: TextStyle(color: Colors.blue)),
                ),
                SizedBox(width: 8.0),
                TextButton.icon(
                  onPressed: () {
                    var classDao = StudentClassDao(); // 创建StudentClassDao实例。
                    // 删除按钮点击事件
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('确认删除'),
                          content: Text(
                            '确定要删除班级“${studentClass.className}”吗？此操作不可恢复。',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('取消'),
                            ),
                            TextButton(
                              onPressed: () async {
                                // 校验该班级下是否还有学生
                                var studentDao = StudentDao();
                                var students = await studentDao
                                    .getAllStudentsByClassName(
                                      studentClass.className,
                                    );
                                if (students.isEmpty) {
                                  await classDao.deleteStudentClassByClassName(
                                    studentClass.className,
                                  );
                                  studentClassProvider.removeStudentClass(
                                    studentClass.id!,
                                  );
                                  if(context.mounted){
                                    Navigator.of(context).pop(); // 关闭确认弹窗
                                  }
                                } else {
                                  // 班级下还有学生，提示用户先删除学生
                                  if (context.mounted) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text('提示'),
                                          content: Text(
                                            '该班级下还有学生，无法删除。请先删除班级下的所有学生。',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  {Navigator.of(context).pop(),
                                                  Navigator.of(context).pop(),
},
                                              child: Text('确定'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                   // 关闭确认弹窗
                                }
                              },
                              child: Text(
                                '删除',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: Icon(Icons.delete, color: Colors.red),
                  label: Text('删除', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          

  Row _classNameQuantityStatusWidget(StudentClassModel studentClass,Icon statusIcon,Color statusColor,String quantityInfo,Color deprecationColor)=>Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  studentClass.className,
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: deprecationColor,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    children: [
                      studentClassProvider.icon[index],
                      SizedBox(width: 4.0),
                      Text(
                        quantityInfo,
                        style: TextStyle(
                          fontSize: 12.0,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );


  Row _classInfoWidget(StudentClassModel studentClass)=>Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '班级现有人数',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      '${studentClass.classQuantity}',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 12.0),
                    Text(
                      '学生现有人数',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      '${studentClass.studentQuantity}',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '教师',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      studentClass.teacherName,
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 12.0),
                    Text(
                      '创建时间',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      '${studentClass.created.year}-${studentClass.created.month.toString().padLeft(2, '0')}-${studentClass.created.day.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            );        
}
