import '../configs/back_up_type.dart';

class BackUpModel {
  BackUpType type = BackUpType.auto;
  DateTime backUpTime = DateTime.now();
  bool result = false;

  String get dateTimeText => '${backUpTime.year}-${backUpTime.month.toString().padLeft(2, '0')}-${backUpTime.day.toString().padLeft(2, '0')} ${backUpTime.hour.toString().padLeft(2, '0')}:${backUpTime.minute.toString().padLeft(2, '0')}:${backUpTime.second.toString().padLeft(2, '0')}';
}