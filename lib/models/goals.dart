class Goal {
  int? id;
  String name;
  String frequency;
  DateTime startDate;
  String notes;

  Goal({
    this.id,
    required this.name,
    required this.frequency,
    required this.startDate,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'frequency': frequency,
      'startDate': startDate.toIso8601String(),
      'notes': notes,
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'],
      name: map['name'],
      frequency: map['frequency'],
      startDate: DateTime.parse(map['startDate']),
      notes: map['notes'] ?? '',
    );
  }
}