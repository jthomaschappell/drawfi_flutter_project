class LoanDashboardNotification {
  final String title;
  final String message;
  final DateTime time;
  bool isRead;

  LoanDashboardNotification({
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
  });
}