class Parking {
  final String? id;
  final String userId;
  final double latitude;
  final double longitude;
  final String timestamp;
  final String? photoUrl;
  final String? photoName;
  final String? description;
  final String? createdAt;
  final String? updatedAt;

  Parking({
    this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.photoUrl,
    this.photoName,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (photoName != null) 'photo_name': photoName,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  factory Parking.fromJson(Map<String, dynamic> json) {
    return Parking(
      id: json['id']?.toString(),
      userId: json['user_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: json['timestamp'] as String,
      photoUrl: json['photo_url'] as String?,
      photoName: json['photo_name'] as String?,
      description: json['description'] as String?,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Parking copyWith({
    String? id,
    String? userId,
    double? latitude,
    double? longitude,
    String? timestamp,
    String? photoUrl,
    String? photoName,
    String? description,
    String? createdAt,
    String? updatedAt,
  }) {
    return Parking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      photoUrl: photoUrl ?? this.photoUrl,
      photoName: photoName ?? this.photoName,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
