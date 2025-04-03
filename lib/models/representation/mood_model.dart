class MoodEntry {
  final String id;
  final DateTime date;
  final int mood;

  MoodEntry({
    required this.id,
    required this.date,
    required this.mood,
  });

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['_id'],
      date: DateTime.parse(json['date']),
      mood: json['mood'],
    );
  }
}
