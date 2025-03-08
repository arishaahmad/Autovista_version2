import 'package:flutter/foundation.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String? data;
  final bool isRead;
  final DateTime createdAt;
  final String type;  // e.g., 'maintenance', 'document_expiry', 'system'

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.data,
    required this.isRead,
    required this.createdAt,
    required this.type,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      body: json['body'],
      data: json['data'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'type': type,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? data,
    bool? isRead,
    DateTime? createdAt,
    String? type,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
    );
  }
}