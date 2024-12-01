import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// Models
class DrawRequestLineItem {
  String categoryName;
  double budgetedAmount;

  DrawRequestLineItem({
    required this.categoryName,
    required this.budgetedAmount,
  });

  Map<String, dynamic> toJson() => {
        'category_name': categoryName,
        'budgeted_amount': budgetedAmount,
      };
}

class ConstructionLoan {
  final String id;
  final String description;

  ConstructionLoan({
    required this.id,
    required this.description,
  });

  factory ConstructionLoan.fromJson(Map<String, dynamic> json) =>
      ConstructionLoan(
        id: json['loan_id'] as String? ?? '',
        description: json['description'] as String? ?? 'Unknown Loan',
      );
}

class CostCategory {
  final String id;
  final String name;

  CostCategory({
    required this.id,
    required this.name,
  });

  factory CostCategory.fromJson(Map<String, dynamic> json) => CostCategory(
        id: json['category_id'] as String? ?? '',
        name: json['category_name'] as String? ?? 'Unknown Category',
      );
}

// Main Screen
class DrawRequestScreen extends StatefulWidget {
  const DrawRequestScreen({super.key});

  @override
  State<DrawRequestScreen> createState() => _DrawRequestScreenState();
}

class _DrawRequestScreenState extends State<DrawRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final supabase = Supabase.instance.client;

  DateTime? _submissionDate;
  DateTime? _periodTo;
  String? _selectedLoanId;
  String _status = 'Pending';
  bool _isLoading = true;
  bool _isSubmitting = false;

  List<ConstructionLoan> _loans = [];
  List<CostCategory> _categories = [];
  List<DrawRequestLineItem> _lineItems = [];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      // Fetch loans and categories
      final loansResponse = await supabase
          .from('construction_loans')
          .select()
          .order('created_at');

      final categoriesResponse = await supabase
          .from('cost_categories')
          .select(
              'category_id, category_name') // Adjusted to match the actual column names
          .order('category_name');

      if (mounted) {
        setState(() {
          _loans = (loansResponse as List<dynamic>)
              .map((loan) => ConstructionLoan.fromJson(loan))
              .toList();
          _categories = (categoriesResponse as List<dynamic>)
              .map((category) => CostCategory.fromJson(category))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _submitDrawRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Validate required fields
      if (_selectedLoanId == null ||
          _submissionDate == null ||
          _periodTo == null ||
          _amountController.text.isEmpty) {
        throw Exception('Please fill in all required fields');
      }

      // Insert draw request
      final drawRequestData = {
        'user_id': userId,
        'loan_id': _selectedLoanId,
        'amount_requested': double.tryParse(_amountController.text) ?? 0.0,
        'submission_date': _submissionDate!.toIso8601String(),
        'period_to': _periodTo!.toIso8601String(),
        'status': _status,
        'description': _descriptionController.text.trim(),
      };

      final drawRequestResponse = await supabase
          .from('draw_requests')
          .insert(drawRequestData)
          .select()
          .single();

      // Insert line items
      if (_lineItems.isNotEmpty) {
        final drawRequestId = drawRequestResponse['id'] as String?;
        if (drawRequestId == null) {
          throw Exception('Failed to get draw request ID');
        }

        final lineItemsData = _lineItems
            .map((item) => {
                  ...item.toJson(),
                  'draw_request_id': drawRequestId,
                })
            .toList();

        await supabase.from('draw_request_line_items').insert(lineItemsData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draw request submitted successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting request: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Draw Request'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFormFields(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitDrawRequest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedLoanId,
          decoration: const InputDecoration(
            labelText: 'Select Loan *',
            border: OutlineInputBorder(),
          ),
          items: _loans
              .map((loan) => DropdownMenuItem(
                    value: loan.id,
                    child: Text(loan.description),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _selectedLoanId = value),
          validator: (value) => value == null ? 'Please select a loan' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _amountController,
          decoration: const InputDecoration(
            labelText: 'Amount (\$) *',
            prefixIcon: Icon(Icons.attach_money),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an amount';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
