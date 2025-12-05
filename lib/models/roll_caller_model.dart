class RollCallerModel {
  int? id;
  String randomCallerName;
  int classId;
  String notes;
  DateTime created;

  RollCallerModel({
    this.id,
    required this.randomCallerName,
    required this.classId,
    required this.notes,
    required this.created,
  });

  factory RollCallerModel.fromMap(Map<String, dynamic> map) {
    RollCallerModel rollCallerModel = RollCallerModel(
      randomCallerName: map['random_caller_name'],
      classId: map['class_id'],
      notes: map['notes'],
      created: DateTime.parse(map['created']),
    );
    if (map.containsKey('id')) {
      rollCallerModel.id = map['id'];
    }
    return rollCallerModel;
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) {
      data['id'] = id;
    }
    data['random_caller_name'] = randomCallerName;
    data['class_id'] = classId;
    data['notes'] = notes;
    data['created'] = created.toIso8601String();
    return data;
  }
}