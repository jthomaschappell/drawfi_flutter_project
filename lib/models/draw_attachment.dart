class DrawAttachment {
  final String id;
  final String fileName;
  final String fileType;
  final String filePath;
  final String uploadedBy;
  final DateTime uploadedAt;

  DrawAttachment({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.filePath,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  factory DrawAttachment.fromJson(Map<String, dynamic> json) {
    return DrawAttachment(
      id: json['id'],
      fileName: json['file_name'],
      fileType: json['file_type'],
      filePath: json['file_path'],
      uploadedBy: json['created_by'],
      uploadedAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'file_name': fileName,
        'file_type': fileType,
        'file_path': filePath,
        'created_by': uploadedBy,
        'created_at': uploadedAt.toIso8601String(),
      };
}
