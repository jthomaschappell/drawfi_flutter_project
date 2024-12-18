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
    required this.inspectionPercentage,
    this.draw1,
    this.draw2,
    this.draw3,
    this.draw1Status = 'pending',
    this.draw2Status = 'pending',
    this.draw3Status = 'pending',
    this.budget = 0.0,
  });

  double get totalDrawn => (draw1 ?? 0) + (draw2 ?? 0) + (draw3 ?? 0);
}
