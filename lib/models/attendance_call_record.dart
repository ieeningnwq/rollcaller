class AttendanceCallRecordModel {
  int id = -1;
  int attendanceCallerId = -1;
  int studentId = -1;
  int present = 0;
  String notes = '';
  DateTime created = DateTime.now();

  AttendanceCallRecordModel();

  factory AttendanceCallRecordModel.fromMap(Map<String, dynamic> map) {
    AttendanceCallRecordModel model = AttendanceCallRecordModel()
      ..attendanceCallerId = map['attendance_caller_id']
      ..studentId = map['student_id']
      ..present = map['present']
      ..notes = map['notes']
      ..created = DateTime.parse(map['created']);

    if (map['id'] != null) {
      model.id = map['id'];
    }
    return model;
  }

  Map<String, Object> toMap() {
    return {
      'id': id,
      'attendance_caller_id': attendanceCallerId,
      'student_id': studentId,
      'present': present,
      'notes': notes,
      'created': created.toIso8601String(),
    };
  }
}
