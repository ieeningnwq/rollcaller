import 'package:flutter/material.dart';
import 'package:rollcall/utils/student_class_dao.dart';

import '../models/random_call_record.dart';
import '../models/random_caller_group.dart';
import '../models/random_caller_model.dart';
import '../models/student_class_model.dart';
import '../models/student_model.dart';
import '../utils/random_call_record_dao.dart';
import '../utils/student_dao.dart';

class RandomCallerProvider with ChangeNotifier {
  final Map<int, RandomCallerModel> _randomCallers = {};
  RandomCallerModel? _selectedCaller;

  RandomCallerModel? get selectedCaller => _selectedCaller;

  int _selectedClassId = -1;
  int get selectedClassId => _selectedClassId;


  void updateSelectedClassId(int value) {
    _selectedClassId = value;
    notifyListeners();
  }

  void selectedClassIdWithoutNotify(int value) {
    _selectedClassId = value;
  }

  Future<RandomCallerModel?> getSelectorCallerAsyc() async {
    while (_selectedCaller == null) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return _selectedCaller;
  }

  Future<RandomCallerGroupModel> getSelectorCallerClassStudents() async {
    while (_selectedCaller == null) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    final RandomCallerModel randomCallerModel;
    StudentClassModel studentClassModel;
    List<StudentModel> studentList;
    Map<int, List<RandomCallRecordModel>> randomCallRecords = {};
    randomCallerModel = _selectedCaller!;
    return await StudentClassDao()
        .getStudentClass(_selectedCaller!.classId)
        .then((studentClass) async {
          studentClassModel = studentClass;
          return (StudentDao().getAllStudentsByClassName(
            studentClassModel.className,
          )).then((students) {
            List<StudentModel> studentModels = students
                .map((e) => StudentModel.fromMap(e))
                .toList();
            studentList = studentModels;
            for (var element in studentModels) {
              RandomCallRecordDao()
                  .getRecordsByCallerIdStudentId(
                    randomCallerModel.id!,
                    element.id!,
                  )
                  .then((records) {
                    randomCallRecords[element.id!] = records;
                  });
            }
            return RandomCallerGroupModel(
              randomCallerModel: randomCallerModel,
              students: studentList,
              studentClassModel: studentClassModel,
              randomCallRecords: randomCallRecords,
            );
          });
        });
  }

  Map<int, RandomCallerModel> get randomCallers => _randomCallers;

  void updateRandomCallerWithoutNotify(RandomCallerModel randomCallerModel) {
    if (randomCallerModel.id == null) {
      return;
    }
    _randomCallers[randomCallerModel.id!] = randomCallerModel;
  }

  void updateRandomCaller(RandomCallerModel randomCallerModel) {
    if (randomCallerModel.id == null) {
      return;
    }
    _randomCallers[randomCallerModel.id!] = randomCallerModel;
    notifyListeners();
  }

  void addRandomCaller(RandomCallerModel randomCaller) {
    if (randomCaller.id == null) {
      return;
    }
    _randomCallers[randomCaller.id!] = randomCaller;
    notifyListeners();
  }

  void removeRandomCaller(int id) {
    _randomCallers.remove(id);
    notifyListeners();
  }

  void setCurrentSelectedCallerWithoutNotify(int id) {
    _selectedCaller = _randomCallers[id];
  }

  void setCurrentSelectedCaller(int id) {
    setCurrentSelectedCallerWithoutNotify(id);
    notifyListeners();
  }
}
