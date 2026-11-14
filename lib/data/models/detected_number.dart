class DetectedNumber {
  const DetectedNumber({
    required this.id,
    required this.phoneNumber,
    required this.source,
    required this.firstDetectedAt,
    required this.lastDetectedAt,
    required this.isSavedContact,
    this.contactName,
  });

  final int id;
  final String phoneNumber;
  final String source;
  final DateTime firstDetectedAt;
  final DateTime lastDetectedAt;
  final bool isSavedContact;
  final String? contactName;

  factory DetectedNumber.fromMap(Map<String, Object?> map) {
    return DetectedNumber(
      id: map['id'] as int,
      phoneNumber: map['phone_number'] as String,
      source: map['source'] as String,
      firstDetectedAt: DateTime.parse(map['first_detected_at'] as String),
      lastDetectedAt: DateTime.parse(map['last_detected_at'] as String),
      isSavedContact: (map['is_saved_contact'] as int? ?? 0) == 1,
      contactName: map['contact_name'] as String?,
    );
  }
}
