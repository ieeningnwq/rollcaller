import '../configs/attendance_status.dart';

class AttendanceCallRecordModel {
  int? id;
  int attendanceCallerId = -1;
  int studentId = -1;
  AttendanceStatus present = AttendanceStatus.absent;
  String notes = '';
  DateTime created = DateTime.now();

  AttendanceCallRecordModel();

  factory AttendanceCallRecordModel.fromMap(Map<String, dynamic> map) {
    AttendanceCallRecordModel model = AttendanceCallRecordModel()
      ..attendanceCallerId = map['attendance_caller_id']
      ..studentId = map['student_id']
      ..present = map['present'] == null
          ? AttendanceStatus.absent
          : AttendanceStatusExtension.fromInt(map['present'])
      ..notes = map['notes'] ?? ''
      ..created = map['created'] == null
          ? DateTime.now()
          : DateTime.parse(map['created']);
    if (map['id'] != null) {
      model.id = map['id'];
    }
    return model;
  }

  Map<String, dynamic> toMap() {
    var result = {
      'attendance_caller_id': attendanceCallerId,
      'student_id': studentId,
      'present': present.toInt,
      'notes': notes,
      'created': created.toIso8601String(),
    };
    if (id != null) {
      result['id'] = id!;
    }
    return result;
  }
}
