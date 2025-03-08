// Event model for managing vehicle-related events and reminders
class Event {
  final String? id;
  final String userId;
  final String title;
  final String description;
  final DateTime date;
  final String eventType;
  final double? fuelNeeded;
  final String? location;
  final bool isCompleted;
  final String? reminderTime;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  Event({
    this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.date,
    required this.eventType,
    this.fuelNeeded,
    this.location,
    this.isCompleted = false,
    this.reminderTime,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id']?.toString(),
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      date: DateTime.parse(json['date'].toString()),
      eventType: json['event_type'] as String,
      fuelNeeded: json['fuel_needed'] != null
          ? (json['fuel_needed'] as num).toDouble()
          : null,
      location: json['location'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      reminderTime: json['reminder_time'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'event_type': eventType,
      if (fuelNeeded != null) 'fuel_needed': fuelNeeded,
      if (location != null) 'location': location,
      'is_completed': isCompleted,
      if (reminderTime != null) 'reminder_time': reminderTime,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  Event copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? date,
    String? eventType,
    double? fuelNeeded,
    String? location,
    bool? isCompleted,
    String? reminderTime,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      eventType: eventType ?? this.eventType,
      fuelNeeded: fuelNeeded ?? this.fuelNeeded,
      location: location ?? this.location,
      isCompleted: isCompleted ?? this.isCompleted,
      reminderTime: reminderTime ?? this.reminderTime,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return '''
Event:
  ID: $id
  User ID: $userId
  Title: $title
  Description: $description
  Date: ${date.toIso8601String()}
  Type: $eventType
  Fuel Needed: ${fuelNeeded?.toStringAsFixed(2) ?? 'N/A'}
  Location: ${location ?? 'N/A'}
  Completed: $isCompleted
  Reminder: ${reminderTime ?? 'N/A'}
  Notes: ${notes ?? 'N/A'}
  Created: ${createdAt ?? 'N/A'}
  Updated: ${updatedAt ?? 'N/A'}
''';
  }
}
