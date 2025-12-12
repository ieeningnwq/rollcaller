import '../configs/back_up_type.dart';

class BackUpModel { 
  BackUpType type = BackUpType.auto;
  String dateTimeKey = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}';
  bool result = false;
  String fileName = '';
  
  String get dateTimeText => dateTimeKey;

  static BackUpModel fromMap(Map<String, dynamic> value) => BackUpModel()
    ..type = value['type']
    ..dateTimeKey = value['dateTimeKey'] as String
    ..result = value['result'] as bool
    ..fileName = value['fileName'] as String;

  Map<String, dynamic> toMap() => {
    'type': type.index,
    'dateTimeKey': dateTimeKey,
    'result': result,
    'fileName': fileName,
  };
}