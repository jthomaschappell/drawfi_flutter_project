class LoanDashboardChatMessage {
  final String sender;
  final String message;
  final DateTime timestamp;
  final String role;
  final String? avatarUrl;

  LoanDashboardChatMessage({
    required this.sender,
    required this.message,
    required this.timestamp,
    required this.role,
    this.avatarUrl,
  });
}