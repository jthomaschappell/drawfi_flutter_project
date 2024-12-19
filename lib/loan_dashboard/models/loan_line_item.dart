class LoanLineItem {
  final String lineItem;
  double inspectionPercentage;
  double? draw1;
  double? draw2;
  double? draw3;
  String? draw1Status;
  String? draw2Status;
  String? draw3Status;
  double budget;

  LoanLineItem({
    required this.lineItem,
    this.inspectionPercentage = 0,
    this.draw1 = 0.0,
    this.draw2 = 0.0,
    this.draw3 = 0.0,
    this.draw1Status = 'pending',
    this.draw2Status = 'pending',
    this.draw3Status = 'pending',
    this.budget = 0.0,
  });

  double get totalDrawn => (draw1 ?? 0) + (draw2 ?? 0) + (draw3 ?? 0);

  @override
  String toString() {
    return 'LoanLineItem('
        'lineItem: $lineItem, '
        'inspectionPercentage: ${(inspectionPercentage * 100).toStringAsFixed(1)}%, '
        'draw1: \$${draw1?.toStringAsFixed(2) ?? "0.00"} (${draw1Status ?? "pending"}), '
        'draw2: \$${draw2?.toStringAsFixed(2) ?? "0.00"} (${draw2Status ?? "pending"}), '
        'draw3: \$${draw3?.toStringAsFixed(2) ?? "0.00"} (${draw3Status ?? "pending"}), '
        'totalDrawn: \$${totalDrawn.toStringAsFixed(2)}, '
        'budget: \$${budget.toStringAsFixed(2)}'
        ')';
  }
}
