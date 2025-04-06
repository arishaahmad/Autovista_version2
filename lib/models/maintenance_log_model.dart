// for the maintenance logs feature . 5-4-2025
class MaintenanceLog {
  final String id;
  final String fileName;
  final String filePath;
  final DateTime createdAt;

  MaintenanceLog({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.createdAt,
  });

  factory MaintenanceLog.fromJson(Map<String, dynamic> json) => MaintenanceLog(
    id: json['id'],
    fileName: json['file_name'],
    filePath: json['file_path'],
    createdAt: DateTime.parse(json['created_at']),
  );
}
