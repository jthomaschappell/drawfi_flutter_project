import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tester/models/construction_notification.dart';
import 'package:uuid/uuid.dart';

class NotificationService {
  final SupabaseClient supabase;
  
  NotificationService(this.supabase);
  
  Stream<List<ConstructionNotification>> subscribeToUpdates() {
    final loansStream = supabase
      .from('construction_loans')
      .stream(primaryKey: ['loan_id'])
      .map((changes) => _processLoanChanges(changes));
      
    final lineItemsStream = supabase
      .from('construction_loan_line_items')
      .stream(primaryKey: ['category_id'])
      .map((changes) => _processLineItemChanges(changes));
      
    return Rx.combineLatest2(loansStream, lineItemsStream,
      (List<ConstructionNotification> loans, 
       List<ConstructionNotification> items) {
        return [...loans, ...items]..sort((a, b) => 
          b.timestamp.compareTo(a.timestamp));
    });
  }
  
  List<ConstructionNotification> _processLoanChanges(List<Map<String, dynamic>> changes) {
    return changes.map((change) {
      return ConstructionNotification(
        id: const Uuid().v4(),
        message: _createLoanMessage(change),
        timestamp: DateTime.parse(change['updated_at']),
        type: 'loan',
        referenceId: change['loan_id'],
      );
    }).toList();
  }
  
  List<ConstructionNotification> _processLineItemChanges(List<Map<String, dynamic>> changes) {
    return changes.map((change) {
      return ConstructionNotification(
        id: const Uuid().v4(),
        message: _createLineItemMessage(change),
        timestamp: DateTime.parse(change['updated_at']),
        type: 'line_item',
        referenceId: change['category_id'],
      );
    }).toList();
  }
  
  String _createLoanMessage(Map<String, dynamic> change) {
    // Customize based on what changed
    return "Loan '${change['loan_name']}' was updated";
  }
  
  String _createLineItemMessage(Map<String, dynamic> change) {
    return "Line item '${change['category_name']}' was updated";
  }
}