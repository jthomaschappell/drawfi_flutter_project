import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PaymentApplicationForm extends StatefulWidget {
  const PaymentApplicationForm({super.key});

  @override
  State<PaymentApplicationForm> createState() => _PaymentApplicationFormState();
}

class _PaymentApplicationFormState extends State<PaymentApplicationForm> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  // Form controllers for payment application
  final _projectNameController = TextEditingController();
  final _ownerController = TextEditingController();
  final _contractorNameController = TextEditingController();
  final _architectController = TextEditingController();
  final _applicationNumberController = TextEditingController();
  final _periodToController = TextEditingController();
  final _architectProjectNumberController = TextEditingController();
  final _contractDateController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _originalContractSumController = TextEditingController();
  final _totalCompletedStoredController = TextEditingController();
  final _previousCertificatesController = TextEditingController();
  final _balanceToDrawController = TextEditingController();

  // Line items
  List<LineItem> lineItems = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Application'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProjectInfo(),
              const SizedBox(height: 24),
              _buildParticipantInfo(),
              const SizedBox(height: 24),
              _buildFinancialInfo(),
              const SizedBox(height: 24),
              _buildLineItems(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Project Information',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _projectNameController,
              decoration: const InputDecoration(
                labelText: 'Project Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _applicationNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Application Number *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _architectProjectNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Architect Project Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _periodToController,
                    decoration: const InputDecoration(
                      labelText: 'Period To *',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        _periodToController.text =
                            DateFormat('yyyy-MM-dd').format(date);
                      }
                    },
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _contractDateController,
                    decoration: const InputDecoration(
                      labelText: 'Contract Date',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        _contractDateController.text =
                            DateFormat('yyyy-MM-dd').format(date);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Project Participants',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ownerController,
              decoration: const InputDecoration(
                labelText: 'Owner *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contractorNameController,
              decoration: const InputDecoration(
                labelText: 'Contractor Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _architectController,
              decoration: const InputDecoration(
                labelText: 'Architect *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Financial Information',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _originalContractSumController,
              decoration: const InputDecoration(
                labelText: 'Original Contract Sum *',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ],
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _balanceToDrawController,
              decoration: const InputDecoration(
                labelText: 'Balance to Draw *',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ],
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItems() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Line Items',
                    style: Theme.of(context).textTheme.titleLarge),
                ElevatedButton.icon(
                  onPressed: _addLineItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lineItems.length,
              itemBuilder: (context, index) {
                return _buildLineItemCard(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItemCard(int index) {
    final item = lineItems[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: item.descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeLineItem(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: item.adjustedAllocationController,
                    decoration: const InputDecoration(
                      labelText: 'Adjusted Allocation',
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CurrencyInputFormatter(),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: item.constructionAllocationController,
                    decoration: const InputDecoration(
                      labelText: 'Construction Allocation',
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CurrencyInputFormatter(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Inspection Complete'),
                    value: item.inspection,
                    onChanged: (bool? value) {
                      setState(() {
                        item.inspection = value ?? false;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        ),
        child: const Text('Submit Application'),
      ),
    );
  }

  void _addLineItem() {
    setState(() {
      lineItems.add(LineItem());
    });
  }

  void _removeLineItem(int index) {
    setState(() {
      lineItems.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      // Insert main application
      final applicationResponse = await _supabase
          .from('payment_applications')
          .insert({
            'project_name': _projectNameController.text,
            'owner': _ownerController.text,
            'contractor_name': _contractorNameController.text,
            'architect': _architectController.text,
            'application_number': _applicationNumberController.text,
            'period_to': _periodToController.text,
            'architect_project_number': _architectProjectNumberController.text,
            'contract_date': _contractDateController.text,
            'invoice_number': _invoiceNumberController.text,
            'original_contract_sum':
                _parseCurrency(_originalContractSumController.text),
            'total_completed_stored':
                _parseCurrency(_totalCompletedStoredController.text),
            'previous_certificates':
                _parseCurrency(_previousCertificatesController.text),
            'balance_to_draw': _parseCurrency(_balanceToDrawController.text),
            'status': 'draft',
            'user_id': _supabase.auth.currentUser!.id,
          })
          .select()
          .single();

      // Insert line items
      for (var item in lineItems) {
        await _supabase.from('payment_line_items').insert({
          'payment_application_id': applicationResponse['id'],
          'item_number': item.itemNumber,
          'description': item.descriptionController.text,
          'adjusted_allocation':
              _parseCurrency(item.adjustedAllocationController.text),
          'construction_allocation':
              _parseCurrency(item.constructionAllocationController.text),
          'inspection': item.inspection,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted successfully')),
        );
        // Navigate back or clear form
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting application: $e')),
      );
    }
  }

  double _parseCurrency(String value) {
    if (value.isEmpty) return 0;
    return double.parse(value.replaceAll(RegExp(r'[^\d.]'), ''));
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _ownerController.dispose();
    _contractorNameController.dispose();
    _architectController.dispose();
    _applicationNumberController.dispose();
    _periodToController.dispose();
    _architectProjectNumberController.dispose();
    _contractDateController.dispose();
    _invoiceNumberController.dispose();
    _originalContractSumController.dispose();
    _totalCompletedStoredController.dispose();
    _previousCertificatesController.dispose();
    _balanceToDrawController.dispose();
    for (var item in lineItems) {
      item.dispose();
    }
    super.dispose();
  }
}

class LineItem {
  final String itemNumber = DateTime.now().millisecondsSinceEpoch.toString();
  final descriptionController = TextEditingController();
  final adjustedAllocationController = TextEditingController();
  final constructionAllocationController = TextEditingController();
  bool inspection = false;

  void dispose() {
    descriptionController.dispose();
    adjustedAllocationController.dispose();
    constructionAllocationController.dispose();
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final number = int.parse(newValue.text);
    final formatted = NumberFormat("#,##0.00", "en_US").format(number / 100);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
