import 'package:flutter/material.dart';
import 'package:rollcall/providers/class_groups_provider.dart';
import 'package:rollcall/widgets/student_item_widget.dart';

import '../models/student_class_group.dart';

class StudentPageClassItem extends StatelessWidget {
  final ClassGroupsProvider classGroupsProvider;
  final int groupIndex;

  final TextEditingController studentNameController;
  final TextEditingController studentNumberController;

  const StudentPageClassItem({
    super.key,
    required this.classGroupsProvider,
    required this.groupIndex,
    required this.studentNameController,
    required this.studentNumberController,
  });

  @override
  Widget build(BuildContext context) {
    final group = classGroupsProvider.filterClassGroups[groupIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _classTitleWidget(group),
        if (group.isExpanded)
          Column(
            children: group.students.map((student) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: StudentItemWidget(
                  student: student,
                  studentNameController: studentNameController,
                  studentNumberController: studentNumberController,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  GestureDetector _classTitleWidget(StudentClassGroup group) => GestureDetector(
    onTap: () => classGroupsProvider.changeExpanded(groupIndex),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            group.studentClass.className,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            '${group.students.length}人',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    ),
  );
}
