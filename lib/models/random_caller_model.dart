class RandomCallerModel {
  int? id;
  String randomCallerName;
  int classId;
  int isDuplicate;
  int isArchive;
  String notes;
  DateTime created;

  RandomCallerModel({
    this.id,
    required this.randomCallerName,
    required this.classId,
    required this.isDuplicate,
    required this.isArchive,
    required this.notes,
    required this.created,
  });

  factory RandomCallerModel.fromMap(Map<String, dynamic> map) {
    RandomCallerModel randomCallerModel = RandomCallerModel(
      randomCallerName: map['random_caller_name'],
      classId: map['class_id'],
      isDuplicate: map['is_duplicate'],
      isArchive: map['is_archive'] ?? 0,
      notes: map['notes'],
      created: DateTime.parse(map['created']),
    );
    if (map.containsKey('id')) {
      randomCallerModel.id = map['id'];
    }
    return randomCallerModel;
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) {
      data['id'] = id;
    }
    data['random_caller_name'] = randomCallerName;
    data['class_id'] = classId;
    data['is_duplicate'] = isDuplicate;
    data['is_archive'] = isArchive;
    data['notes'] = notes;
    data['created'] = created.toIso8601String();
    return data;
  }

  @override
  toString() {
    return 'RandomCallerModel{id: $id, randomCallerName: $randomCallerName, classId: $classId, isDuplicate: $isDuplicate, isArchive: $isArchive, notes: $notes, created: $created}';
  }
}
