import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tester/loan_dashboard/chat/loan_chat_section.dart';
import 'package:tester/loan_dashboard/models/loan_line_item.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

final supabase = Supabase.instance.client;
class LoanLineItem {
  String lineItem;
  double inspectionPercentage;
  double? draw1;
  String draw1Status;
  double? draw2;
  String draw2Status;
  double? draw3;
  String draw3Status;
  double? draw4;
  String draw4Status;
  double budget;

  LoanLineItem({
    required this.lineItem,
    required this.inspectionPercentage,
    this.draw1,
    this.draw1Status = 'pending',
    this.draw2,
    this.draw2Status = 'pending',
    this.draw3,
    this.draw3Status = 'pending',
    this.draw4,
    this.draw4Status = 'pending',
    required this.budget,
  });

  double get totalDrawn {
    return (draw1 ?? 0) + (draw2 ?? 0) + (draw3 ?? 0) + (draw4 ?? 0);
  }
}

class LoanDashboardScreen extends StatefulWidget {
  final String loanId;

  const LoanDashboardScreen({super.key, required this.loanId});

  @override
  State<LoanDashboardScreen> createState() => _LoanDashboardScreenState();
}

class _LoanDashboardScreenState extends State<LoanDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  String _searchQuery = '';
  String companyName = "Loading...";
  String contractorName = "Loading...";
  String contractorEmail = "Loading...";
  String contractorPhone = "Loading...";
  
  // Number of draws to show (can be dynamic)
  int numberOfDraws = 4; // New value
  
  // Initialize default loan items
  List<LoanLineItem> _loanLineItems = [
    LoanLineItem(
      lineItem: 'Default Value: Foundation Work',
      inspectionPercentage: 0.3,
      draw1: 0,
      draw1Status: 'pending',
      draw2: 25000,
      draw2Status: 'pending',
      budget: 153000,
    ),
    LoanLineItem(
      lineItem: 'Default Value: Framing',
      inspectionPercentage: 0.34,
      draw1: 0,
      draw1Status: 'pending',
      budget: 153000,
    ),
    LoanLineItem(
      lineItem: 'Default Value: Electrical',
      inspectionPercentage: .55,
      draw1: 0,
      draw1Status: 'pending',
      budget: 111000,
    ),
    LoanLineItem(
      lineItem: 'Default Value: Plumbing',
      inspectionPercentage: .13,
      draw1: 0,
      draw2: 10000,
      draw1Status: 'pending',
      draw2Status: 'pending',
      budget: 153000,
    ),
    LoanLineItem(
      lineItem: 'Default Value: HVAC Installation',
      inspectionPercentage: 0,
      draw1: 0,
      draw1Status: 'pending',
      budget: 153000,
    ),
    LoanLineItem(
      lineItem: 'Default Value: Roofing',
      inspectionPercentage: .4,
      draw1: 0,
      draw1Status: 'pending',
      budget: 153000,
    ),
    LoanLineItem(
      lineItem: 'Default Value: Interior Finishing',
      inspectionPercentage: .45,
      draw1: 0,
      draw1Status: 'pending',
      budget: 153000,
    ),
  ];

  Map<int, String> drawStatuses = {};

  @override
  void initState() {
    super.initState();
    // Initialize draw statuses for all possible draws
    for (int i = 1; i <= numberOfDraws; i++) {
      drawStatuses[i] = 'pending';
    }
    _setContractorDetails();
    fetchLoanLineItems();
  }

  List<LoanLineItem> get filteredLineItems {
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
    double totalDrawn = _loanLineItems.fold<double>(
        0.0, (sum, request) => sum + request.totalDrawn);
    double totalBudget = _loanLineItems.fold<double>(
        0.0, (sum, request) => sum + request.budget);

    if (totalBudget == 0) return 0;
    return (totalDrawn / totalBudget) * 100;
  }

  double get projectCompletion {
    double weightedSum = 0;
    double totalBudget = 0;

    for (var item in _loanLineItems) {
      weightedSum += (item.inspectionPercentage * item.budget);
      totalBudget += item.budget;
    }

    if (totalBudget == 0) return 0;
    return (weightedSum / totalBudget) * 100;
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
                _buildNavItem(
                  icon: Icons.home_outlined,
                  isActive: true,
                  onTap: () => Navigator.of(context).pop(),
                ),
                _buildNavItem(
                  icon: Icons.settings_outlined,
                  onTap: _showSettings,
                ),
                _buildNavItem(
                  icon: Icons.share_outlined,
                  onTap: () => _shareLoanDashboard(),
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
  Future<void> _shareLoanDashboard() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              '$companyName - Construction Loan Details',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 20),

          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Contractor: $contractorName'),
              pw.Text('Phone: $contractorPhone'),
              pw.Text('Email: $contractorEmail'),
            ],
          ),
          pw.SizedBox(height: 20),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Amount Disbursed: ${totalDisbursed.toStringAsFixed(1)}%',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Total Amount: \$${_loanLineItems.fold<double>(0.0, (sum, item) => sum + item.totalDrawn).toStringAsFixed(2)}',
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Project Completion: ${projectCompletion.toStringAsFixed(1)}%',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          pw.Table.fromTextArray(
            context: context,
            headerAlignment: pw.Alignment.centerLeft,
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
            headerHeight: 25,
            cellHeight: 40,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
            cellStyle: const pw.TextStyle(
              color: PdfColors.black,
            ),
            headers: ['Line Item', 'INSP', 'Draw 1', 'Draw 2', 'Draw 3', 'Total Drawn', 'Budget'],
            data: _loanLineItems.map((item) => [
              item.lineItem,
              '${(item.inspectionPercentage * 100).toStringAsFixed(1)}%',
              item.draw1 != null ? '\$${item.draw1!.toStringAsFixed(2)}' : '-',
              item.draw2 != null ? '\$${item.draw2!.toStringAsFixed(2)}' : '-',
              item.draw3 != null ? '\$${item.draw3!.toStringAsFixed(2)}' : '-',
              '\$${item.totalDrawn.toStringAsFixed(2)}',
              '\$${item.budget.toStringAsFixed(2)}',
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${companyName.replaceAll(' ', '_')}_loan_details.pdf',
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 20,
        ),
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
  // Database methods
  Future<void> fetchLoanLineItems() async {
    print("Loan line items were: $_loanLineItems");

    try {
      final response = await supabase
          .from('construction_loan_line_items')
          .select()
          .eq('loan_id', widget.loanId);

      print("This was the response: $response");

      if (response.isEmpty) {
        throw Exception(
            'No line items found for loan ID: ${widget.loanId}.\nUsing default values.');
      }
      setState(() {
        _loanLineItems = response
            .map(
              (entity) => LoanLineItem(
                lineItem: entity['category_name'] ?? "-",
                inspectionPercentage: entity['inspection_percentage'] ?? 0,
                draw1: entity['draw1_amount'] ?? 0.0,
                draw1Status: entity['draw1_status'] ?? 'pending',
                draw2: entity['draw2_amount'] ?? 0.0,
                draw2Status: entity['draw2_status'] ?? 'pending',
                draw3: entity['draw3_amount'] ?? 0.0,
                draw3Status: entity['draw3_status'] ?? 'pending',
                budget: entity['budgeted_amount'] ?? 0.0,
              ),
            )
            .toList();
      });
    } catch (e) {
      print('Error fetching line items: $e');
    }
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
        const SizedBox(height: 16),
        _buildUploadSection(), // Add this line
        const Spacer(),
      ],
    ),
  );
}

// Add this method to handle file uploads
Future<void> _handleFileUpload(List<PlatformFile> files) async {
  final supabase = Supabase.instance.client;

  for (final file in files) {
    try {
      // Show upload progress
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uploading ${file.name}...'),
          duration: const Duration(seconds: 1),
        ),
      );

      // Generate unique filename under loan ID folder
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = path.extension(file.name);
      final fileName = '${widget.loanId}/${timestamp}_${file.name}';

      // Upload file to Supabase Storage
      if (file.bytes != null) {
        await supabase.storage
            .from('project_documents')
            .uploadBinary(
              fileName,
              file.bytes!,
              fileOptions: FileOptions(
                contentType: file.bytes != null ? 'application/octet-stream' : null,
              ),
            );

        // Get public URL
        final fileUrl = supabase.storage
            .from('project_documents')
            .getPublicUrl(fileName);

        // Insert file record into database
        await supabase.from('project_documents').insert({
          'loan_id': widget.loanId,
          'file_url': fileUrl,
          'file_name': file.name,
          'uploaded_by': supabase.auth.currentUser!.id,
          'file_type': fileExtension.replaceAll('.', ''),
          'file_status': 'active'
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${file.name} uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error uploading file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading ${file.name}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

Widget _buildUploadSection() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.upload_file,
              size: 20,
              color: Color(0xFF6B7280),
            ),
            SizedBox(width: 8),
            Text(
              'Upload Files',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DottedBorder(
          borderType: BorderType.RRect,
          radius: const Radius.circular(8),
          color: const Color(0xFF4F46E5),
          dashPattern: const [6, 3],
          strokeWidth: 1,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              children: [
                const Icon(
                  Icons.cloud_upload_outlined,
                  size: 24,
                  color: Color(0xFF4F46E5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Drag & drop or',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      allowMultiple: true,
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'jpg', 'png', 'doc', 'docx'],
                      withData: true,
                    );
                    if (result != null) {
                      await _handleFileUpload(result.files);
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: const Text(
                    'browse files',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4F46E5),
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

  Widget _buildProgressCircle({
    required double percentage,
    required String label,
    required Color color,
  }) {
    double totalDrawnAmount = label == 'Amount Disbursed'
        ? _loanLineItems.fold<double>(
            0.0, (sum, request) => sum + request.totalDrawn)
        : 0.0;

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
                  if (label == 'Amount Disbursed')
                    Text(
                      '\$${totalDrawnAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
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

  Future<void> _updateLineItemInDatabase(
      LoanLineItem item, int drawNumber, double? amount) async {
    try {
      final drawColumn = 'draw${drawNumber}_amount';

      await supabase
          .from('construction_loan_line_items')
          .update({
            drawColumn: amount,
          })
          .eq('loan_id', widget.loanId)
          .eq('category_name', item.lineItem);

      print('Successfully updated draw $drawNumber for ${item.lineItem} to $amount');
    } catch (e) {
      print('Error updating line item in database: $e');
      _showError(e.toString());
    }
  }

  Future<void> _setContractorDetails() async {
    try {
      final loanResponse = await supabase
          .from('construction_loans')
          .select('contractor_id')
          .eq('loan_id', widget.loanId)
          .single();
      final contractorId = loanResponse['contractor_id'];

      final contractorResponse = await supabase
          .from('contractors')
          .select()
          .eq('contractor_id', contractorId)
          .single();

      setState(() {
        contractorName = contractorResponse['full_name'];
        companyName = contractorResponse['company_name'];
        contractorEmail = contractorResponse['email'];
        contractorPhone = contractorResponse['phone'];
      });
    } catch (e) {
      print("Error fetching contractor name: $e");
      setState(() {
        contractorName = "Error loading";
        companyName = "Error loading";
        contractorEmail = "Error loading";
        contractorPhone = "Error loading";
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
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
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              await _updateLineItemInDatabase(request, drawNumber, amount);
              setState(() {
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
  // UI Building Methods for Table
  // This replaces the existing _buildDataTable() method
  // Replace these methods in your _LoanDashboardScreenState class

Widget _buildDataTable() {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey[300]!),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        // Header row
        Row(
          children: [
            // Fixed left headers
            Row(
              children: [
                Container(
                  width: 200,
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
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
            // Scrollable middle section
            Expanded(
              child: SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    numberOfDraws,
                    (index) => Container(
                      width: 120,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Colors.grey[200]!),
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
                ),
              ),
            ),
            // Fixed right headers
            Container(
              width: 240, // 120 * 2 for Total Drawn and Budget
              child: Row(
                children: [
                  Container(
                    width: 120,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Colors.grey[200]!),
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
                  Container(
                    width: 120,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: const Text(
                      'Budget',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Table body
        Expanded(
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fixed left column
                Column(
                  children: filteredLineItems.map((item) => Row(
                    children: [
                      Container(
                        width: 200,
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.centerLeft,
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
                        child: Text(
  '${(item.inspectionPercentage * 100).toStringAsFixed(1)}%',
  style: const TextStyle(
    fontSize: 14,
    color: Colors.black, // Darker text
    fontWeight: FontWeight.w500, // Slightly bolder
  ),
),
                      ),
                    ],
                  )).toList(),
                ),
                // Scrollable middle section
                Expanded(
                  child: SingleChildScrollView(
                    controller: _horizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      children: filteredLineItems.map((item) => Row(
                        children: List.generate(
                          numberOfDraws,
                          (drawIndex) => _buildDrawCell(item, drawIndex + 1),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
                // Fixed right columns
                Column(
                  children: filteredLineItems.map((item) => Container(
                    width: 240, // 120 * 2 for Total Drawn and Budget
                    child: Row(
                      children: [
                        _buildTotalDrawnCell(item),
                        _buildBudgetCell(item),
                      ],
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
Widget _buildFixedRightHeaders() {
  return Container(
    decoration: BoxDecoration(
      border: Border(left: BorderSide(color: Colors.grey[300]!)),
    ),
    child: Row(
      children: [
        Container(
          width: 120,
          alignment: Alignment.center,
          child: const Text(
            'Total Drawn',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          width: 120,
          alignment: Alignment.center,
          child: const Text(
            'Budget',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    ),
  );
}
  // Update this method in your code

Widget _buildDrawCell(LoanLineItem item, int drawNumber) {
  double? amount = _getDrawAmount(item, drawNumber);
  bool wouldExceedBudget = _wouldExceedBudget(item, drawNumber, amount);

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
        // Left arrow button
        if (drawNumber > 1)
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 16),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            onPressed: () => _moveDrawAmount(item, drawNumber, 'left'),
          ),

        // Draw amount and warning
        Expanded(
          child: GestureDetector(
            onTap: () => _showDrawEditDialog(item, drawNumber),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  amount != null ? '\$${amount.toStringAsFixed(2)}' : '-',
                  style: TextStyle(
                    fontSize: 14,
                    color: wouldExceedBudget ? Colors.red : const Color.fromARGB(120, 39, 133, 5),
                    decoration: amount != null ? TextDecoration.underline : null,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                if (wouldExceedBudget) ...[
                  const SizedBox(width: 4),
                  Tooltip(
                    message: 'This draw would exceed the budget',
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Right arrow button
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

// Add this method to handle moving draw amounts
void _moveDrawAmount(LoanLineItem item, int drawNumber, String direction) {
  setState(() {
    if (direction == 'left' && drawNumber > 1) {
      // Move amount left
      double? tempAmount = _getDrawAmount(item, drawNumber - 1);
      String tempStatus = _getDrawStatus(item, drawNumber - 1);
      
      _setDrawAmount(item, drawNumber - 1, _getDrawAmount(item, drawNumber));
      _setDrawStatus(item, drawNumber - 1, _getDrawStatus(item, drawNumber));
      
      _setDrawAmount(item, drawNumber, tempAmount);
      _setDrawStatus(item, drawNumber, tempStatus);
      
    } else if (direction == 'right' && drawNumber < numberOfDraws) {
      // Move amount right
      double? tempAmount = _getDrawAmount(item, drawNumber + 1);
      String tempStatus = _getDrawStatus(item, drawNumber + 1);
      
      _setDrawAmount(item, drawNumber + 1, _getDrawAmount(item, drawNumber));
      _setDrawStatus(item, drawNumber + 1, _getDrawStatus(item, drawNumber));
      
      _setDrawAmount(item, drawNumber, tempAmount);
      _setDrawStatus(item, drawNumber, tempStatus);
    }
  });
}

// Helper method to get draw status
String _getDrawStatus(LoanLineItem item, int drawNumber) {
  switch (drawNumber) {
    case 1:
      return item.draw1Status ?? 'pending';
    case 2:
      return item.draw2Status ?? 'pending';
    case 3:
      return item.draw3Status ?? 'pending';
    case 4:
      return item.draw4Status ?? 'pending';
    // Additional cases can be added as needed
    default:
      return 'pending';
  }
}

// Helper method to set draw status
void _setDrawStatus(LoanLineItem item, int drawNumber, String status) {
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
    case 4:
      item.draw4Status = status;
      break;
    // Additional cases can be added as needed
  }
}
// Helper method to set draw amount
void _setDrawAmount(LoanLineItem item, int drawNumber, double? amount) {
  switch (drawNumber) {
    case 1:
      item.draw1 = amount;
      break;
    case 2:
      item.draw2 = amount;
      break;
    case 3:
      item.draw3 = amount;
      break;
    case 4:
      item.draw4 = amount;
      break;
    // Additional cases can be added as needed
  }
}
Widget _buildTotalDrawnCell(LoanLineItem item) {
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

Widget _buildBudgetCell(LoanLineItem item) {
  return Container(
    width: 120,
    height: 50,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      border: Border(
        left: BorderSide(color: Colors.grey[200]!),
      ),
    ),
    child: Text(
      '\$${item.budget.toStringAsFixed(2)}',
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black, // Darker text
        fontWeight: FontWeight.w500, // Slightly bolder
      ),
    ),
  );
}


  
  Widget _buildDrawStatusControls(int drawNumber) {
    return Container(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            iconSize: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: Colors.green,
            onPressed: () => _approveVerticalDraw(drawNumber),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(drawStatuses[drawNumber] ?? 'pending')
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              (drawStatuses[drawNumber] ?? 'PENDING').toUpperCase(),
              style: TextStyle(
                color: _getStatusColor(drawStatuses[drawNumber] ?? 'pending'),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cancel_outlined),
            iconSize: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: Colors.red,
            onPressed: () => _declineVerticalDraw(drawNumber),
          ),
        ],
      ),
    );
  }
  Widget _buildSeparator() {
    return Container(
      width: 2,
      color: Colors.grey[300],
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
  Widget _buildFixedRightColumns() {
    return SizedBox(
      width: 240, // 120 + 120
      child: ListView.builder(
        itemCount: filteredLineItems.length,
        itemBuilder: (context, index) {
          final item = filteredLineItems[index];
          return SizedBox(
            height: 50,
            child: Row(
              children: [
                Container(
                  width: 120,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '\$${item.totalDrawn.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: item.totalDrawn > item.budget
                              ? Colors.red
                              : Colors.black87,
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
                ),
                Container(
                  width: 120,
                  alignment: Alignment.center,
                  child: Text('\$${item.budget.toStringAsFixed(2)}'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _approveVerticalDraw(int drawNumber) {
    setState(() {
      drawStatuses[drawNumber] = 'approved';
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
      drawStatuses[drawNumber] = 'declined';
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

  double? _getDrawAmount(LoanLineItem item, int drawNumber) {
  switch (drawNumber) {
    case 1:
      return item.draw1;
    case 2:
      return item.draw2;
    case 3:
      return item.draw3;
    case 4:
      return item.draw4;
    // Additional cases can be added as needed
    default:
      return null;
  }
}

  bool _wouldExceedBudget(LoanLineItem item, int drawNumber, double? amount) {
    if (amount == null) return false;
    double totalWithoutThisDraw = item.totalDrawn - (amount ?? 0);
    return (totalWithoutThisDraw + amount) > item.budget;
  }

  Color _getStatusColor(String status) {
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

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }
}