import 'package:dotted_border/dotted_border.dart';
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
        contentPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Request Amount',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              request.lineItem,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey[200]),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Amount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                    prefixText: '\$ ',
                    prefixStyle: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      request.requestedAmount =
                          double.tryParse(controller.text);
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6500E9),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      height: 36,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF111827), // Dark text color
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: 'Search line items...',
          hintStyle: TextStyle(
            fontSize: 14,
            color: Colors.grey[700], // Darker hint text
          ),
          prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey[700]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
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
                    fontSize: 22, // Increased size
                    fontWeight: FontWeight.w800, // Bolder
                    color: Color(0xFF111827), // Darker text
                    letterSpacing: -0.5, // Tighter spacing
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Draw Request Summary',
            style: TextStyle(
              fontSize: 20, // Increased size
              fontWeight: FontWeight.w800, // Bolder
              color: Color(0xFF111827), // Darker text
              letterSpacing: -0.5, // Tighter spacing
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6500E9).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Requested Amount',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${totalRequested.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6500E9),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Submit Draw Request',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
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
              child: const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Line Item',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF111827), // Darker text
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Status',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF111827), // Darker text
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Amount',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF111827), // Darker text
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
                            child: Text(
                              request.lineItem,
                              style: const TextStyle(
                                color: Color(0xFF111827), // Darker text
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  request.inspected
                                      ? Icons.check_circle
                                      : Icons.pending,
                                  color: request.inspected
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  request.inspected ? 'Verified' : 'Pending',
                                  style: TextStyle(
                                    color: request.inspected
                                        ? Colors.green[700]
                                        : Colors.orange[700],
                                    fontWeight: FontWeight.w500,
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
                                style: const TextStyle(
                                  color: Color(0xFF6500E9),
                                  fontWeight: FontWeight.w500,
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

  Widget _buildDocumentUpload() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Supporting Documents',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          DottedBorder(
            // Using DottedBorder instead of BorderStyle.dashed
            borderType: BorderType.RRect,
            radius: const Radius.circular(12),
            color: const Color(0xFF6500E9),
            strokeWidth: 2,
            dashPattern: const [8, 4],
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6500E9).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.cloud_upload_outlined,
                      color: Color(0xFF6500E9),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Drag & Drop files here',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'or browse from device',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // List of uploaded files would go here
        ],
      ),
    );
  }

  Widget _buildProgressCircles() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 180, // Increased height
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                SizedBox(
                  height: 140, // Increased size (approximately 10cm)
                  width: 140, // Increased size (approximately 10cm)
                  child: Stack(
                    alignment: Alignment.center, // Center the text
                    children: [
                      SizedBox(
                        height: 140,
                        width: 140,
                        child: CircularProgressIndicator(
                          value: 0.75,
                          strokeWidth: 12, // Made stroke thicker
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF6500E9),
                          ),
                        ),
                      ),
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '75%',
                            style: TextStyle(
                              fontSize: 36, // Larger text
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          Text(
                            'Complete',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Project Progress',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '15 of 20 items completed',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Second circle (Budget Status) with same changes
        Expanded(
          child: Container(
            height: 180, // Increased height
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                SizedBox(
                  height: 140, // Increased size
                  width: 140, // Increased size
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 140,
                        width: 140,
                        child: CircularProgressIndicator(
                          value: 0.45,
                          strokeWidth: 12,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.green,
                          ),
                        ),
                      ),
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '45%',
                            style: TextStyle(
                              fontSize: 36, // Larger text
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          Text(
                            'Disbursed',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Budget Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '\$450,000 of \$1M disbursed',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildProgressCircles(),
                        const SizedBox(height: 24),
                        _buildSearchBar(),
                        const SizedBox(height: 24),
                        _buildDataTable(),
                        const SizedBox(height: 24),
                        _buildSummaryCard(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  _buildDocumentUpload(),
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
