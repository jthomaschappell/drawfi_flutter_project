import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// 1.15.25 Not used in the UI right now
/// ------------ IGNORE THESE FOR NOW 1.15.25 -----------------
enum FileStatus {
  pending,
  uploaded,
  verified,
  rejected,
}

class FileDocument {
  final String id;
  final String category;
  final String fileName;
  final String fileUrl;
  final FileStatus status;
  final DateTime uploadedAt;
  final String? note;

  FileDocument({
    required this.id,
    required this.category,
    required this.fileName,
    required this.fileUrl,
    this.status = FileStatus.pending,
    required this.uploadedAt,
    this.note,
  });
}

/// Is this class ACTUALLY used?
class LenderReview {
  final String drawId;
  final String status;
  final String? note;
  final DateTime timestamp;
  final List<FileDocument>? reviewedDocuments;

  LenderReview({
    required this.drawId,
    required this.status,
    this.note,
    required this.timestamp,
    this.reviewedDocuments,
  });
}

/// ------------ IGNORE THESE FOR NOW 1.15.25 -----------------

class ContractorScreenLoanLineItem {
  final String categoryId;
  final String lineItemName;
  double inspectionPercentage;
  double draw1Amount;
  double draw2Amount;
  double draw3Amount;
  double draw4Amount;
  String draw1Status;
  String draw2Status;
  String draw3Status;
  String draw4Status;
  double budget;
  String? lenderNote;
  DateTime? reviewedAt;

  ContractorScreenLoanLineItem({
    required this.categoryId,
    required this.lineItemName,
    required this.inspectionPercentage,
    required this.budget,
    this.lenderNote,
    this.reviewedAt,
  })  : draw1Amount = 0,
        draw2Amount = 0,
        draw3Amount = 0,
        draw4Amount = 0,
        draw1Status = "pending",
        draw2Status = "pending",
        draw3Status = "pending",
        draw4Status = "pending";

  double get totalDrawn {
    return draw1Amount + draw2Amount + draw3Amount + draw4Amount;
  }

  @override
  String toString() {
    return '''ContractorScreenLoanLineItem(
      categoryId: $categoryId,
      lineItemName: $lineItemName,
      inspectionPercentage: $inspectionPercentage,
      budget: $budget,
      totalDrawn: $totalDrawn,
      draws: [
        Draw 1: $draw1Amount ($draw1Status),
        Draw 2: $draw2Amount ($draw2Status),
        Draw 3: $draw3Amount ($draw3Status),
        Draw 4: $draw4Amount ($draw4Status)
      ],
      lenderNote: $lenderNote,
      reviewedAt: $reviewedAt
    )''';
  }
}

class ContractorLoanScreen extends StatefulWidget {
  final String loanId;

  final bool isLender; // TODO: Is this necessary.

  const ContractorLoanScreen({
    super.key,
    required this.loanId,
    this.isLender = false,
  });

  @override
  State<ContractorLoanScreen> createState() => _ContractorLoanScreenState();
}

class _ContractorLoanScreenState extends State<ContractorLoanScreen> {
  // Are these values used? 1.15.25.
  String _searchQuery = '';
  Timer? _refreshTimer;
  final List<LenderReview> _lenderReviews = [];
  final ScrollController _horizontalScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, TextEditingController> _controllers = {};

  /// Default values for the name display on the contractor screen.
  String companyName = "Loading...";
  String contractorName = "Loading...";
  String contractorEmail = "Loading...";
  String contractorPhone = "Loading...";
  bool isPending = false;

  /// switches to pending vs submitted.

  int numberOfDraws = 4;
  final supabase = Supabase.instance.client;

  String draw1StatusUI = "pending";
  String draw2StatusUI = "pending";
  String draw3StatusUI = "pending";
  String draw4StatusUI = "pending";

  // FILE STUFF:
  /// Hardcoded.
  final documents = [
    FileDocument(
      id: '1',
      category: 'W9 Forms',
      fileName: 'foundation_w9.pdf',
      fileUrl: 'foundation_w9.pdf',
      status: FileStatus.verified,
      uploadedAt: DateTime.now(),
    ),
  ];
  static const List<String> fileCategories = [
    'W9 Forms',
    'Construction Photos',
    'Building Permits',
    'Insurance Documents',
    'Contract Documents',
    'Inspection Reports',
    'Other Documents'
  ];

  bool hasRequiredDocuments() {
    return documents.any((doc) =>
            doc.category == 'W9 Forms' && doc.status == FileStatus.verified) &&
        documents.any((doc) =>
            doc.category == 'Building Permits' &&
            doc.status == FileStatus.verified);
  }
  Future<void> _saveDrawAmount(ContractorScreenLoanLineItem item, int drawNumber, double amount) async {
  try {
    print('Saving amount $amount for draw $drawNumber on line item ${item.categoryId}');
    
    // First update line items table
    String amountColumn = 'draw${drawNumber}_amount';
    await supabase
      .from('construction_loan_line_items')
      .update({
        amountColumn: amount,
      })
      .eq('category_id', item.categoryId);

    print('Updated line items table');
    
    // Then update draws table
    final existingDraw = await supabase
      .from('construction_loan_draws')
      .select()
      .eq('category_id', item.categoryId)
      .eq('draw_number', drawNumber)
      .maybeSingle();

    if (existingDraw != null) {
      await supabase
        .from('construction_loan_draws')
        .update({
          'amount': amount,
          'status': 'pending'
        })
        .eq('draw_id', existingDraw['draw_id']);
        print('Updated existing draw');
    } else {
      await supabase
        .from('construction_loan_draws')
        .insert({
          'loan_id': widget.loanId,
          'category_id': item.categoryId,
          'draw_number': drawNumber,
          'amount': amount,
          'status': 'pending'
        });
        print('Inserted new draw');
    }
  } catch (e) {
    print('Error saving draw amount: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving draw amount: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
  Future<void> _downloadAsPdf() async {
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

          // Contractor information
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Contractor: $contractorName'),
              pw.Text('Phone: $contractorPhone'),
              pw.Text('Email: $contractorEmail'),
            ],
          ),
          pw.SizedBox(height: 20),

          // Summary statistics
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
                    'Total Amount: \$${_contractorScreenLoanLineItems.fold<double>(0.0, (sum, item) => sum + item.totalDrawn).toStringAsFixed(2)}',
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

          // Draw requests table
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
              ...List.generate(numberOfDraws, (i) => 'Draw ${i + 1}'),
              'Total Drawn',
              'Budget'
            ],
            data: _contractorScreenLoanLineItems
                .map((item) => [
                      item.lineItemName,
                      '${(item.inspectionPercentage * 100).toStringAsFixed(1)}%',
                      // Replace the old draws map access with individual draw amounts
                      '\$${item.draw1Amount.toStringAsFixed(2)}',
                      '\$${item.draw2Amount.toStringAsFixed(2)}',
                      '\$${item.draw3Amount.toStringAsFixed(2)}',
                      '\$${item.draw4Amount.toStringAsFixed(2)}',
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

  Future<void> _handleFileUpload(
      List<PlatformFile> files, String category) async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      for (final file in files) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Uploading ${file.name}...'),
            duration: const Duration(seconds: 1),
          ),
        );

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${widget.loanId}/$category/${timestamp}_${file.name}';

        if (file.bytes != null) {
          // Upload to Supabase storage
          await supabase.storage.from('project_documents').uploadBinary(
                fileName,
                file.bytes!,
                fileOptions: FileOptions(
                  contentType: 'application/octet-stream',
                ),
              );

          // Get public URL
          final fileUrl =
              supabase.storage.from('project_documents').getPublicUrl(fileName);

          // Insert into database with correct types
          await supabase.from('project_documents').insert({
            'loan_id': widget.loanId,
            'file_url': fileUrl,
            'file_name': file.name,
            'file_status': 'active',
            'file_category': category,
            'uploaded_by': currentUser.id, // This should be a UUID from auth
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildFileUploadSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      height: 300, // Fixed height to make it scrollable
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Upload Documents',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: fileCategories
                    .map((category) => InkWell(
                          onTap: () async {
                            final result = await FilePicker.platform.pickFiles(
                              allowMultiple: true,
                              type: FileType.custom,
                              allowedExtensions: [
                                'pdf',
                                'jpg',
                                'png',
                                'doc',
                                'docx'
                              ],
                            );
                            if (result != null) {
                              await _handleFileUpload(result.files, category);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade100),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getCategoryIcon(category),
                                  size: 20,
                                  color: const Color(0xFF6500E9),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    category,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ),
                                if (category == 'W9 Forms' ||
                                    category == 'Building Permits')
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF4E5),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: Colors.orange.shade200),
                                    ),
                                    child: Text(
                                      'Required',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.upload_file,
                                  size: 20,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<ContractorScreenLoanLineItem> _contractorScreenLoanLineItems = [
    ContractorScreenLoanLineItem(
      categoryId: '00000000-0000-0000-0000-000000000000',
      lineItemName: 'No Line Items Yet',
      inspectionPercentage: 0.0,
      budget: 0.0,
      // default values for draw1 amount, etc.
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    fetchLoanData();
    // I don't think this actually does anything -- Thomas -- 1.15.25.
    if (!widget.isLender) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _checkLenderUpdates();
      });
    }
  }

  Future<void> fetchLoanData() async {
    try {
      print("Starting data load for loan ID: ${widget.loanId}");
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

      // Fetch line items with their associated draws
      final lineItemsResponse =
          await supabase.from('construction_loan_line_items').select('''
        *,
        construction_loan_draws (
          draw_number,
          amount,
          status
        )
      ''').eq('loan_id', widget.loanId);

      setState(() {
        companyName = contractorResponse['company_name'] ?? "Unknown Company";
        contractorName =
            contractorResponse['full_name'] ?? "Unknown Contractor";
        contractorEmail = contractorResponse['email'] ?? "No Email";
        contractorPhone = contractorResponse['phone'] ?? "No Phone";

        if (lineItemsResponse.isEmpty) {
          // Reset status
          draw1StatusUI = "pending";
          draw2StatusUI = "pending";
          draw3StatusUI = "pending";
          draw4StatusUI = "pending";

          // Create a default line item if none exist
          _contractorScreenLoanLineItems = [
            ContractorScreenLoanLineItem(
              categoryId: '00000000-0000-0000-0000-000000000000',
              lineItemName: 'No Line Items Yet',
              inspectionPercentage: 0.0,
              budget: 0.0,
            ),
          ];
        } else {
  _contractorScreenLoanLineItems = lineItemsResponse.map<ContractorScreenLoanLineItem>((item) {
    var lineItem = ContractorScreenLoanLineItem(
      categoryId: item['category_id'] ?? '00000000-0000-0000-0000-000000000000',
      lineItemName: item['category_name'] ?? 'Unnamed Item',
      inspectionPercentage: item['inspection_percentage']?.toDouble() ?? 0.0,
      budget: item['budgeted_amount']?.toDouble() ?? 0.0,
    );

    // Set draw amounts from database
    lineItem.draw1Amount = item['draw1_amount']?.toDouble() ?? 0.0;
    lineItem.draw2Amount = item['draw2_amount']?.toDouble() ?? 0.0;
    lineItem.draw3Amount = item['draw3_amount']?.toDouble() ?? 0.0;
    lineItem.draw4Amount = item['draw4_amount']?.toDouble() ?? 0.0;

    // Set draw statuses
    lineItem.draw1Status = item['draw1_status'] ?? 'pending';
    lineItem.draw2Status = item['draw2_status'] ?? 'pending';
    lineItem.draw3Status = item['draw3_status'] ?? 'pending';
    lineItem.draw4Status = item['draw4_status'] ?? 'pending';

    return lineItem;
  }).toList();

          /// CLAUDE CHANGE HERE
          // Set UI status from first line item after creation
          draw1StatusUI = _contractorScreenLoanLineItems.first.draw1Status;
          draw2StatusUI = _contractorScreenLoanLineItems.first.draw2Status;
          draw3StatusUI = _contractorScreenLoanLineItems.first.draw3Status;
          draw4StatusUI = _contractorScreenLoanLineItems.first.draw4Status;
        }
      });

      print("Data load completed successfully");
      print("Company Name: $companyName");
      print(
          "Number of loan line items: ${_contractorScreenLoanLineItems.length}");
    } catch (e) {
      print('Error loading loan data: $e');
      // setState(() => _isLoading = false);  // Uncomment if _isLoading is defined
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

// Handles the controllers.
  void _initializeControllers() {
    for (var item in _contractorScreenLoanLineItems) {
      // Create controllers for each draw amount field
      _controllers['${item.lineItemName}_1'] =
          TextEditingController(text: item.draw1Amount.toString());
      _controllers['${item.lineItemName}_2'] =
          TextEditingController(text: item.draw2Amount.toString());
      _controllers['${item.lineItemName}_3'] =
          TextEditingController(text: item.draw3Amount.toString());
      _controllers['${item.lineItemName}_4'] =
          TextEditingController(text: item.draw4Amount.toString());
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'W9 Forms':
        return Icons.description;
      case 'Construction Photos':
        return Icons.photo_library;
      case 'Building Permits':
        return Icons.assignment;
      case 'Insurance Documents':
        return Icons.security;
      case 'Contract Documents':
        return Icons.handshake;
      case 'Inspection Reports':
        return Icons.fact_check;
      default:
        return Icons.folder;
    }
  }

  /// CLAUDE MADE A CHANGE HERE
  Future<void> _checkLenderUpdates() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      for (var review in _lenderReviews) {
        for (var request in _contractorScreenLoanLineItems) {
          int drawNumber = int.parse(review.drawId.split('_')[1]);
          // Update individual draw statuses instead of using map
          switch (drawNumber) {
            case 1:
              request.draw1Status = review.status;
              break;
            case 2:
              request.draw2Status = review.status;
              break;
            case 3:
              request.draw3Status = review.status;
              break;
            case 4:
              request.draw4Status = review.status;
              break;
          }
          request.lenderNote = review.note;
          request.reviewedAt = review.timestamp;
        }
      }
    });
  }

  /// CLAUDE MADE A CHANGE HERE
  void _reviewDraw(int drawNumber, String status, String? note) {
    setState(() {
      final review = LenderReview(
        drawId: 'draw_$drawNumber',
        status: status,
        note: note,
        timestamp: DateTime.now(),
      );
      _lenderReviews.add(review);

      for (var request in _contractorScreenLoanLineItems) {
        // Update individual draw status instead of using map
        switch (drawNumber) {
          case 1:
            request.draw1Status = status;
            break;
          case 2:
            request.draw2Status = status;
            break;
          case 3:
            request.draw3Status = status;
            break;
          case 4:
            request.draw4Status = status;
            break;
        }
        request.lenderNote = note;
        request.reviewedAt = review.timestamp;
      }
    });
  }

  Future<void> updateDrawContractorSide(
      String newStatus, int drawNumber) async {
    try {
      String capitalizedNewStatus = newStatus[0].toUpperCase();
      capitalizedNewStatus += newStatus.substring(1);
      String statusToUpdate = 'draw1_status';

      // Get all line items for this loan
      final lineItemsResponse = await supabase
          .from('construction_loan_line_items')
          .select()
          .eq('loan_id', widget.loanId);

      switch (drawNumber) {
        case 1:
          print("Changing draw1");
          statusToUpdate = "draw1_status";
          draw1StatusUI = newStatus;
          break;
        case 2:
          print("Changing draw2");
          draw2StatusUI = newStatus;
          statusToUpdate = "draw2_status";
          break;
        case 3:
          print("Changing draw3");
          draw3StatusUI = newStatus;
          statusToUpdate = "draw3_status";
          break;
        case 4:
          print("Changing draw4");
          draw4StatusUI = newStatus;
          statusToUpdate = "draw4_status";
          break;
      }

      // Update each line item's draw statuses to 'approved'
      for (var item in lineItemsResponse) {
        await supabase.from('construction_loan_line_items').update({
          statusToUpdate: newStatus,
        }).eq('category_id', item['category_id']);
      }

      // Refresh the data on the page
      // await fetchLoanData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Draw made "$capitalizedNewStatus"',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      setState(() {
        print("Now, after the function, isPending is $isPending");
        isPending = !isPending;
      });
    } catch (e) {
      print('Error approving draws: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error approving draws: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {}
    }
  }

  /// TODO:
  /// Does this button ever get called, or was it replaced by another implementation?

  void _submitDraw(int drawNumber) {
    // setState(() {
    // for (var lineItem in _contractorScreenLoanLineItems) {
    //   if (lineItem.draws[drawNumber] != null) {
    //     lineItem.drawStatuses[drawNumber] = "submitted";
    //   }
    // }
    // });

    /// TODO:
    /// drawNumber --> maps to draw1_status, draw2_status.
    ///
    ///
  }

  void _addNewDraw() {
    // Remove this method or modify based on requirements since we now have fixed draws
    // Cannot dynamically add new draws with the current structure
    print(
        "Warning: Adding new draws is not supported in the current implementation");

    // setState(() {
    //   numberOfDraws++;
    //   for (var request in _contractorScreenLoanLineItems) {
    //     request.draws[numberOfDraws] = null;
    //     request.drawStatuses[numberOfDraws] = "pending";

    //     final key = '${request.lineItemName}_$numberOfDraws';
    //     _controllers[key] = TextEditingController();
    //   }
    // });
  }

  List<ContractorScreenLoanLineItem> get filteredLineItems {
    if (_searchQuery.isEmpty) return _contractorScreenLoanLineItems;
    return _contractorScreenLoanLineItems
        .where(
          (request) => request.lineItemName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  double get totalDisbursed {
    double totalDrawn = _contractorScreenLoanLineItems.fold<double>(
        0.0, (sum, request) => sum + request.totalDrawn);
    double totalBudget = _contractorScreenLoanLineItems.fold<double>(
        0.0, (sum, request) => sum + request.budget);

    if (totalBudget == 0) return 0;
    return (totalDrawn / totalBudget) * 100;
  }

  double get projectCompletion {
    double weightedSum = 0;
    double totalBudget = 0;

    for (var item in _contractorScreenLoanLineItems) {
      weightedSum += (item.inspectionPercentage * item.budget);
      totalBudget += item.budget;
    }

    if (totalBudget == 0) return 0;
    return (weightedSum / totalBudget) * 100;
  }

  Future<void> _showReviewDialog(int drawNumber, String status) async {
    final TextEditingController noteController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(status == "approved" ? 'Approve Draw' : 'Decline Draw'),
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
              backgroundColor: status == "approved" ? Colors.green : Colors.red,
            ),
            // child: Text(status == "approved" ? 'Approve' : 'Decline'),
            child: Text("Way of Kings"),
          ),
        ],
      ),
    );
  }

  String _getButtonText(String status) {
    print("The get button text was called!");
    switch (status) {
      /// Some of these cases aren't consistent with the database...
      case "approved":
        return 'Approved';
      case "declined":
        return 'Declined';
      case "submitted":
        return 'Submitted';
      case "underReview":
        return 'Under Review';
      case "pending":
      default:
        return 'Submit';
    }
  }

  Color _getStatusColor(String status) {
    // This method is fine as is - no changes needed
    switch (status) {
      case "approved":
        return const Color(0xFF22C55E);
      case "declined":
        return const Color(0xFFEF4444);
      case "submitted":
        return const Color(0xFF6500E9);
      case "underReview":
        return const Color(0xFF6366F1);
      case "pending":
      default:
        return const Color(0xFFF97316);
    }
  }

  /// This sees if the line item totalDrawn exceeds the budget for that item.
  bool _lineItemExceedsBudget(ContractorScreenLoanLineItem item) {
    return (item.totalDrawn) > item.budget;
  }

  /// 1.15.25 Does this even do anything?
  /// CLAUDE MADE A CHANGE HERE
  void _moveDrawAmount(
      ContractorScreenLoanLineItem item, int drawNumber, String direction) {
    setState(() {
      if (direction == 'left' && drawNumber > 1) {
        // Moving left
        double tempAmount;
        String tempStatus;

        switch (drawNumber) {
          case 2:
            tempAmount = item.draw1Amount;
            tempStatus = item.draw1Status;
            item.draw1Amount = item.draw2Amount;
            item.draw1Status = item.draw2Status;
            item.draw2Amount = tempAmount;
            item.draw2Status = tempStatus;

            // Update controllers
            _controllers['${item.lineItemName}_1']?.text =
                item.draw1Amount.toString();
            _controllers['${item.lineItemName}_2']?.text =
                item.draw2Amount.toString();
            break;

          case 3:
            tempAmount = item.draw2Amount;
            tempStatus = item.draw2Status;
            item.draw2Amount = item.draw3Amount;
            item.draw2Status = item.draw3Status;
            item.draw3Amount = tempAmount;
            item.draw3Status = tempStatus;

            _controllers['${item.lineItemName}_2']?.text =
                item.draw2Amount.toString();
            _controllers['${item.lineItemName}_3']?.text =
                item.draw3Amount.toString();
            break;

          case 4:
            tempAmount = item.draw3Amount;
            tempStatus = item.draw3Status;
            item.draw3Amount = item.draw4Amount;
            item.draw3Status = item.draw4Status;
            item.draw4Amount = tempAmount;
            item.draw4Status = tempStatus;

            _controllers['${item.lineItemName}_3']?.text =
                item.draw3Amount.toString();
            _controllers['${item.lineItemName}_4']?.text =
                item.draw4Amount.toString();
            break;
        }
      } else if (direction == 'right' && drawNumber < numberOfDraws) {
        // Moving right
        double tempAmount;
        String tempStatus;

        switch (drawNumber) {
          case 1:
            tempAmount = item.draw2Amount;
            tempStatus = item.draw2Status;
            item.draw2Amount = item.draw1Amount;
            item.draw2Status = item.draw1Status;
            item.draw1Amount = tempAmount;
            item.draw1Status = tempStatus;

            _controllers['${item.lineItemName}_1']?.text =
                item.draw1Amount.toString();
            _controllers['${item.lineItemName}_2']?.text =
                item.draw2Amount.toString();
            break;

          case 2:
            tempAmount = item.draw3Amount;
            tempStatus = item.draw3Status;
            item.draw3Amount = item.draw2Amount;
            item.draw3Status = item.draw2Status;
            item.draw2Amount = tempAmount;
            item.draw2Status = tempStatus;

            _controllers['${item.lineItemName}_2']?.text =
                item.draw2Amount.toString();
            _controllers['${item.lineItemName}_3']?.text =
                item.draw3Amount.toString();
            break;

          case 3:
            tempAmount = item.draw4Amount;
            tempStatus = item.draw4Status;
            item.draw4Amount = item.draw3Amount;
            item.draw4Status = item.draw3Status;
            item.draw3Amount = tempAmount;
            item.draw3Status = tempStatus;

            _controllers['${item.lineItemName}_3']?.text =
                item.draw3Amount.toString();
            _controllers['${item.lineItemName}_4']?.text =
                item.draw4Amount.toString();
            break;
        }
      }
    });
  }

  /// Builds a cell widget for a specific draw in the loan line item table
  /// Each cell represents a draw amount that can be edited if its status is 'pending'
 Widget _buildDrawCell(ContractorScreenLoanLineItem item, int drawNumber) {
  final String key = '${item.lineItemName}_$drawNumber';
  String status;
  double amount;
  
  switch (drawNumber) {
    case 1:
      status = item.draw1Status;
      amount = item.draw1Amount;
      break;
    case 2:
      status = item.draw2Status;
      amount = item.draw2Amount;
      break;
    case 3:
      status = item.draw3Status;
      amount = item.draw3Amount;
      break;
    case 4:
      status = item.draw4Status;
      amount = item.draw4Amount;
      break;
    default:
      status = "pending";
      amount = 0;
  }
  
  bool isEditable = status == "pending";
  
  _controllers[key] ??= TextEditingController(text: amount > 0 ? amount.toString() : '');

  return Container(
    width: 120,
    height: 50,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      border: Border(
        left: BorderSide(color: Colors.grey[200]!),
        bottom: BorderSide(color: Colors.grey[200]!),
      ),
      color: status == "approved" ? Colors.green.withOpacity(0.1) :
             status == "declined" ? Colors.red.withOpacity(0.1) :
             Colors.white,
    ),
    child: TextField(
      controller: _controllers[key],
      textAlign: TextAlign.center,
      enabled: isEditable,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        border: InputBorder.none,
        fillColor: Colors.transparent,
        filled: true,
        hintText: '-',
        contentPadding: EdgeInsets.zero,
        prefixText: amount > 0 ? '\$' : '',
      ),
      style: TextStyle(
        fontSize: 14,
        color: status == "approved" ? Colors.green :
               status == "declined" ? Colors.red :
               Colors.black87,
        fontWeight: FontWeight.w500,
      ),
      onChanged: (value) {
  final newAmount = value.isEmpty ? 0.0 : double.tryParse(value) ?? 0.0;
  setState(() {
    switch (drawNumber) {
      case 1: item.draw1Amount = newAmount; break;
      case 2: item.draw2Amount = newAmount; break;
      case 3: item.draw3Amount = newAmount; break;
      case 4: item.draw4Amount = newAmount; break;
    }
  });
  _saveDrawAmount(item, drawNumber, newAmount);
},
    ),
  );
}
  Widget _buildTotalDrawnCell(ContractorScreenLoanLineItem item) {
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

  /// CLAUDE MADE A CHANGE HERE
  Widget _buildDrawStatusSection(int drawNumber) {
  String status;
  switch (drawNumber) {
    case 1: status = draw1StatusUI; break;
    case 2: status = draw2StatusUI; break;
    case 3: status = draw3StatusUI; break;
    case 4: status = draw4StatusUI; break;
    default: status = "pending";
  }

  Color statusColor = _getStatusColor(status);
  bool isPending = status == "pending";

  return Container(
    width: 120,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    decoration: BoxDecoration(
      border: Border(
        left: BorderSide(color: Colors.grey[200]!),
        top: BorderSide(color: Colors.grey[200]!),
      ),
      color: Colors.white,
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isPending ? Colors.grey[100] : statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPending ? Colors.grey[300]! : statusColor.withOpacity(0.2),
            ),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
              color: isPending ? Colors.grey[600] : statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ),
        if (isPending) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: () => updateDrawContractorSide("submitted", drawNumber),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF6500E9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6500E9).withOpacity(0.25),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Text(
                'Submit',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ],
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
                        ...filteredLineItems
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
                            ...filteredLineItems
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
          // Enhanced download button
          Container(
            margin: const EdgeInsets.only(right: 16),
            height: 40,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 95, 135, 93),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6500E9).withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _downloadAsPdf,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.file_download_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'PDF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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

          // Add the new file upload section here
          _buildFileUploadSection(),

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

  // Widget _buildThomasTestButton() {
  //   /// DONE:
  //   /// This should update draw #1 --
  //   /// -- on the screen,
  //   /// -- and in the database.
  //   ///
  //   /// DONE:
  //   /// Try changing it to draw #2 and see if it also updates draw #2 --
  //   /// -- on the screen,
  //   /// -- and in the database.
  //   ///
  //   /// DONE:
  //   /// Take this functionality to the actual button.
  //   ///
  //   final drawNumber = 2;
  //   final newStatus = (isPending) ? "pending" : "submitted";
  //   String capitalizedNewStatus = newStatus[0].toUpperCase();
  //   capitalizedNewStatus += newStatus.substring(1);
  //   return ElevatedButton(
  //     onPressed: () async {
  //       print("Before the function, isPending was $isPending");
  //       updateDraws(newStatus, drawNumber);
  //     },
  //     child: Text(
  //       "Make '$capitalizedNewStatus' Draw #$drawNumber on DB",
  //     ),
  //   );
  // }

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

                            /// Remove this when we are no longer testing.
                            // _buildThomasTestButton(),
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
