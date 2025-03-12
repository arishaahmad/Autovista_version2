class Document {
  final String id;
  final String? userId;
  final String? category;
  final String description;
  final String? fileUrl;
  final String? fileName;
  final String? fileType;
  final int? fileSize;
  final String? createdAt;
  final String? updatedAt;

  Document({
    required this.id,
    this.userId,
    this.category,
    required this.description,
    this.fileUrl,
    this.fileName,
    this.fileType,
    this.fileSize,
    this.createdAt,
    this.updatedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'].toString(),
      userId: json['user_id'],
      category: json['category'],
      description: json['description'] ?? '',
      fileUrl: json['file_url'],
      fileName: json['file_name'],
      fileType: json['file_type'],
      fileSize: json['file_size'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category': category,
      'description': description,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_type': fileType,
      'file_size': fileSize,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}