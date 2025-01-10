import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Add this enum at the top of the file
enum DrawStatus { pending, submitted, underReview, approved, declined }

class DrawRequest {
  final String lineItem;
  double inspectionPercentage;
  Map<int, double?> draws;
  Map<int, DrawStatus> drawStatuses; // Changed from String to DrawStatus
  double budget;
  String? lenderNote; // New field
  DateTime? reviewedAt; // New field

  DrawRequest({
    required this.lineItem,
    required this.inspectionPercentage,
    Map<int, double?>? draws,
    Map<int, DrawStatus>? drawStatuses,
    required this.budget,
    this.lenderNote,
    this.reviewedAt,
  })  : draws = draws ?? {1: null, 2: null, 3: null, 4: null},
        drawStatuses = drawStatuses ??
            {
              1: DrawStatus.pending,
              2: DrawStatus.pending,
              3: DrawStatus.pending,
              4: DrawStatus.pending
            };

  double get totalDrawn {
    return draws.values.fold<double>(0, (sum, amount) => sum + (amount ?? 0));
  }
}

class LenderReview {
  final String drawId;
  final DrawStatus status;
  final String? note;
  final DateTime timestamp;

  LenderReview({
    required this.drawId,
    required this.status,
    this.note,
    required this.timestamp,
  });
}

class ContractorLoanScreen extends StatefulWidget {
  final String loanId;
  final bool isLender; // Add this parameter

  const ContractorLoanScreen({
    super.key,
    required this.loanId,
    this.isLender = false, // Default to builder view
  });

  @override
  State<ContractorLoanScreen> createState() => _ContractorLoanScreenState();
}

class _ContractorLoanScreenState extends State<ContractorLoanScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  String _searchQuery = '';
  final Map<String, TextEditingController> _controllers = {};
  Timer? _refreshTimer;
  List<LenderReview> _lenderReviews = [];
  bool _isLoading = false;

  String companyName = "Loading...";
  String contractorName = "Loading...";
  String contractorEmail = "Loading...";
  String contractorPhone = "Loading...";

  final supabase = Supabase.instance.client;

  int numberOfDraws = 4;

  List<DrawRequest> _drawRequests = [
    DrawRequest(
      lineItem: 'No Line Items Yet',
      inspectionPercentage: 0.0,
      budget: 0.0,
      draws: {
        1: null,
        2: null,
        3: null,
        4: null,
      },
      drawStatuses: {
        1: DrawStatus.pending,
        2: DrawStatus.pending,
        3: DrawStatus.pending,
        4: DrawStatus.pending,
      },
    ),
  ];

  void testInitialSetup() {
    print("\n");
    print("Testing ContractorLoanScreen setup...");
    print("Loan ID received: ${widget.loanId}");
    print("Is Lender view: ${widget.isLender}");
  }

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    testInitialSetup();
    _loadLoanData();
    if (!widget.isLender) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _checkLenderUpdates();
      });
    }
  }

  /// CLAUDE MADE A CHANGE HERE
  Future<void> _loadLoanData() async {
    try {
      print("Starting data load for loan ID: ${widget.loanId}");
      setState(() => _isLoading = true);

      // Fetch loan details
      final loanResponse = await supabase
          .from('construction_loans')
          .select()
          .eq('loan_id', widget.loanId)
          .single();
      print("Loan data fetched: $loanResponse");

      // Fetch contractor details
      final contractorResponse = await supabase
          .from('contractors')
          .select()
          .eq('contractor_id', loanResponse['contractor_id'])
          .single();
      print("Contractor data fetched: $contractorResponse");

      // Fetch line items
      final lineItemsResponse = await supabase
          .from('construction_loan_line_items')
          .select()
          .eq('loan_id', widget.loanId);
      print("Line items fetched: ${lineItemsResponse.length} items");

      setState(() {
        companyName = contractorResponse['company_name'] ?? "Unknown Company";
        contractorName =
            contractorResponse['full_name'] ?? "Unknown Contractor";
        contractorEmail = contractorResponse['email'] ?? "No Email";
        contractorPhone = contractorResponse['phone'] ?? "No Phone";

        if (lineItemsResponse.isEmpty) {
          // Create a default line item if none exist
          _drawRequests = [
            DrawRequest(
              lineItem: 'No Line Items Yet',
              inspectionPercentage: 0.0,
              budget: 0.0,
              draws: {
                1: null,
                2: null,
                3: null,
                4: null,
              },
              drawStatuses: {
                1: DrawStatus.pending,
                2: DrawStatus.pending,
                3: DrawStatus.pending,
                4: DrawStatus.pending,
              },
            ),
          ];
        } else {
          _drawRequests = lineItemsResponse
              .map<DrawRequest>((item) => DrawRequest(
                    lineItem: item['category_name'],
                    inspectionPercentage: item['inspection_percentage'] ?? 0.0,
                    budget: item['budgeted_amount'].toDouble(),
                    draws: {
                      1: item['draw1_amount']?.toDouble(),
                      2: item['draw2_amount']?.toDouble(),
                      3: item['draw3_amount']?.toDouble(),
                      4: null,
                    },
                    drawStatuses: {
                      1: _getDrawStatusFromAmount(item['draw1_amount']),
                      2: _getDrawStatusFromAmount(item['draw2_amount']),
                      3: _getDrawStatusFromAmount(item['draw3_amount']),
                      4: DrawStatus.pending,
                    },
                  ))
              .toList();
        }

        _isLoading = false;
      });

      print("Data load completed successfully");
      print("Company Name: $companyName");
      print("Number of draw requests: ${_drawRequests.length}");
    } catch (e) {
      print('Error loading loan data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading loan data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// TODO:
  /// This is hardcoded.
  /// Remove it when the time comes.
  DrawStatus _getDrawStatusFromAmount(double? amount) {
    if (amount == null || amount == 0) {
      print("Amount $amount interpreted as PENDING");
      return DrawStatus.pending;
    }
    print("Amount $amount interpreted as APPROVED");
    return DrawStatus.approved;
  }

  void _initializeControllers() {
    for (var item in _drawRequests) {
      for (int i = 1; i <= numberOfDraws; i++) {
        final key = '${item.lineItem}_$i';
        final amount = item.draws[i];
        _controllers[key] =
            TextEditingController(text: amount?.toString() ?? '');
      }
    }
  }

  Future<void> _checkLenderUpdates() async {
    // Simulate API call to check for updates
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      for (var review in _lenderReviews) {
        for (var request in _drawRequests) {
          int drawNumber = int.parse(review.drawId.split('_')[1]);
          request.drawStatuses[drawNumber] = review.status;
          request.lenderNote = review.note;
          request.reviewedAt = review.timestamp;
        }
      }
    });
  }
  /// TODO: 
  /// Testing to see if we can propagate everything EXCEPT 
  /// the construction loan line items. 

  /// CLAUDE MADE A CHANGE HERE
  Future<void> _loadLoanData() async {
    print("The loan data function was called!");
    try {
      setState(() => _isLoading = true);

      // Fetch loan details
      final loanResponse = await supabase
          .from('construction_loans')
          .select()
          .eq('loan_id', widget.loanId)
          .single();

      // Fetch contractor details
      final contractorResponse = await supabase
          .from('contractors')
          .select()
          .eq('contractor_id', loanResponse['contractor_id'])
          .single();

      // // Fetch line items
      // final lineItemsResponse = await supabase
      //     .from('construction_loan_line_items')
      //     .select()
      //     .eq('loan_id', widget.loanId);

      setState(() {
        companyName = contractorResponse['company_name'] ?? "Unknown Company";
        contractorName =
            contractorResponse['full_name'] ?? "Unknown Contractor";
        contractorEmail = contractorResponse['email'] ?? "No Email";
        contractorPhone = contractorResponse['phone'] ?? "No Phone";

        // _drawRequests = lineItemsResponse
        //     .map<DrawRequest>((item) => DrawRequest(
        //           lineItem: item['category_name'],
        //           inspectionPercentage: item['inspection_percentage'] ?? 0.0,
        //           budget: item['budgeted_amount'].toDouble(),
        //           draws: {
        //             1: item['draw1_amount']?.toDouble(),
        //             2: item['draw2_amount']?.toDouble(),
        //             3: item['draw3_amount']?.toDouble(),
        //             4: null,
        //           },
        //           // Keep the original hardcoded status logic
        //           drawStatuses: {
        //             1: DrawStatus.approved,
        //             2: DrawStatus.pending,
        //             3: DrawStatus.pending,
        //             4: DrawStatus.pending,
        //           },
        //         ))
        //     .toList();

        _isLoading = false;
      });

      // Reinitialize controllers with new data
      _initializeControllers();
    } catch (e) {
      print('Error loading loan data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading loan data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _reviewDraw(int drawNumber, DrawStatus status, String? note) {
    setState(() {
      final review = LenderReview(
        drawId: 'draw_$drawNumber',
        status: status,
        note: note,
        timestamp: DateTime.now(),
      );
      _lenderReviews.add(review);

      for (var request in _drawRequests) {
        request.drawStatuses[drawNumber] = status;
        request.lenderNote = note;
        request.reviewedAt = review.timestamp;
      }
    });
  }

  void _submitDraw(int drawNumber) {
    setState(() {
      for (var request in _drawRequests) {
        if (request.draws[drawNumber] != null) {
          request.drawStatuses[drawNumber] = DrawStatus.submitted;
        }
      }
    });
  }

  void _addNewDraw() {
    setState(() {
      numberOfDraws++;
      for (var request in _drawRequests) {
        request.draws[numberOfDraws] = null;
        request.drawStatuses[numberOfDraws] = DrawStatus.pending;

        final key = '${request.lineItem}_$numberOfDraws';
        _controllers[key] = TextEditingController();
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
    double totalBudget =
        _drawRequests.fold<double>(0.0, (sum, request) => sum + request.budget);

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

  Future<void> _showReviewDialog(int drawNumber, DrawStatus status) async {
    final TextEditingController noteController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            status == DrawStatus.approved ? 'Approve Draw' : 'Decline Draw'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Add a note (optional)',
                hintText: 'Enter feedback for the builder',
              ),
              maxLines: 3,
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
              _reviewDraw(drawNumber, status, noteController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  status == DrawStatus.approved ? Colors.green : Colors.red,
            ),
            child: Text(status == DrawStatus.approved ? 'Approve' : 'Decline'),
          ),
        ],
      ),
    );
  }

  String _getButtonText(DrawStatus status) {
    switch (status) {
      case DrawStatus.approved:
        return 'Approved';
      case DrawStatus.declined:
        return 'Declined';
      case DrawStatus.submitted:
        return 'Submitted';
      case DrawStatus.underReview:
        return 'Under Review';
      case DrawStatus.pending:
      default:
        return 'Submit';
    }
  }

  Color _getStatusColor(DrawStatus status) {
    switch (status) {
      case DrawStatus.approved:
        return const Color(0xFF22C55E);
      case DrawStatus.declined:
        return const Color(0xFFEF4444);
      case DrawStatus.submitted:
        return const Color(0xFF6500E9);
      case DrawStatus.underReview:
        return const Color(0xFF6366F1);
      case DrawStatus.pending:
      default:
        return const Color(0xFFF97316);
    }
  }

  bool _wouldExceedBudget(DrawRequest item, int drawNumber) {
    final amount = item.draws[drawNumber];
    if (amount == null) return false;
    double totalWithoutThisDraw = item.totalDrawn - amount;
    return (totalWithoutThisDraw + amount) > item.budget;
  }

  void _moveDrawAmount(DrawRequest item, int drawNumber, String direction) {
    setState(() {
      if (direction == 'left' && drawNumber > 1) {
        double? tempAmount = item.draws[drawNumber - 1];
        DrawStatus tempStatus =
            item.drawStatuses[drawNumber - 1] ?? DrawStatus.pending;

        item.draws[drawNumber - 1] = item.draws[drawNumber];
        item.drawStatuses[drawNumber - 1] =
            item.drawStatuses[drawNumber] ?? DrawStatus.pending;

        item.draws[drawNumber] = tempAmount;
        item.drawStatuses[drawNumber] = tempStatus;

        String currentKey = '${item.lineItem}_$drawNumber';
        _controllers[currentKey]?.text =
            item.draws[drawNumber]?.toString() ?? '';

        String prevKey = '${item.lineItem}_${drawNumber - 1}';
        _controllers[prevKey]?.text =
            item.draws[drawNumber - 1]?.toString() ?? '';
      } else if (direction == 'right' && drawNumber < numberOfDraws) {
        double? tempAmount = item.draws[drawNumber + 1];
        DrawStatus tempStatus =
            item.drawStatuses[drawNumber + 1] ?? DrawStatus.pending;

        item.draws[drawNumber + 1] = item.draws[drawNumber];
        item.drawStatuses[drawNumber + 1] =
            item.drawStatuses[drawNumber] ?? DrawStatus.pending;

        item.draws[drawNumber] = tempAmount;
        item.drawStatuses[drawNumber] = tempStatus;

        String currentKey = '${item.lineItem}_$drawNumber';
        _controllers[currentKey]?.text =
            item.draws[drawNumber]?.toString() ?? '';

        String nextKey = '${item.lineItem}_${drawNumber + 1}';
        _controllers[nextKey]?.text =
            item.draws[drawNumber + 1]?.toString() ?? '';
      }
    });
  }

  Widget _buildDrawCell(DrawRequest item, int drawNumber) {
    final String key = '${item.lineItem}_$drawNumber';
    final bool wouldExceedBudget = _wouldExceedBudget(item, drawNumber);
    final bool isEditable = item.drawStatuses[drawNumber] == DrawStatus.pending;

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
          if (drawNumber > 1 && isEditable)
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
              enabled: isEditable,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
                hintText: '-',
                prefixText:
                    _controllers[key]?.text.isNotEmpty ?? false ? '\$' : '',
                prefixStyle: TextStyle(
                  color: wouldExceedBudget
                      ? Colors.red
                      : const Color.fromARGB(120, 39, 133, 5),
                ),
              ),
              style: TextStyle(
                fontSize: 14,
                color: wouldExceedBudget
                    ? Colors.red
                    : const Color.fromARGB(120, 39, 133, 5),
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
          if (drawNumber < numberOfDraws && isEditable)
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
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '\$${item.totalDrawn.toStringAsFixed(2)}',
            style: TextStyle(
              color:
                  item.totalDrawn > item.budget ? Colors.red : Colors.black87,
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

  Widget _buildDrawStatusSection(int drawNumber) {
    // Initialize with default values
    DrawStatus status = DrawStatus.pending;
    String? lenderNote;
    DateTime? reviewedAt;

    // Only try to access first item if list is not empty
    if (_drawRequests.isNotEmpty && drawNumber <= numberOfDraws) {
      status =
          _drawRequests.first.drawStatuses[drawNumber] ?? DrawStatus.pending;
      lenderNote = _drawRequests.first.lenderNote;
      reviewedAt = _drawRequests.first.reviewedAt;
    }

    Color statusColor = _getStatusColor(status);

    // Rest of your existing _buildDrawStatusSection code...

    return Stack(
      children: [
        Container(
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
              // Status indicator with timestamp
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      status.toString().split('.').last.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (reviewedAt != null && status != DrawStatus.pending)
                      Text(
                        DateFormat('MM/dd/yy HH:mm').format(reviewedAt),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Show different buttons based on user type
              if (widget.isLender && status == DrawStatus.submitted)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () =>
                          _showReviewDialog(drawNumber, DrawStatus.approved),
                      tooltip: 'Approve',
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () =>
                          _showReviewDialog(drawNumber, DrawStatus.declined),
                      tooltip: 'Decline',
                    ),
                  ],
                )
              else if (!widget.isLender)
                ElevatedButton(
                  onPressed: status == DrawStatus.pending
                      ? () => _submitDraw(drawNumber)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 61, 143, 96),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: const Size(80, 32),
                    disabledBackgroundColor: Colors.grey[400],
                  ),
                  child: Text(
                    _getButtonText(status),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Show lender note if available
              if (lenderNote != null && lenderNote.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Tooltip(
                    message: lenderNote,
                    child: const Icon(Icons.comment, size: 16),
                  ),
                ),
            ],
          ),
        ),
        // Status banner
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 3,
            color: statusColor,
          ),
        ),
      ],
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
            child: SingleChildScrollView(
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
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
                        ...filteredRequests
                            .map((item) => Row(
                                  children: [
                                    Container(
                                      width: 200,
                                      height: 50,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      alignment: Alignment.centerLeft,
                                      decoration: BoxDecoration(
                                        border: Border(
                                          right: BorderSide(
                                              color: Colors.grey[200]!),
                                          bottom: BorderSide(
                                              color: Colors.grey[200]!),
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
                                          bottom: BorderSide(
                                              color: Colors.grey[200]!),
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
                                ))
                            .toList(),
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
                        width: (120.0 * numberOfDraws) + 170,
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
                                        left: BorderSide(
                                            color: Colors.grey[200]!),
                                        bottom: BorderSide(
                                            color: Colors.grey[200]!),
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
                                if (!widget.isLender)
                                  Container(
                                    width: 50,
                                    height: 50,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        left: BorderSide(
                                            color: Colors.grey[200]!),
                                        bottom: BorderSide(
                                            color: Colors.grey[200]!),
                                      ),
                                    ),
                                    child: IconButton(
                                      icon:
                                          const Icon(Icons.add_circle_outline),
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
                                      left:
                                          BorderSide(color: Colors.grey[200]!),
                                      bottom:
                                          BorderSide(color: Colors.grey[200]!),
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
                            ...filteredRequests
                                .map((item) => Row(
                                      children: [
                                        ...List.generate(
                                          numberOfDraws,
                                          (drawIndex) => _buildDrawCell(
                                              item, drawIndex + 1),
                                        ),
                                        if (!widget.isLender)
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              border: Border(
                                                left: BorderSide(
                                                    color: Colors.grey[200]!),
                                                bottom: BorderSide(
                                                    color: Colors.grey[200]!),
                                              ),
                                            ),
                                          ),
                                        _buildTotalDrawnCell(item),
                                      ],
                                    ))
                                .toList(),
                            // Status section
                            Row(
                              children: [
                                ...List.generate(
                                  numberOfDraws,
                                  (index) => _buildDrawStatusSection(index + 1),
                                ),
                                if (!widget.isLender)
                                  Container(
                                    width: 50,
                                    height: 92,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        left: BorderSide(
                                            color: Colors.grey[200]!),
                                        top: BorderSide(
                                            color: Colors.grey[200]!),
                                      ),
                                    ),
                                  ),
                                Container(
                                  width: 120,
                                  height: 92,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left:
                                          BorderSide(color: Colors.grey[200]!),
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
                Text(
                  "Construction Loan Dashboard",
                  style: const TextStyle(
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
    _refreshTimer?.cancel();
    _searchController.dispose();
    _horizontalScrollController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
