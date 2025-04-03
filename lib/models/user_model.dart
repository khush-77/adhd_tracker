class ProfileData {
  final String id;
  final String name;
  final String emailId;
  final bool isVerified;
  final bool addMedication;
  final List<String> medications;
  final bool addSymptoms;
  final List<String> symptoms;
  final bool addStrategies;
  final List<String> strategies;
  final String? profilePicture;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProfileData({
    required this.id,
    required this.name,
    required this.emailId,
    required this.isVerified,
    required this.addMedication,
    required this.medications,
    required this.addSymptoms,
    required this.symptoms,
    required this.addStrategies,
    required this.strategies,
    this.profilePicture,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      emailId: json['emailId'] ?? '',
      isVerified: json['isVerified'] ?? false,
      addMedication: json['addMedication'] ?? false,
      medications: List<String>.from(json['medications'] ?? []),
      addSymptoms: json['addSymptoms'] ?? false,
      symptoms: List<String>.from(json['symptoms'] ?? []),
      addStrategies: json['addStrategies'] ?? false,
      strategies: List<String>.from(json['strategies'] ?? []),
      profilePicture: json['profilePicture'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}