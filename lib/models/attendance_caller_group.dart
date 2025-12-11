import 'attendance_call_record.dart';
import 'attendance_caller_model.dart';
import 'student_class_model.dart';
import 'student_model.dart';

class AttendanceCallerGroupModel {
  final AttendanceCallerModel attendanceCallerModel;
  final StudentClassModel studentClassModel;
  Map<int, StudentModel> students = {};
  Map<int, AttendanceCallRecordModel> attendanceCallRecords = {};
  bool isExpanded = false;

  AttendanceCallerGroupModel({
    required this.attendanceCallerModel,
    required this.studentClassModel,
    required this.attendanceCallRecords,
    required this.students,
  });

  List<AttendanceCallRecordModel> get allRecords =>
      attendanceCallRecords.values.toList();
}
