import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class DrawRequest {
  final String lineItem;
  bool inspected;
  double? requestedAmount;
  String status;

  DrawRequest({
    required this.lineItem,
    this.inspected = false,
    this.requestedAmount,
    this.status = 'Pending',
  });
}

class DrawRequestScreen extends StatefulWidget {
  const DrawRequestScreen({super.key});

  @override
  State<DrawRequestScreen> createState() => _DrawRequestScreenState();
}

class _DrawRequestScreenState extends State<DrawRequestScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DrawRequest? _selectedRequest;

  final List<DrawRequest> _drawRequests = [
    DrawRequest(
      lineItem: 'Foundation Work',
      inspected: true,
      requestedAmount: 25000,
    ),
    DrawRequest(
      lineItem: 'Framing',
      inspected: true,
      requestedAmount: 30000,
    ),
    DrawRequest(
      lineItem: 'Electrical',
      requestedAmount: 12000,
    ),
    DrawRequest(
      lineItem: 'Plumbing',
      inspected: true,
      requestedAmount: 10000,
    ),
    DrawRequest(
      lineItem: 'HVAC Installation',
      requestedAmount: 20000,
    ),
    DrawRequest(
      lineItem: 'Roofing',
      inspected: true,
      requestedAmount: 25000,
    ),
    DrawRequest(
      lineItem: 'Interior Finishing',
      requestedAmount: 18000,
    ),
  ];

  List<DrawRequest> get filteredRequests {
    if (_searchQuery.isEmpty) return _drawRequests;
    return _drawRequests
        .where((request) =>
            request.lineItem.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  double get totalRequested {
    return _drawRequests.fold(
        0, (sum, request) => sum + (request.requestedAmount ?? 0));
  }

  void _showAmountEditDialog(DrawRequest request) {
    final controller =
        TextEditingController(text: request.requestedAmount?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Requested Amount'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: '\$',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                request.requestedAmount = double.tryParse(controller.text);
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 14),
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search line items...',
          hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
          prefixIcon: const Icon(Icons.search, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildTopNav() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Row(
              children: [
                // Logo
                SvgPicture.string(
                  '''<svg width="32" height="32" viewBox="0 0 1531 1531" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <rect width="1531" height="1531" rx="200" fill="url(#paint0_linear_82_170)"/>
                  <ellipse cx="528" cy="429.5" rx="136.5" ry="136" transform="rotate(-90 528 429.5)" fill="white"/>
                  <circle cx="528" cy="1103" r="136" transform="rotate(-90 528 1103)" fill="white"/>
                  <circle cx="1001" cy="773" r="136" fill="white"/>
                  <ellipse cx="528" cy="774" rx="29" ry="28" fill="white"/>
                  <ellipse cx="808" cy="494" rx="29" ry="28" fill="white"/>
                  <ellipse cx="808" cy="1038.5" rx="29" ry="29.5" fill="white"/>
                  <defs>
                  <linearGradient id="paint0_linear_82_170" x1="1485.07" y1="0.00010633" x2="30.6199" y2="1485.07" gradientUnits="userSpaceOnUse">
                  <stop stop-color="#FF1970"/>
                  <stop offset="0.145" stop-color="#E81766"/>
                  <stop offset="0.307358" stop-color="#DB12AF"/>
                  <stop offset="0.43385" stop-color="#BF09D5"/>
                  <stop offset="0.556871" stop-color="#A200FA"/>
                  <stop offset="0.698313" stop-color="#6500E9"/>
                  <stop offset="0.855" stop-color="#3C17DB"/>
                  <stop offset="1" stop-color="#2800D7"/>
                  </linearGradient>
                  </defs>
                  </svg>''',
                  width: 32,
                  height: 32,
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'New Draw Request',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Draw Request Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Requested Amount',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${totalRequested.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6500E9),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Submit draw request logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Draw request submitted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6500E9),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Submit Draw Request'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: const [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Line Item',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Amount',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredRequests.length,
                itemBuilder: (context, index) {
                  final request = filteredRequests[index];
                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: ListTile(
                      title: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(request.lineItem),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  request.inspected
                                      ? Icons.check_circle
                                      : Icons.pending,
                                  color: request.inspected
                                      ? Colors.green
                                      : Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  request.inspected ? 'Verified' : 'Pending',
                                  style: TextStyle(
                                    color: request.inspected
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showAmountEditDialog(request),
                              child: Text(
                                request.requestedAmount != null
                                    ? '\$${request.requestedAmount!.toStringAsFixed(2)}'
                                    : 'Add Amount',
                                style: TextStyle(
                                  color: const Color(0xFF6500E9),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildTopNav(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  _buildDataTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
