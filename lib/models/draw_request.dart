enum Status { pending, completed }

class DrawRequest {
  final String userId;
  final double amountRequested;
  final Status status;

  DrawRequest({
    required this.userId,
    required this.amountRequested,
    required this.status,
  }); // this is an enum

  @override
  String toString() {
    return 'DrawRequest(userId: $userId, amountRequested: \$${amountRequested.toStringAsFixed(2)}, status: ${status.toString().split('.').last})';
  }
}
