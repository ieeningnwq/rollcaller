import 'student_class_model.dart';
import 'student_model.dart';

class StudentClassGroup {
  StudentClassModel studentClass;
  List<StudentModel> students;
  bool isExpanded = false;

  StudentClassGroup({
    required this.studentClass,
    required this.students,
    this.isExpanded = false,
  });

  factory StudentClassGroup.fromMap(Map<String, dynamic> mapData) {
    final List<StudentModel> listData = <StudentModel>[];
    if (mapData['students'] != null) {
      mapData['students'].forEach((v) {
        listData.add(StudentModel.fromMap(v));
      });
    }
    return StudentClassGroup(
      studentClass: StudentClassModel.fromMap(mapData['class']),
      students: listData,
      isExpanded: mapData['isExpanded'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['class'] = studentClass.toMap();
    data['students'] = students.map((v) => v.toMap()).toList();
    data['isExpanded'] = isExpanded;
    return data;
  }

  @override
  toString() {
    return 'StudentClassGroup(studentClass: $studentClass, students: $students)';
  }
}
