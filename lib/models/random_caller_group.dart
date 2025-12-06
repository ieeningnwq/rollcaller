import 'random_call_record.dart';
import 'random_caller_model.dart';
import 'student_class_model.dart';
import 'student_model.dart';

class RandomCallerGroupModel {
  final RandomCallerModel randomCallerModel;
  final StudentClassModel studentClassModel;
  List<StudentModel> students = [];
  Map<int, List<RandomCallRecordModel>> randomCallRecords = {};
  RandomCallerGroupModel({
    required this.randomCallerModel,
    required this.students,
    required this.studentClassModel,
    required this.randomCallRecords,
  });

  @override
  String toString() {
    return 'RandomCallerGroupModel(randomCallerModel: $randomCallerModel, studentClassModel: $studentClassModel, students: $students, randomCallRecords: $randomCallRecords)';
  }
}
