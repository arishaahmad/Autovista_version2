class EmergencyContact {
  final String id;
  final String userId;
  final String contactName;
  final String contactNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmergencyContact({
    required this.id,
    required this.userId,
    required this.contactName,
    required this.contactNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'],
      userId: json['user_id'],
      contactName: json['contact_name'],
      contactNumber: json['contact_number'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'contact_name': contactName,
      'contact_number': contactNumber,
    };
  }
}