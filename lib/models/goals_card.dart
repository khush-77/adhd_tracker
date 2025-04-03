class Goal {
  final String id;
  final String goalName;
  final String frequency;
  final String howOften;
  final String notes;
  final DateTime startDate;
  final int progress;
  final bool completed;

  Goal({
    required this.id,
    required this.goalName,
    required this.frequency,
    required this.howOften,
    required this.notes,
    required this.startDate,
    required this.progress,
    required this.completed,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['_id'],
      goalName: json['goalName'],
      frequency: json['frequency'],
      howOften: json['howOften'],
      notes: json['notes'],
      startDate: DateTime.parse(json['startDate']),
      progress: json['progress'] ?? 0,
      completed: json['completed'] ?? false,
    );
  }
}