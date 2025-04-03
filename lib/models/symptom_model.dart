class SymptomLog {
  final List<String> symptoms;
  final String date;
  final String severity;
  final String timeOfDay;
  final String notes;

  SymptomLog({
    required this.symptoms,
    required this.date,
    required this.severity,
    required this.timeOfDay,
    required this.notes,
  });

  factory SymptomLog.fromJson(Map<String, dynamic> json) {
    return SymptomLog(
      symptoms: List<String>.from(json['symptoms'] ?? []),
      date: json['date'] ?? '',
      severity: json['severity'] ?? '',
      timeOfDay: json['timeOfDay'] ?? '',
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symptoms': symptoms,
      'date': date,
      'severity': severity,
      'timeOfDay': timeOfDay,
      'notes': notes,
    };
  }
}