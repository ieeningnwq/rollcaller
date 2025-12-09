class AttendanceCallerModel {
  int id = -1;
  String attendanceCallerName = '';
  int classId = -1;
  int isArchive = 0;
  String notes = '';
  DateTime created = DateTime.now();

  AttendanceCallerModel();

  factory AttendanceCallerModel.fromMap(Map<String, dynamic> map) {
    AttendanceCallerModel callerModel = AttendanceCallerModel()
      ..attendanceCallerName = map['attendanceCallerName'] as String
      ..classId = map['classId'] as int
      ..isArchive = map['isArchive'] as int
      ..notes = map['notes'] as String
      ..created = DateTime.parse(map['created'] as String);
    if (map['id'] != null) {
      callerModel.id = map['id'] as int;
    }
    return callerModel;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'attendanceCallerName': attendanceCallerName,
      'classId': classId,
      'isArchive': isArchive,
      'notes': notes,
      'created': created.toIso8601String(),
    };
  }
}
