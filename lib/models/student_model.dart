import 'student_class_model.dart';

class StudentModel {
  int? id;
  String studentNumber;
  String studentName;
  String className;
  DateTime created;

  StudentModel({
    required this.studentName,
    required this.studentNumber,
    required this.className,
    required this.created,
  });

  bool isInClass(StudentClassModel studentClass) =>
      studentClass.className.contains(className);

  factory StudentModel.fromMap(Map<String, dynamic> mapData) {
    var studentModel = StudentModel(
      studentName: mapData['student_name'],
      studentNumber: mapData['student_number'],
      className: mapData['class_name'],
      created: mapData['created'] != null
          ? DateTime.parse(mapData['created'])
          : DateTime.now(),
    );
    if (mapData.containsKey('id')) {
      studentModel.id = mapData['id'];
    }
    return studentModel;
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
