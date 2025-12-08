class RandomCallRecordModel {
  int? id;
  int randomCallerId;
  int studentId;
  int score;
  String notes;
  DateTime created;

  RandomCallRecordModel({
    this.id,
    required this.randomCallerId,
    required this.studentId,
    required this.score,
    required this.notes,
    required this.created,
  });

  factory RandomCallRecordModel.fromMap(Map<String, dynamic> map) {
    RandomCallRecordModel randomCallRecordModel = RandomCallRecordModel(
      randomCallerId: map['random_caller_id'],
      studentId: map['student_id'],
      score: map['score'],
      notes: map['notes'],
      created: DateTime.parse(map['created']),
    );
    if (map.containsKey('id')) {
      randomCallRecordModel.id = map['id'];
    }
    return randomCallRecordModel;
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) {
      data['id'] = id;
    }
    data['random_caller_id'] = randomCallerId;
    data['student_id'] = studentId;
    data['score'] = score;
    data['notes'] = notes;
    data['created'] = created.toIso8601String();
    return data;
  }

  @override
  String toString() {
    return 'RandomCallRecordModel(id: $id, randomCallerId: $randomCallerId, studentId: $studentId, score: $score, notes: $notes, created: $created)';
  }
}
