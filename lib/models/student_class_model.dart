import './Student_model.dart';

class StudentClassModel {
  int? id;
  String className;
  int studentQuantity;
  String teacherName;
  String notes;
  DateTime created;

  StudentClassModel({
    required this.className,
    required this.studentQuantity,
    required this.teacherName,
    required this.notes,
    required this.created,
  });

  factory StudentClassModel.fromMap(Map<String, dynamic> mapData) {
    var studentClass = StudentClassModel(
      className: mapData['class_name'],
      teacherName: mapData['teacher_name'],
      studentQuantity: mapData['student_quantity'],
      notes: mapData['notes'] ?? '',
      created: mapData['created'] != null
          ? DateTime.parse(mapData['created'])
          : DateTime.now(),
    );
    if (mapData.containsKey('id')) {
      studentClass.id = mapData['id'];
    }
    return studentClass;
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['class_name'] = className;
    data['teacher_name'] = teacherName;
    data['student_quantity'] = studentQuantity;
    data['notes'] = notes;
    data['created'] = created.toIso8601String();
    return data;
  }

  bool isStudentIn(StudentModel student) =>
      className.contains(student.className);
}
