import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:html' as html;
import 'package:collection/collection.dart';

final supabase = Supabase.instance.client;

enum DownloadStatus { inProgress, completed, failed }

class DownloadProgress {
  final DownloadStatus status;
  final String message;
  final double? progress;

  DownloadProgress({
    required this.status,
    required this.message,
    this.progress,
  });
}

final List<String> builderFileCategories = [
  'Construction Photos',
  'Progress Reports',
  'Material Receipts',
  'Inspection Reports',
  'Permits',
  'Change Orders',
  'Safety Reports',
  'Quality Control Documents',
  'Other'
];

class LoanLineItem {
  String lineItemName;
  double inspectionPercentage;
  double budget;
  double? draw1;
  double? draw2;
  double? draw3;
  double? draw4;
  String draw1Status;
  String draw2Status;
  String draw3Status;
  String draw4Status;

  LoanLineItem({
    required this.lineItemName,
    required this.inspectionPercentage,
    required this.budget,
    this.draw1,
    this.draw2,
    this.draw3,
    this.draw4,
    this.draw1Status = 'pending',
    this.draw2Status = 'pending',
    this.draw3Status = 'pending',
    this.draw4Status = 'pending',
  });

  double get totalDrawn {
    return (draw1 ?? 0) + (draw2 ?? 0) + (draw3 ?? 0) + (draw4 ?? 0);
  }
}

// Add after imports, before LoanLineItem class
class DocumentRequirement {
  final String category;
  final bool isRequired;
  final IconData icon;
  final Color color;

  DocumentRequirement({
    required this.category,
    this.isRequired = false,
    required this.icon,
    required this.color,
  });
}

class LenderLoanScreen extends StatefulWidget {
  final String loanId;

  const LenderLoanScreen({super.key, required this.loanId});

  @override
  State<LenderLoanScreen> createState() => _LenderLoanScreenState();
}

class _LenderLoanScreenState extends State<LenderLoanScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();

  late String _selectedCategory;

  // Add near the top of _LoanDashboardScreenState, where other variables are defined
  List<DocumentRequirement> documentRequirements = [
    DocumentRequirement(
      category: 'Construction Photos',
      isRequired: false,
      icon: Icons.photo_library,
      color: Color(0xFF6500E9),
    ),
    DocumentRequirement(
      category: 'Draw Documentation',
      isRequired: false,
      icon: Icons.description,
      color: Color(0xFF6500E9),
    ),
    DocumentRequirement(
      category: 'Material Receipts',
      isRequired: false,
      icon: Icons.receipt,
      color: Color(0xFF6500E9),
    ),
    DocumentRequirement(
      category: 'Inspection Reports',
      isRequired: false,
      icon: Icons.fact_check,
      color: Color(0xFF6500E9),
    ),
    DocumentRequirement(
      category: 'Permits',
      isRequired: false,
      icon: Icons.card_membership,
      color: Color(0xFF6500E9),
    ),
    DocumentRequirement(
      category: 'Other',
      isRequired: false,
      icon: Icons.folder,
      color: Color(0xFF6500E9),
    ),
  ];
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
      lineItemName: 'Default Value: Foundation Work',
      inspectionPercentage: 0.3,
      draw1: 0,
      draw1Status: 'pending',
      draw2: 25000,
      draw2Status: 'pending',
      budget: 153000,
    ),
    LoanLineItem(
      lineItemName: 'Default Value: Framing',
      inspectionPercentage: 0.34,
      draw1: 0,
      draw1Status: 'pending',
      budget: 153000,
    ),
    LoanLineItem(
      lineItemName: 'Default Value: Electrical',
      inspectionPercentage: .55,
      draw1: 0,
      draw1Status: 'pending',
      budget: 111000,
    ),
    LoanLineItem(
      lineItemName: 'Default Value: Plumbing',
      inspectionPercentage: .13,
      draw1: 0,
      draw2: 10000,
      draw1Status: 'pending',
      draw2Status: 'pending',
      budget: 153000,
    ),
    LoanLineItem(
      lineItemName: 'Default Value: HVAC Installation',
      inspectionPercentage: 0,
      draw1: 0,
      draw1Status: 'pending',
      budget: 153000,
    ),
    LoanLineItem(
      lineItemName: 'Default Value: Roofing',
      inspectionPercentage: .4,
      draw1: 0,
      draw1Status: 'pending',
      budget: 153000,
    ),
    LoanLineItem(
      lineItemName: 'Default Value: Interior Finishing',
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
    _selectedCategory = documentRequirements[0].category;
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
          (request) => request.lineItemName.toLowerCase().contains(
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
            headers: [
              'Line Item',
              'INSP',
              'Draw 1',
              'Draw 2',
              'Draw 3',
              'Total Drawn',
              'Budget'
            ],
            data: _loanLineItems
                .map((item) => [
                      item.lineItemName,
                      '${(item.inspectionPercentage * 100).toStringAsFixed(1)}%',
                      item.draw1 != null
                          ? '\$${item.draw1!.toStringAsFixed(2)}'
                          : '-',
                      item.draw2 != null
                          ? '\$${item.draw2!.toStringAsFixed(2)}'
                          : '-',
                      item.draw3 != null
                          ? '\$${item.draw3!.toStringAsFixed(2)}'
                          : '-',
                      '\$${item.totalDrawn.toStringAsFixed(2)}',
                      '\$${item.budget.toStringAsFixed(2)}',
                    ])
                .toList(),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${companyName.replaceAll(' ', '_')}_loan_details.pdf',
    );
  }

  // Add this widget to show the file list
  Widget _buildFileViewer() {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.folder_outlined,
                  size: 20,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Builder Documents',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                  ),
                ),
                const Spacer(),
                _buildFileFilterButton(),
              ],
            ),
          ),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: supabase
                .from('project_documents')
                .stream(primaryKey: ['id'])
                .eq('loan_id', widget.loanId)
                .order('uploaded_at', ascending: false),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final files = snapshot.data!;
              if (files.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No builder documents uploaded yet'),
                );
              }

              // Group files by category
              final filesByCategory = groupBy(
                  files,
                  (Map<String, dynamic> file) =>
                      file['file_category'] as String);

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filesByCategory.length,
                itemBuilder: (context, index) {
                  final category = filesByCategory.keys.elementAt(index);
                  final categoryFiles = filesByCategory[category]!;

                  return ExpansionTile(
                    leading: Icon(_getCategoryIcon(category),
                        color: _getCategoryColor(category)),
                    title: Row(
                      children: [
                        Text(
                          category,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6500E9).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${categoryFiles.length}',
                            style: const TextStyle(
                              color: Color(0xFF6500E9),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    children: categoryFiles
                        .map((file) => _buildFileListItem(file))
                        .toList(),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFileFilterButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.filter_list, size: 20),
      onSelected: (String filter) {
        // Implement filtering logic
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'all',
          child: Text('All Documents'),
        ),
        ...documentRequirements.map((req) => PopupMenuItem<String>(
              value: req.category.toLowerCase(),
              child: Text(req.category),
            )),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'construction photos':
        return Icons.photo_library;
      case 'progress reports':
        return Icons.assignment;
      case 'material receipts':
        return Icons.receipt;
      case 'inspection reports':
        return Icons.fact_check;
      case 'permits':
        return Icons.card_membership;
      case 'change orders':
        return Icons.change_circle;
      case 'safety reports':
        return Icons.health_and_safety;
      case 'quality control documents':
        return Icons.verified;
      default:
        return Icons.folder;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'construction photos':
        return Colors.blue;
      case 'progress reports':
        return Colors.green;
      case 'material receipts':
        return Colors.orange;
      case 'inspection reports':
        return Colors.purple;
      case 'permits':
        return Colors.red;
      case 'change orders':
        return Colors.teal;
      case 'safety reports':
        return Colors.amber;
      case 'quality control documents':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  Widget _buildFileListItem(Map<String, dynamic> file) {
    final fileName = file['file_name'] as String;
    final fileUrl = file['file_url'] as String;
    final uploadDate = DateTime.parse(file['uploaded_at']);
    final fileStatus = file['file_status'] as String;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        fileName,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        'Uploaded ${_formatDate(uploadDate)}',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusBadge(fileStatus),
          IconButton(
            icon: const Icon(Icons.download),
            iconSize: 20,
            color: Colors.grey[600],
            onPressed: () => _downloadFile(fileUrl, fileName),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadFile(String fileUrl, String fileName) async {
    final downloadProgress = ValueNotifier<DownloadProgress?>(null);

    try {
      // 1. Show initial progress
      downloadProgress.value = DownloadProgress(
          status: DownloadStatus.inProgress,
          message: 'Starting download...',
          progress: 0);

      // 2. Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ValueListenableBuilder<DownloadProgress?>(
          valueListenable: downloadProgress,
          builder: (context, progress, _) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (progress?.status == DownloadStatus.inProgress) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(progress?.message ?? 'Downloading...'),
                  ] else if (progress?.status == DownloadStatus.failed) ...[
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      progress?.message ?? 'Download failed',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ] else if (progress?.status == DownloadStatus.completed) ...[
                    const Icon(Icons.check_circle_outline,
                        color: Colors.green, size: 48),
                    const SizedBox(height: 16),
                    const Text('Download completed successfully'),
                  ]
                ],
              ),
              actions: [
                if (progress?.status != DownloadStatus.inProgress)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
              ],
            );
          },
        ),
      );

      // 3. Get file path and update progress
      final filePath = fileUrl.split('/').last;
      downloadProgress.value = DownloadProgress(
          status: DownloadStatus.inProgress,
          message: 'Downloading $fileName...',
          progress: 0.2);

      // 4. Download file
      final response =
          await supabase.storage.from('project_documents').download(filePath);

      downloadProgress.value = DownloadProgress(
          status: DownloadStatus.inProgress,
          message: 'Processing file...',
          progress: 0.8);

      // 5. Process and trigger download
      final blob = html.Blob([response]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement()
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body!.children.add(anchor);
      anchor.click();

      // 6. Cleanup
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      // 7. Show success and close
      downloadProgress.value = DownloadProgress(
          status: DownloadStatus.completed, message: 'Download completed');
      await Future.delayed(const Duration(seconds: 1));
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error downloading file: $e');

      // 8. Handle different error types
      String errorMessage = 'An error occurred while downloading the file.';
      if (e is StorageException) {
        switch (e.statusCode) {
          case 404:
            errorMessage =
                'The file could not be found. It may have been deleted or moved.';
            break;
          case 403:
            errorMessage = 'You don\'t have permission to download this file.';
            break;
          case 500:
            errorMessage = 'A server error occurred. Please try again later.';
            break;
          default:
            errorMessage = 'Storage error: ${e.message}';
        }
      }

      // 9. Show error state and snackbar
      downloadProgress.value = DownloadProgress(
          status: DownloadStatus.failed, message: errorMessage);

      Future.delayed(const Duration(seconds: 2)).then((_) {
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Dismiss',
                onPressed: () {},
                textColor: Colors.white,
              ),
            ),
          );
        }
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
          'No line items found for loan ID: ${widget.loanId}.\nUsing default values.',
        );
      }
      setState(() {
        _loanLineItems = response
            .map(
              (entity) => LoanLineItem(
                lineItemName: entity['category_name'] ?? "-",
                inspectionPercentage: entity['inspection_percentage'] ?? 0,
                draw1: entity['draw1_amount'] ?? 0.0,
                draw2: entity['draw2_amount'] ?? 0.0,
                draw3: entity['draw3_amount'] ?? 0.0,
                draw4: entity['draw4_amount'] ?? 0.0,
                draw1Status: entity['draw1_status'] ?? 'pending',
                draw2Status: entity['draw2_status'] ?? 'pending',
                draw3Status: entity['draw3_status'] ?? 'pending',
                draw4Status: entity['draw4_status'] ?? 'pending',
                budget: entity['budgeted_amount'] ?? 0.0,
              ),
            )
            .toList();
      });
    } catch (e) {
      print('Error fetching line items: $e');
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String displayText;

    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        displayText = 'Approved';
        break;
      case 'rejected':
        color = Colors.red;
        displayText = 'Rejected';
        break;
      case 'pending':
        color = Colors.orange;
        displayText = 'Pending';
        break;
      default:
        color = Colors.grey;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
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
          const SizedBox(height: 16),
          _buildUploadSection(),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.folder_outlined,
                        size: 20,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Project Files',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildFileList(),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

// Add this method to handle file uploads
  Future<void> _handleFileUpload(
      List<PlatformFile> files, String category) async {
    for (final file in files) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Uploading ${file.name}...'),
            duration: const Duration(seconds: 1),
          ),
        );

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileExtension = path.extension(file.name);
        final fileName = '${widget.loanId}/${timestamp}_${file.name}';

        if (file.bytes != null) {
          await supabase.storage.from('project_documents').uploadBinary(
                fileName,
                file.bytes!,
                fileOptions: FileOptions(
                  contentType:
                      file.bytes != null ? 'application/octet-stream' : null,
                ),
              );

          final fileUrl =
              supabase.storage.from('project_documents').getPublicUrl(fileName);

          await supabase.from('project_documents').insert({
            'loan_id': widget.loanId,
            'file_url': fileUrl,
            'file_name': file.name,
            'uploaded_by': supabase.auth.currentUser!.id,
            'file_type': fileExtension.replaceAll('.', ''),
            'file_status': 'active',
            'file_category': category // Add category here
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

  final List<String> fileCategories = [
    'Draw Documentation',
    'Inspection Reports',
    'Permits & Licenses',
    'Contracts',
    'Insurance Documents',
    'Construction Photos',
    'Invoices',
    'W9 Forms', // Added W9 category
    'Other'
  ];

// Special handling for W9 files
  bool isW9FilePresent(List<Map<String, dynamic>> files) {
    return files.any((file) =>
        file['file_category'] == 'W9 Forms' && file['file_status'] == 'active');
  }

  Widget _buildW9Warning() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'W9 form required',
              style: TextStyle(
                color: Colors.orange[900],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('project_documents')
          .stream(primaryKey: ['id'])
          .eq('loan_id', widget.loanId)
          .order('uploaded_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(
            color: Color(0xFF6500E9),
          ));
        }

        final files = snapshot.data!;
        final filesByCategory =
            files.groupListsBy((file) => file['file_category'] ?? 'Other');

        if (files.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No files uploaded yet'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Required documents warnings
            ...documentRequirements.where((req) => req.isRequired).map((req) {
              final hasFiles = filesByCategory.containsKey(req.category);
              if (!hasFiles) {
                return Container(
                  // New (correct) code:
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber,
                          size: 16, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Text(
                        '${req.category} required',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

            // File categories
            ...filesByCategory.entries.map((entry) {
              final requirement = documentRequirements.firstWhere(
                (req) => req.category == entry.key,
                orElse: () => DocumentRequirement(
                  category: 'Other',
                  icon: Icons.folder,
                  color: const Color(0xFF6500E9),
                ),
              );

              return ExpansionTile(
                leading: Icon(requirement.icon, color: requirement.color),
                title: Row(
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6500E9).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${entry.value.length}',
                        style: const TextStyle(
                          color: Color(0xFF6500E9),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (requirement.isRequired)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green[600],
                        ),
                      ),
                  ],
                ),
                children: entry.value
                    .map((file) => _buildFileListItem(file))
                    .toList(),
              );
            }),
          ],
        );
      },
    );
  }

  void _showRequirementsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Document Requirements'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: documentRequirements
                .map(
                  (req) => CheckboxListTile(
                    title: Row(
                      children: [
                        Icon(req.icon, size: 20, color: req.color),
                        const SizedBox(width: 8),
                        Text(req.category),
                      ],
                    ),
                    value: req.isRequired,
                    activeColor: const Color(0xFF6500E9),
                    onChanged: (value) {
                      setState(() {
                        final index = documentRequirements.indexOf(req);
                        documentRequirements[index] = DocumentRequirement(
                          category: req.category,
                          isRequired: value ?? false,
                          icon: req.icon,
                          color: req.color,
                        );
                      });
                      Navigator.pop(context);
                    },
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory, // Use the state variable here
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                items: documentRequirements.map((req) {
                  return DropdownMenuItem(
                    value: req.category,
                    child: Row(
                      children: [
                        Icon(req.icon, size: 18, color: req.color),
                        const SizedBox(width: 12),
                        Text(
                          req.category,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue; // Update the state variable
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Upload Box
          InkWell(
            onTap: () async {
              final result = await FilePicker.platform.pickFiles(
                allowMultiple: true,
                type: FileType.custom,
                allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
                withData: true,
              );
              if (result != null) {
                await _handleFileUpload(result.files,
                    _selectedCategory); // Use the state variable here
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF6500E9).withOpacity(0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF6500E9).withOpacity(0.02),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.cloud_upload_outlined,
                    size: 28,
                    color: Color(0xFF6500E9),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      children: const [
                        TextSpan(text: 'Drop files here or '),
                        TextSpan(
                          text: 'browse',
                          style: TextStyle(
                            color: Color(0xFF6500E9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PDF, JPG, PNG, DOC up to 10MB',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
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
          .eq('category_name', item.lineItemName);

      print(
          'Successfully updated draw $drawNumber for ${item.lineItemName} to $amount');
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
                    children: filteredLineItems
                        .map((item) => Row(
                              children: [
                                Container(
                                  width: 200,
                                  height: 50,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    item.lineItemName,
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
                                      fontWeight:
                                          FontWeight.w500, // Slightly bolder
                                    ),
                                  ),
                                ),
                              ],
                            ))
                        .toList(),
                  ),
                  // Scrollable middle section
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        children: filteredLineItems
                            .map((item) => Row(
                                  children: List.generate(
                                    numberOfDraws,
                                    (drawIndex) =>
                                        _buildDrawCell(item, drawIndex + 1),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  // Fixed right columns
                  Column(
                    children: filteredLineItems
                        .map((item) => Container(
                              width: 240, // 120 * 2 for Total Drawn and Budget
                              child: Row(
                                children: [
                                  _buildTotalDrawnCell(item),
                                  _buildBudgetCell(item),
                                ],
                              ),
                            ))
                        .toList(),
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
                      color: wouldExceedBudget
                          ? Colors.red
                          : const Color.fromARGB(120, 39, 133, 5),
                      decoration:
                          amount != null ? TextDecoration.underline : null,
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
