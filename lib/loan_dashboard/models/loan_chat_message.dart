class LoanChatMessage {
  final String sender;
  final String message;
  final DateTime timestamp;
  final String role;
  final String? avatarUrl;

  LoanChatMessage({
    required this.sender,
    required this.message,
    required this.timestamp,
    required this.role,
    this.avatarUrl,
  });
}