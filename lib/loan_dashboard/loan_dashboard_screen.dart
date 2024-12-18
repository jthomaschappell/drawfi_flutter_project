import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tester/loan_dashboard/chat/loan_chat_section.dart';
import 'package:tester/loan_dashboard/models/loan_line_item.dart';

final supabase = Supabase.instance.client;

class LoanDashboardScreen extends StatefulWidget {
  final String loanId;

  const LoanDashboardScreen({super.key, required this.loanId});

  @override
  State<LoanDashboardScreen> createState() => _LoanDashboardScreenState();
}

class _LoanDashboardScreenState extends State<LoanDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final supabase = Supabase.instance.client;
  String companyName = "Loading...";
  String contractorName = "Loading...";
  String contractorEmail = "Loading...";
  String contractorPhone = "Loading...";

  List<LoanLineItem> _loanLineItems = [
    LoanLineItem(
      lineItem: 'Foundation Work',
      // inspected: true,
      inspectionPercentage: 0.3,
      draw1: 15000, // these will come from draws
      draw1Status: 'pending',
      draw2: 25000,
      draw2Status: 'pending',
    ),
    LoanLineItem(
      lineItem: 'Framing',
      inspectionPercentage: .34,
      draw1: 30000,
      draw1Status: 'pending',
    ),
    LoanLineItem(
      lineItem: 'Electrical',
      inspectionPercentage: .55,
      draw1: 12000,
      draw1Status: 'pending',
    ),
    LoanLineItem(
      lineItem: 'Plumbing',
      inspectionPercentage: .13,
      draw1: 8000,
      draw2: 10000,
      draw1Status: 'pending',
      draw2Status: 'pending',
    ),
    LoanLineItem(
      lineItem: 'HVAC Installation',
      inspectionPercentage: 0,
      draw1: 20000,
      draw1Status: 'pending',
    ),
    LoanLineItem(
      lineItem: 'Roofing',
      inspectionPercentage: .4,
      draw1: 25000,
      draw1Status: 'pending',
    ),
    LoanLineItem(
      lineItem: 'Interior Finishing',
      inspectionPercentage: .45,
      draw1: 18000,
      draw1Status: 'pending',
    ),
  ];

  List<LoanLineItem> get filteredRequests {
    if (_searchQuery.isEmpty) return _loanLineItems;
    return _loanLineItems
        .where(
          (request) => request.lineItem.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  double get totalDisbursed {
    return _loanLineItems.fold(0, (sum, request) => sum + request.totalDrawn);
  }

  // calculates average progress over all the items, converting to a percentage.
  double get projectCompletion {
    double totalProgress =
        _loanLineItems.fold(0, (sum, item) => sum + item.inspectionPercentage);
    return (totalProgress / _loanLineItems.length) * 100;
  }

  @override
  void initState() {
    super.initState();
    _setContractorDetails();
    fetchLoanLineItems();
  }

  Future<void> fetchLoanLineItems() async {
    print(
      "Loan line items from the database were: $_loanLineItems",
    );
    try {
      final response = await supabase
          .from('construction_loan_line_items')
          .select()
          .eq('loan_id', widget.loanId);

      print("This was the response: $response");

      if (response.isEmpty) {
        throw Exception('No line items found for loan ID: ${widget.loanId}');
      }

      setState(
        () {
          _loanLineItems = response
              .map(
                (entity) => LoanLineItem(
                  lineItem: entity['category_name'] ?? "-",
                  inspectionPercentage: entity['inspection_percentage'] ?? 0,
                  draw1: entity['draw1_amount'] ?? 0.0,
                  draw1Status: entity['draw1_status'] ?? 'pending',
                  draw2: entity['draw2_amount'] ?? 0,
                  draw2Status: entity['draw2_status'] ?? 'pending',
                  budget: entity['budgeted_amount'] ?? 0,
                ),
              )
              .toList();
        },
      );

      print(
        "Loan line items from the database were: $_loanLineItems",
      );
    } catch (e) {
      print('Error fetching line items: $e');
    }
  }

  Future<void> _setContractorDetails() async {
    try {
      // Fetch contractor_id for the loan
      final loanResponse = await supabase
          .from('construction_loans')
          .select('contractor_id')
          .eq('loan_id', widget.loanId)
          .single();
      final contractorId = loanResponse['contractor_id'];
      print("The contractor id is $contractorId");

      // fetch contractor name for the contractor id.
      final contractorResponse = await supabase
          .from('contractors')
          .select()
          .eq('contractor_id', contractorId)
          .single();
      print("This is the contractor response: $contractorResponse");

      // Wrap all state updates in setState
      setState(() {
        contractorName = contractorResponse['full_name'];
        companyName = contractorResponse['company_name'];
        contractorEmail = contractorResponse['email'];
        contractorPhone = contractorResponse['phone'];
      });

      print("Contractor details name is $contractorName");
      print("Contractor details company name is $companyName");
      print("Contractor details email is $contractorEmail");
      print("Contractor details phone is $contractorPhone");
    } catch (e) {
      print("Error fetching contractor name: $e");
      setState(() {
        print("The pulling didn't work!");
        // Optionally set error states here
        contractorName = "Error loading";
        companyName = "Error loading";
        contractorEmail = "Error loading";
        contractorPhone = "Error loading";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 20,
        ), // Increased padding
        child: Column(
          children: [
            _buildTopNav(),
            const SizedBox(
              height: 20,
            ), // Increased spacing
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSidebar(),
                  const SizedBox(width: 24), // Increased spacing
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildProgressCircle(
                              percentage: (totalDisbursed / 200000) * 100,
                              label: 'Amount Disbursed',
                              color: const Color(0xFFE91E63),
                            ),
                            const SizedBox(width: 24), // Increased spacing
                            _buildProgressCircle(
                              percentage: projectCompletion,
                              label: 'Project Completion',
                              color: const Color.fromARGB(255, 51, 7, 163),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24), // Increased spacing
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

  void _updateDrawStatus(LoanLineItem item, int drawNumber, String status) {
    setState(() {
      switch (drawNumber) {
        case 1:
          item.draw1Status = status;
          break;
        case 2:
          item.draw2Status = status;
          break;
        case 3:
          item.draw3Status = status;
          break;
      }
    });
  }

  // this shows a dialog popup with settings.
  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.notifications_active),
                title: const Text('Email Notifications'),
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Dark Mode'),
                trailing: Switch(
                  value: false,
                  onChanged: (value) {},
                ),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                trailing: DropdownButton<String>(
                  value: 'English',
                  items: ['English', 'Spanish', 'French']
                      .map((lang) => DropdownMenuItem(
                            value: lang,
                            child: Text(lang),
                          ))
                      .toList(),
                  onChanged: (value) {},
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDrawEditDialog(LoanLineItem request, int drawNumber) {
    final controller = TextEditingController(
      text: drawNumber == 1
          ? request.draw1?.toString()
          : drawNumber == 2
              ? request.draw2?.toString()
              : request.draw3?.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Draw $drawNumber'),
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
                final amount = double.tryParse(controller.text);
                switch (drawNumber) {
                  case 1:
                    request.draw1 = amount;
                    break;
                  case 2:
                    request.draw2 = amount;
                    break;
                  case 3:
                    request.draw3 = amount;
                    break;
                }
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
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: 'Search by name, loan #, etc...',
          hintStyle: const TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: Colors.black,
          ),
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
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildDrawStatusWidget(LoanLineItem item, int drawNumber) {
    String? status;
    double? amount;

    switch (drawNumber) {
      case 1:
        status = item.draw1Status;
        amount = item.draw1;
        break;
      case 2:
        status = item.draw2Status;
        amount = item.draw2;
        break;
      case 3:
        status = item.draw3Status;
        amount = item.draw3;
        break;
    }

    if (amount == null) {
      return const Expanded(child: SizedBox());
    }

    Color getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'approved':
          return Colors.green;
        case 'declined':
          return Colors.red;
        case 'pending':
        default:
          return Colors.orange;
      }
    }

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Status text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: getStatusColor(status ?? 'pending').withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status?.toUpperCase() ?? 'PENDING',
              style: TextStyle(
                color: getStatusColor(status ?? 'pending'),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (status?.toLowerCase() == 'pending') const SizedBox(height: 4),
          // Action buttons
          if (status?.toLowerCase() == 'pending')
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: Colors.green,
                  onPressed: () =>
                      _updateDrawStatus(item, drawNumber, 'approved'),
                  tooltip: 'Approve',
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.cancel_outlined),
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: Colors.red,
                  onPressed: () =>
                      _updateDrawStatus(item, drawNumber, 'declined'),
                  tooltip: 'Decline',
                ),
              ],
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
        height: 140, // Increased height
        padding: const EdgeInsets.symmetric(
            horizontal: 28, vertical: 20), // Increased padding
        decoration: BoxDecoration(
          color: color.withOpacity(0.17),
          borderRadius: BorderRadius.circular(16), // Increased radius
        ),
        child: Row(
          children: [
            SizedBox(
              height: 110, // Increased size
              width: 130, // Increased size
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 110,
                    width: 110,
                    child: CircularProgressIndicator(
                      value: percentage / 100,
                      strokeWidth: 10, // Increased stroke width
                      backgroundColor: color.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  Text(
                    '${percentage.toInt()}%',
                    style: const TextStyle(
                      fontSize: 20, // Increased font size
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
                      fontSize: 18, // Increased font size
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  if (label == 'Amount Disbursed')
                    Text(
                      '\$${totalDisbursed.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16, // Increased font size
                        color: color,
                        fontWeight: FontWeight.w500,
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

  Widget _buildTableHeader(String text, {bool isFirst = false}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.only(left: isFirst ? 16 : 78),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(
    String text, {
    bool isFirst = false,
    bool isAmount = false,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.only(left: isFirst ? 16 : 8),
        child: Text(
          isAmount ? '\$${double.parse(text).toStringAsFixed(2)}' : text,
          style: TextStyle(
            fontSize: 14,
            color: isAmount ? Colors.green[700] : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildEditableTableCell(String text,
      {bool isFirst = false, bool isAmount = false, VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.only(left: isFirst ? 16 : 68),
          child: Text(
            isAmount ? '\$${double.parse(text).toStringAsFixed(2)}' : text,
            style: TextStyle(
              fontSize: 14,
              color: isAmount ? Colors.green[700] : Colors.black87,
              decoration: onTap != null ? TextDecoration.underline : null,
            ),
          ),
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
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 25),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                _buildTableHeader('Line Item', isFirst: true),
                _buildTableHeader('INSP'),
                _buildTableHeader('Draw 1'),
                _buildTableHeader('Draw 2'),
                _buildTableHeader('Draw 3'),
                _buildTableHeader('Budget', isFirst: true),
              ],
            ),
          ),
          // Table content
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: filteredRequests.length,
              itemBuilder: (context, index) {
                final item = filteredRequests[index];
                return Container(
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      // line item description column.
                      _buildTableCell(
                        item.lineItem,
                        isFirst: true,
                      ),
                      // inspection percentage column.
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${(item.inspectionPercentage * 100).toStringAsFixed(1)}%",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Draw 1.
                      // It can be edited.
                      _buildEditableTableCell(
                        item.draw1?.toString() ?? '-',
                        isAmount: item.draw1 != null,
                        onTap: () => _showDrawEditDialog(item, 1),
                      ),
                      // Draw 2.
                      // It can be edited.
                      _buildEditableTableCell(
                        item.draw2?.toString() ?? '-',
                        isAmount: item.draw2 != null,
                        onTap: () => _showDrawEditDialog(item, 2),
                      ),
                      // Draw 3.
                      // It can be edited.
                      _buildEditableTableCell(
                        item.draw3?.toString() ?? '-',
                        isAmount: item.draw3 != null,
                        onTap: () => _showDrawEditDialog(item, 3),
                      ),
                      // Budget can be edited.
                      /**
                       * TODO: 
                       * 
                       * I edited the loan line item to have a budget field. 
                       * 
                       * I edited the header to have aheader titled Budget 
                       * AND I made an editable table cell for budget. 
                       */
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            '\$${item.budget.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Status lines at the bottom
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                // Empty space for Line Item and INSP columns
                Expanded(flex: 2, child: Container()),
                // Draw 1 Status
                Expanded(child: _buildVerticalDrawStatus(1)),
                // Draw 2 Status
                Expanded(child: _buildVerticalDrawStatus(2)),
                // Draw 3 Status
                Expanded(child: _buildVerticalDrawStatus(3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDrawStatus(int drawNumber) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.check_circle_outline),
          iconSize: 16,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          color: Colors.green,
          onPressed: () => _approveVerticalDraw(drawNumber),
          tooltip: 'Approve Draw $drawNumber',
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'PENDING',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.cancel_outlined),
          iconSize: 16,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          color: Colors.red,
          onPressed: () => _declineVerticalDraw(drawNumber),
          tooltip: 'Decline Draw $drawNumber',
        ),
      ],
    );
  }

  void _approveVerticalDraw(int drawNumber) {
    setState(() {
      for (var item in _loanLineItems) {
        switch (drawNumber) {
          case 1:
            if (item.draw1 != null) item.draw1Status = 'approved';
            break;
          case 2:
            if (item.draw2 != null) item.draw2Status = 'approved';
            break;
          case 3:
            if (item.draw3 != null) item.draw3Status = 'approved';
            break;
        }
      }
    });
  }

  void _declineVerticalDraw(int drawNumber) {
    setState(() {
      for (var item in _loanLineItems) {
        switch (drawNumber) {
          case 1:
            if (item.draw1 != null) item.draw1Status = 'declined';
            break;
          case 2:
            if (item.draw2 != null) item.draw2Status = 'declined';
            break;
          case 3:
            if (item.draw3 != null) item.draw3Status = 'declined';
            break;
        }
      }
    });
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
          const Padding(
            padding: EdgeInsets.all(16),
            child: LoanChatSection(),
          ),
          const SizedBox(height: 16),
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
                <stop stop-color="#FF1970"/><stop offset="0.145" stop-color="#E81766"/>
                <stop offset="0.307358" stop-color="#DB12AF"/><stop offset="0.43385" stop-color="#BF09D5"/>
                <stop offset="0.556871" stop-color="#A200FA"/><stop offset="0.698313" stop-color="#6500E9"/>
                <stop offset="0.855" stop-color="#3C17DB"/><stop offset="1" stop-color="#2800D7"/>
                </linearGradient></defs></svg>''',
                  width: 32,
                  height: 32,
                ),
                const SizedBox(width: 24),
                _buildNavItem(
                  icon: Icons.home_outlined,
                  isActive: true,
                  onTap: () => Navigator.of(context).pop(),
                ),
                _buildNavItem(
                  icon: Icons.settings_outlined,
                  onTap: _showSettings,
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Icon(
          icon,
          color: isActive ? const Color(0xFF6500E9) : Colors.grey[600],
          size: 24,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
