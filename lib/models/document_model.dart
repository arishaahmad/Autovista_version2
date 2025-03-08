class Document {
  final String? id;
  final String userId;
  final String category;
  final String description;
  final String fileUrl;
  final String fileName;
  final String fileType;
  final int fileSize;
  final String? createdAt;
  final String? updatedAt;

  Document({
    this.id,
    required this.userId,
    required this.category,
    required this.description,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    this.createdAt,
    this.updatedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id']?.toString(),
      userId: json['user_id'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      fileUrl: json['file_url'] as String,
      fileName: json['file_name'] as String,
      fileType: json['file_type'] as String,
      fileSize: json['file_size'] as int,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'category': category,
      'description': description,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_type': fileType,
      'file_size': fileSize,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  Document copyWith({
    String? id,
    String? userId,
    String? category,
    String? description,
    String? fileUrl,
    String? fileName,
    String? fileType,
    int? fileSize,
    String? createdAt,
    String? updatedAt,
  }) {
    return Document(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      description: description ?? this.description,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
