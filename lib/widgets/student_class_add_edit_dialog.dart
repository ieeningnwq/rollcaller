import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/student_class_model.dart';
import '../providers/student_class_provider.dart';
import '../utils/student_class_dao.dart';

class StudentClassAddEditDialog extends StatelessWidget {
  final StudentClassModel studentClass;
  final String title;
  late final bool isAdd;
  final StudentClassProvider studentClassProvider;
  

  final TextEditingController classNameController;
  final TextEditingController studentQuantityController ;
  final TextEditingController teacherNameController;
  final TextEditingController notesController;
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();


  StudentClassAddEditDialog({super.key, required this.studentClass, required this.title, required this.studentClassProvider, required this.classNameController, required this.teacherNameController, required this.notesController, required this.studentQuantityController}){
    isAdd = title == '添加班级';
  }

  @override
  Widget build(BuildContext context) {
    classNameController.text = studentClass.className;
    studentQuantityController.text = studentClass.studentQuantity.toString();
    teacherNameController.text = studentClass.teacherName;
    notesController.text = studentClass.notes;
    return AlertDialog(
      title:  Text(title),
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildClassNameInfoRow('班级名称（必填）', ),
            _buildClassQuantityInfoRowInt('学生数量（必填）'),
            _buildInfoRow('教师姓名（可选）', teacherNameController),
            _buildInfoRow('备注（可选）', notesController),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();(context);
          },
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
            // 处理添加/编辑学生班级的逻辑
            await _saveOnPressed();
            if(context.mounted){
              Navigator.of(context).pop();(context);
            }
            }
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
  
  Padding _buildInfoRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
              decoration: InputDecoration(labelText: label),
              controller: controller,
            ),
            );
  }
  
  
  Padding _buildClassNameInfoRow(String label) {
    bool isClassNameUnique=true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
              decoration: InputDecoration(labelText: label),
              controller: classNameController,
              autovalidateMode: AutovalidateMode.onUnfocus,
              onChanged: (value) {
                WidgetsFlutterBinding.ensureInitialized(); // 确保初始化Flutter绑定。对于插件很重要。
                var classDao = StudentClassDao(); // 创建StudentClassDao实例。
                classDao
                    .isStudentClassesNameExist(value)
                    .then(
                      (onValue) => {
                        if (onValue)
                          {
                            if (!isAdd &&
                                (classNameController.text == studentClass.className))
                              isClassNameUnique = true
                            else
                              isClassNameUnique = false,
                          }
                        else
                          isClassNameUnique = true,
                      },
                    );
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '班级名称不能为空';
                }
                if (!isClassNameUnique) {
                  return '$value重复使用';
                }
                return null; // 如果没有找到重复值，返回null表示验证通过
              },
            ),
            );
  }
  
  Padding _buildClassQuantityInfoRowInt(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
              keyboardType: TextInputType.number,
              // 设置键盘类型为数字键盘
              inputFormatters: <TextInputFormatter>[
                // 添加输入格式化器以限制输入为数字
                FilteringTextInputFormatter.digitsOnly, // 只允许输入数字
              ],
              decoration: InputDecoration(labelText: label),
              controller: studentQuantityController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '学生人数不能为空';
                }
                return null;
              },
            ),
            );
  }

  Future<void> _saveOnPressed() async {
    
      // 表单验证通过，执行添加/编辑操作
      studentClass.className=classNameController.text;
      studentClass.studentQuantity=int.parse(studentQuantityController.text);
      studentClass.teacherName=teacherNameController.text;
      studentClass.notes=notesController.text;
        // 获取数据库dao
      var classDao = StudentClassDao(); // 创建StudentClassDao实例。

      if (isAdd) {
        // 添加操作
        studentClass.created=DateTime.now();
        int id=await classDao.insertStudentClass(
                  studentClass
                );
        studentClass.id=id;
        // 添加班级列表
        studentClassProvider.addStudentClass(
          studentClass,
        );
      } else {
        // 更新操作
        await classDao.updateStudentClassById(
                  studentClass,
                );
          studentClassProvider.updateStudentClass(
          studentClass,
        );
      }
      
      
    
  }

  void dispose(){
    classNameController.dispose();
    studentQuantityController.dispose();
    teacherNameController.dispose();
    notesController.dispose();
  }
}