import 'student_class_model.dart';
import 'student_model.dart';

class StudentClassListItem {
  StudentClassModel studentClass;
  List<StudentModel> students;

  StudentClassListItem({required this.studentClass, required this.students});

  factory StudentClassListItem.fromMap(Map<String, dynamic> mapData) {
    final List<StudentModel> listData = <StudentModel>[];
    if (mapData['students'] != null) {
      mapData['students'].forEach((v) {
        listData.add(StudentModel.fromMap(v));
      });
    }
    return StudentClassListItem(
      studentClass: StudentClassModel.fromMap(mapData['class']),
      students: listData,
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['class'] = studentClass.toMap();
    data['students'] = students.map((v) => v.toMap()).toList();
    return data;
  }
}
