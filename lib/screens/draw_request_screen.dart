import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class DrawRequest {
  final String lineItem;
  double inspectionPercentage;
  Map<int, double?> draws;  
  Map<int, String> drawStatuses;
  double budget;

  DrawRequest({
    required this.lineItem,
    required this.inspectionPercentage,
    Map<int, double?>? draws,
    Map<int, String>? drawStatuses,
    required this.budget,
  }) : 
    draws = draws ?? {1: null, 2: null, 3: null, 4: null},
    drawStatuses = drawStatuses ?? {1: 'pending', 2: 'pending', 3: 'pending', 4: 'pending'};

  double get totalDrawn {
    return draws.values.fold<double>(0, (sum, amount) => sum + (amount ?? 0));
  }
}

class DrawRequestScreen extends StatefulWidget {
  final String loanId;
  const DrawRequestScreen({super.key, required this.loanId});

  @override
  State<DrawRequestScreen> createState() => _DrawRequestScreenState();
}

// At the top of your _DrawRequestScreenState class
final Map<String, TextEditingController> _controllers = {};

class _DrawRequestScreenState extends State<DrawRequestScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  String _searchQuery = '';
  Map<String, TextEditingController> _controllers = {};
  String companyName = "ABC Construction";
  String contractorName = "John Builder";
  String contractorEmail = "john@builder.com";
  String contractorPhone = "(555) 123-4567";
  
  int numberOfDraws = 4;
  
  List<DrawRequest> _drawRequests = [
    DrawRequest(
      lineItem: 'Foundation Work',
      inspectionPercentage: 0.3,
      budget: 153000,
      draws: {
        1: 45000,
        2: 25000,
        3: 30000,
        4: null
      },
      drawStatuses: {
        1: 'approved',
        2: 'pending',
        3: 'pending',
        4: 'pending'
      },
    ),
    DrawRequest(
      lineItem: 'Framing',
      inspectionPercentage: 0.34,
      budget: 153000,
      draws: {
        1: 35000,
        2: 40000,
        3: null,
        4: null
      },
      drawStatuses: {
        1: 'approved',
        2: 'pending',
        3: 'pending',
        4: 'pending'
      },
    ),
    DrawRequest(
      lineItem: 'Electrical',
      inspectionPercentage: 0.55,
      budget: 111000,
      draws: {
        1: 28000,
        2: 32000,
        3: null,
        4: null
      },
      drawStatuses: {
        1: 'approved',
        2: 'pending',
        3: 'pending',
        4: 'pending'
      },
    ),
    DrawRequest(
      lineItem: 'Plumbing',
      inspectionPercentage: 0.13,
      budget: 153000,
      draws: {
        1: 42000,
        2: 10000,
        3: null,
        4: null
      },
      drawStatuses: {
        1: 'approved',
        2: 'pending',
        3: 'pending',
        4: 'pending'
      },
    ),
    DrawRequest(
      lineItem: 'HVAC Installation',
      inspectionPercentage: 0.0,
      budget: 153000,
      draws: {
        1: 38000,
        2: 45000,
        3: null,
        4: null
      },
      drawStatuses: {
        1: 'pending',
        2: 'pending',
        3: 'pending',
        4: 'pending'
      },
    ),
    DrawRequest(
      lineItem: 'Roofing',
      inspectionPercentage: 0.4,
      budget: 153000,
      draws: {
        1: 50000,
        2: 35000,
        3: null,
        4: null
      },
      drawStatuses: {
        1: 'approved',
        2: 'pending',
        3: 'pending',
        4: 'pending'
      },
    ),
    DrawRequest(
      lineItem: 'Interior Finishing',
      inspectionPercentage: 0.45,
      budget: 153000,
      draws: {
        1: 40000,
        2: 38000,
        3: 25000,
        4: null
      },
      drawStatuses: {
        1: 'approved',
        2: 'pending',
        3: 'pending',
        4: 'pending'
      },
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (var item in _drawRequests) {
      for (int i = 1; i <= numberOfDraws; i++) {
        final key = '${item.lineItem}_$i';
        final amount = item.draws[i];
        _controllers[key] = TextEditingController(text: amount?.toString() ?? '');
      }
    }
  }

  void _addNewDraw() {
    setState(() {
      numberOfDraws++;
      // Add new draw for each request
      for (var request in _drawRequests) {
        request.draws[numberOfDraws] = null;
        request.drawStatuses[numberOfDraws] = 'pending';
        
        // Add new controller
        final key = '${request.lineItem}_$numberOfDraws';
        _controllers[key] = TextEditingController();
      }
    });
  }

  void _submitDraw(int drawNumber) {
    setState(() {
      for (var request in _drawRequests) {
        if (request.draws[drawNumber] != null) {
          request.drawStatuses[drawNumber] = 'submitted';
        }
      }
    });
  }

  List<DrawRequest> get filteredRequests {
    if (_searchQuery.isEmpty) return _drawRequests;
    return _drawRequests
        .where(
          (request) => request.lineItem.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  double get totalDisbursed {
    double totalDrawn = _drawRequests.fold<double>(
        0.0, (sum, request) => sum + request.totalDrawn);
    double totalBudget = _drawRequests.fold<double>(
        0.0, (sum, request) => sum + request.budget);

    if (totalBudget == 0) return 0;
    return (totalDrawn / totalBudget) * 100;
  }

  double get projectCompletion {
    double weightedSum = 0;
    double totalBudget = 0;

    for (var item in _drawRequests) {
      weightedSum += (item.inspectionPercentage * item.budget);
      totalBudget += item.budget;
    }

    if (totalBudget == 0) return 0;
    return (weightedSum / totalBudget) * 100;
  }

  Widget _buildDrawStatusSection(int drawNumber) {
    String status = drawNumber <= numberOfDraws ? 
      (_drawRequests.any((request) => request.drawStatuses[drawNumber] == 'submitted') ? 'submitted' : 'pending') : '';
    Color statusColor = _getStatusColor(status);
    
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.grey[200]!),
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Submit button
          ElevatedButton(
            onPressed: status != 'submitted' ? () => _submitDraw(drawNumber) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 61, 143, 96),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(80, 32),
            ),
            child: Text(
              status == 'submitted' ? 'Submitted' : 'Submit',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
                SvgPicture.string(
                  '''
                    <svg width="32" height="32" viewBox="0 0 1531 1531" fill="none" xmlns="http://www.w3.org/2000/svg">
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
                    </svg>
                  ''',
                  width: 32,
                  height: 32,
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Draw Request',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    letterSpacing: -0.5,
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

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildSearchBar(),
          ),
          Text(
            companyName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const Text(
            "Construction Loan",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            contractorName,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          Text(
            contractorPhone,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          _buildSidebarItem(count: "2", label: "Draw Requests"),
          _buildSidebarItem(count: "6", label: "Inspections"),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF111827),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: 'Search line items...',
          hintStyle: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
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
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF6500E9)),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildSidebarItem({required String count, required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 208, 205, 205),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              count,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCircle({
    required double percentage,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        height: 140,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.17),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            SizedBox(
              height: 110,
              width: 130,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 110,
                    width: 110,
                    child: CircularProgressIndicator(
                      value: percentage / 100,
                      strokeWidth: 10,
                      backgroundColor: color.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  Text(
                    '${percentage.toInt()}%',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildDataTable() {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey[300]!),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fixed left column (Line Item + INSP)
              Container(
                width: 280,
                child: Column(
                  children: [
                    // Header for fixed column
                    Row(
                      children: [
                        Container(
                          width: 200,
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Colors.grey[200]!),
                              bottom: BorderSide(color: Colors.grey[200]!),
                            ),
                          ),
                          child: const Text(
                            'Line Item',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          width: 80,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[200]!),
                            ),
                          ),
                          child: const Text(
                            'INSP',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Data rows for fixed column
                    ...filteredRequests.map((item) => Row(
                      children: [
                        Container(
                          width: 200,
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Colors.grey[200]!),
                              bottom: BorderSide(color: Colors.grey[200]!),
                            ),
                          ),
                          child: Text(
                            item.lineItem,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          width: 80,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[200]!),
                            ),
                          ),
                          child: Text(
                            '${(item.inspectionPercentage * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    )).toList(),
                    // Spacer for status section
                    Container(
                      height: 92,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Scrollable section
              Expanded(
                child: SingleChildScrollView(
                  controller: _horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: (120.0 * numberOfDraws) + 170, // Width for draws + button + total
                    child: Column(
                      children: [
                        // Header row for scrollable section
                        Row(
                          children: [
                            ...List.generate(
                              numberOfDraws,
                              (index) => Container(
                                width: 120,
                                height: 50,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(color: Colors.grey[200]!),
                                    bottom: BorderSide(color: Colors.grey[200]!),
                                  ),
                                ),
                                child: Text(
                                  'Draw ${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            // Add Draw Button
                            Container(
                              width: 50,
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: Colors.grey[200]!),
                                  bottom: BorderSide(color: Colors.grey[200]!),
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: _addNewDraw,
                                tooltip: 'Add New Draw',
                                color: Color(0xFF6500E9),
                              ),
                            ),
                            // Total Drawn header
                            Container(
                              width: 120,
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: Colors.grey[200]!),
                                  bottom: BorderSide(color: Colors.grey[200]!),
                                ),
                              ),
                              child: const Text(
                                'Total Drawn',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Data rows for scrollable section
                        ...filteredRequests.map((item) => Row(
                          children: [
                            ...List.generate(
                              numberOfDraws,
                              (drawIndex) => _buildDrawCell(item, drawIndex + 1),
                            ),
                            // Placeholder for + button in data rows
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: Colors.grey[200]!),
                                  bottom: BorderSide(color: Colors.grey[200]!),
                                ),
                              ),
                            ),
                            _buildTotalDrawnCell(item),
                          ],
                        )).toList(),
                        // Status section
                        Row(
                          children: [
                            ...List.generate(
                              numberOfDraws,
                              (index) => _buildDrawStatusSection(index + 1),
                            ),
                            Container(
                              width: 50,
                              height: 92,
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: Colors.grey[200]!),
                                  top: BorderSide(color: Colors.grey[200]!),
                                ),
                              ),
                            ),
                            Container(
                              width: 120,
                              height: 92,
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: Colors.grey[200]!),
                                  top: BorderSide(color: Colors.grey[200]!),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
  Widget _buildDrawCell(DrawRequest item, int drawNumber) {
  final String key = '${item.lineItem}_$drawNumber';  // Explicitly define key as String
  final bool wouldExceedBudget = _wouldExceedBudget(item, drawNumber);  // Use the method we defined

  return Container(
    width: 120,
    height: 50,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      border: Border(
        left: BorderSide(color: Colors.grey[200]!),
        bottom: BorderSide(color: Colors.grey[200]!),
      ),
      color: Colors.white,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (drawNumber > 1)
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 16),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            onPressed: () => _moveDrawAmount(item, drawNumber, 'left'),
          ),
        Expanded(
          child: TextField(
            controller: _controllers[key] ?? TextEditingController(),
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: InputBorder.none,
              hintText: '-',
              prefixText: _controllers[key]?.text.isNotEmpty ?? false ? '\$' : '',
              prefixStyle: TextStyle(
                color: wouldExceedBudget ? Colors.red : const Color.fromARGB(120, 39, 133, 5),
              ),
            ),
            style: TextStyle(
              fontSize: 14,
              color: wouldExceedBudget ? Colors.red : const Color.fromARGB(120, 39, 133, 5),
              fontWeight: FontWeight.w500,
            ),
            onChanged: (value) {
              final newAmount = value.isEmpty ? null : double.tryParse(value);
              setState(() {
                item.draws[drawNumber] = newAmount;
              });
            },
          ),
        ),
        if (drawNumber < numberOfDraws)
          IconButton(
            icon: const Icon(Icons.arrow_forward, size: 16),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            onPressed: () => _moveDrawAmount(item, drawNumber, 'right'),
          ),
      ],
    ),
  );
}

  Widget _buildTotalDrawnCell(DrawRequest item) {
    return Container(
      width: 120,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '\$${item.totalDrawn.toStringAsFixed(2)}',
            style: TextStyle(
              color: item.totalDrawn > item.budget ? Colors.red : Colors.black87,
            ),
          ),
          if (item.totalDrawn > item.budget) ...[
            const SizedBox(width: 4),
            Tooltip(
              message: 'Total drawn amount exceeds budget',
              child: Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: Colors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _moveDrawAmount(DrawRequest item, int drawNumber, String direction) {
    setState(() {
      if (direction == 'left' && drawNumber > 1) {
        double? tempAmount = item.draws[drawNumber - 1];
        String tempStatus = item.drawStatuses[drawNumber - 1] ?? 'pending';
        
        item.draws[drawNumber - 1] = item.draws[drawNumber];
        item.drawStatuses[drawNumber - 1] = item.drawStatuses[drawNumber] ?? 'pending';
        
        item.draws[drawNumber] = tempAmount;
        item.drawStatuses[drawNumber] = tempStatus;
        
        // Update the controllers
        String currentKey = '${item.lineItem}_$drawNumber';
        _controllers[currentKey]?.text = item.draws[drawNumber]?.toString() ?? '';
        
        String prevKey = '${item.lineItem}_${drawNumber - 1}';
        _controllers[prevKey]?.text = item.draws[drawNumber - 1]?.toString() ?? '';
        
      } else if (direction == 'right' && drawNumber < numberOfDraws) {
        double? tempAmount = item.draws[drawNumber + 1];
        String tempStatus = item.drawStatuses[drawNumber + 1] ?? 'pending';
        
        item.draws[drawNumber + 1] = item.draws[drawNumber];
        item.drawStatuses[drawNumber + 1] = item.drawStatuses[drawNumber] ?? 'pending';
        
        item.draws[drawNumber] = tempAmount;
        item.drawStatuses[drawNumber] = tempStatus;
        
        // Update the controllers
        String currentKey = '${item.lineItem}_$drawNumber';
        _controllers[currentKey]?.text = item.draws[drawNumber]?.toString() ?? '';
        
        String nextKey = '${item.lineItem}_${drawNumber + 1}';
        _controllers[nextKey]?.text = item.draws[drawNumber + 1]?.toString() ?? '';
      }
    });
  }

  bool _wouldExceedBudget(DrawRequest item, int drawNumber) {
  final amount = item.draws[drawNumber];
  if (amount == null) return false;
  double totalWithoutThisDraw = item.totalDrawn - amount;
  return (totalWithoutThisDraw + amount) > item.budget;
}

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'submitted':
        return const Color(0xFF6500E9);
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            _buildTopNav(),
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSidebar(),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildProgressCircle(
                              percentage: totalDisbursed,
                              label: 'Amount Disbursed',
                              color: const Color(0xFFE91E63),
                            ),
                            const SizedBox(width: 24),
                            _buildProgressCircle(
                              percentage: projectCompletion,
                              label: 'Project Completion',
                              color: const Color.fromARGB(255, 51, 7, 163),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: _buildDataTable(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}