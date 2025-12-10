import 'random_call_record.dart';
import 'random_caller_model.dart';
import 'student_class_model.dart';
import 'student_model.dart';

class RandomCallerGroupModel {
  final RandomCallerModel randomCallerModel;
  final StudentClassModel studentClassModel;
  Map<int, StudentModel> students = {};
  Map<int, List<RandomCallRecordModel>> randomCallRecords = {};
  bool isExpanded = false;
  RandomCallerGroupModel({
    required this.randomCallerModel,
    required this.students,
    required this.studentClassModel,
    required this.randomCallRecords,
  });

  List<RandomCallRecordModel> get allRecords {
    List<RandomCallRecordModel> records = [];
    for (var recordList in randomCallRecords.values) {
      records.addAll(recordList);
    }
    // 按照时间排序
    records.sort((a, b) => a.created.compareTo(b.created));
    return records;
  }

  @override
  String toString() {
    return 'RandomCallerGroupModel(randomCallerModel: $randomCallerModel, studentClassModel: $studentClassModel, students: $students, randomCallRecords: $randomCallRecords)';
  }
}
