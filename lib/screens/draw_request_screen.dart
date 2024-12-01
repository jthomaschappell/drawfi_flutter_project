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

class DrawRequestScreen extends StatefulWidget {
  const DrawRequestScreen({super.key});

  @override
  State<DrawRequestScreen> createState() => _DrawRequestScreenState();
}

class _DrawRequestScreenState extends State<DrawRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _inviteEmailController = TextEditingController();
  final _invitePhoneController = TextEditingController();
  final supabase = Supabase.instance.client;

  DateTime? _submissionDate;
  DateTime? _periodTo;
  String? _selectedLoanId;
  String _status = 'Pending';
  bool _isLoading = true;
  bool _isSubmitting = false;
  int _selectedIndex = 0;

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
      final loansResponse = await supabase
          .from('construction_loans')
          .select()
          .order('created_at');

      final categoriesResponse = await supabase
          .from('cost_categories')
          .select('category_id, category_name')
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
        _showErrorSnackbar('Error loading data: $e');
        Navigator.pop(context);
      }
    }
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Project Members'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _inviteEmailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter email address',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _invitePhoneController,
              decoration: const InputDecoration(
                labelText: 'Phone (Optional)',
                hintText: 'Enter phone number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'contractor', child: Text('Contractor')),
                DropdownMenuItem(value: 'inspector', child: Text('Inspector')),
              ],
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement invitation logic
              _showSuccessSnackbar('Invitation sent successfully');
              Navigator.pop(context);
            },
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitDrawRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      if (_selectedLoanId == null ||
          _submissionDate == null ||
          _periodTo == null ||
          _amountController.text.isEmpty) {
        throw Exception('Please fill in all required fields');
      }

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

      if (_lineItems.isNotEmpty) {
        final drawRequestId = drawRequestResponse['id'] as String?;
        if (drawRequestId == null)
          throw Exception('Failed to get draw request ID');

        final lineItemsData = _lineItems
            .map((item) => {
                  ...item.toJson(),
                  'draw_request_id': drawRequestId,
                })
            .toList();

        await supabase.from('draw_request_line_items').insert(lineItemsData);
      }

      if (mounted) {
        _showSuccessSnackbar('Draw request submitted successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Error submitting request: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'New Draw Request',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CircleAvatar(
              backgroundColor: Colors.deepPurple.shade100,
              child: const Text('IS'),
            ),
          ),
        ],
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
              ElevatedButton.icon(
                onPressed: _showInviteDialog,
                icon: const Icon(Icons.person_add),
                label: const Text('Invite Project Members'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitDrawRequest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.deepPurple,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit Request'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          // Handle navigation based on index
          switch (index) {
            case 0: // Home
              break;
            case 1: // Projects
              break;
            case 2: // Notifications
              break;
            case 3: // Settings
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
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
            labelStyle: TextStyle(color: Colors.black),
          ),
          style: const TextStyle(color: Colors.black),
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
            labelStyle: TextStyle(color: Colors.black),
          ),
          style: const TextStyle(color: Colors.black),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
            labelStyle: TextStyle(color: Colors.black),
          ),
          style: const TextStyle(color: Colors.black),
          maxLines: 3,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _inviteEmailController.dispose();
    _invitePhoneController.dispose();
    super.dispose();
  }
}
