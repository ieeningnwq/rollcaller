import './student_class_model.dart';

class StudentModel {
  int id;
  String studentNumber;
  String studentName;
  String className;
  DateTime created;

  StudentModel({
    required this.id,
    required this.studentName,
    required this.studentNumber,
    required this.className,
    required this.created,
  });

  bool isInClass(StudentClassModel studentClass) =>
      studentClass.className.contains(className);

  factory StudentModel.fromMap(Map<String, dynamic> mapData) {
    return StudentModel(
      id: mapData['id'],
      studentName: mapData['student_name'],
      studentNumber: mapData['student_number'],
      className: mapData['class_name'],
      created: mapData['created']
          ? DateTime.parse(mapData['created'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['student_number'] = studentNumber;
    data['student_name'] = studentName;
    data['class_name'] = className;
    data['created'] = created.toIso8601String();
    return data;
  }
}
