class LoanLineItem {
  final String lineItem; 
  /// TODO: 
  /// I see here that this is a data class for a DrawRequest.
  /// It has a lot of good data here, like the lineItem (for example, "Excavation"), 
  /// the inspected status, etc. 
  /// 
  /// My question: 
  /// Why does it look like there is more than one draw? 
  /// I see a 'draw1', 'draw2', 'draw3'. 
  /// 
  /// Suggestion: 
  /// I feel like we should change our code so that there aren't *3* "draws" for one "draw request". 
  /// Let's keep it simple. 
  /// 
  /// -Thomas Chappell, 12.17.2024
  // bool inspected;
  double inspectionPercentage;
  double? draw1;
  double? draw2;
  double? draw3;
  String? draw1Status;
  String? draw2Status;
  String? draw3Status;

  LoanLineItem({
    required this.lineItem,
    required this.inspectionPercentage, 
    this.draw1,
    this.draw2,
    this.draw3,
    this.draw1Status = 'pending',
    this.draw2Status = 'pending',
    this.draw3Status = 'pending',
  });

  double get totalDrawn => (draw1 ?? 0) + (draw2 ?? 0) + (draw3 ?? 0);
}