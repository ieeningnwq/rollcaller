import 'student_class_model.dart';

class StudentModel {
  int? id;
  String studentNumber;
  String studentName;
  DateTime created;
  Map<int,StudentClassModel> classesMap = {};

  StudentModel({
    required this.studentName,
    required this.studentNumber,
    required this.created,
  });

  List<StudentClassModel> get allClasses => classesMap.values.toList();


  factory StudentModel.fromMap(Map<String, dynamic> mapData) {
    var studentModel = StudentModel(
      studentName: mapData['student_name'],
      studentNumber: mapData['student_number'],
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
    if (id != null) {
      data['id'] = id;
    }
    data['student_number'] = studentNumber;
    data['student_name'] = studentName;
    data['created'] = created.toIso8601String();
    return data;
  }

  @override
  toString() {
    return 'StudentModel(id: $id, studentNumber: $studentNumber, studentName: $studentName, created: $created)';
  }
}
