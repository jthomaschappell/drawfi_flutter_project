class ConstructionNotification {
  final String id;
  final String message;
  final DateTime timestamp;
  final String type; // 'loan' or 'line_item'
  final String referenceId; // loan_id or category_id

  ConstructionNotification({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.type,
    required this.referenceId,
  });

  @override
  String toString() {
    return 'ConstructionNotification('
        'id: $id, '
        'message: $message, '
        'timestamp: ${timestamp.toIso8601String()}, '
        'type: $type, '
        'referenceId: $referenceId'
        ')';
  }
}
