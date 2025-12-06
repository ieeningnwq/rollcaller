class StudentClassModel {
  int? id;
  String className;
  int studentQuantity; // 学生人数，班级应该有的人数
  String teacherName;
  String notes;
  DateTime created;
  int classQuantity = 0; // 班级人数

  StudentClassModel({
    required this.className,
    required this.studentQuantity,
    required this.teacherName,
    required this.notes,
    required this.created,
    this.classQuantity = 0,
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
      classQuantity: mapData['class_quantity'] ?? 0,
    );
    if (mapData.containsKey('id')) {
      studentClass.id = mapData['id'];
    }
    return studentClass;
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) {
      data['id'] = id;
    }
    data['class_name'] = className;
    data['teacher_name'] = teacherName;
    data['student_quantity'] = studentQuantity;
    data['notes'] = notes;
    data['created'] = created.toIso8601String();
    data['class_quantity'] = classQuantity;
    return data;
  }

  @override
  toString() {
    return 'StudentClassModel(id: $id, className: $className, studentQuantity: $studentQuantity, teacherName: $teacherName, notes: $notes, created: $created, classQuantity: $classQuantity)';
  }
}
