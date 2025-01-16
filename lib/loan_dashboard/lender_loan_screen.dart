import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:collection/collection.dart';

import 'package:path/path.dart' as path;

/// TODO:
/// See if doing 'flutter pub add collection'
/// is the right thing.

final supabase = Supabase.instance.client;

/// Do we use this? 1.15.25
enum DownloadStatus { inProgress, completed, failed }

/// Do we use this? 1.15.25
enum DrawStatus { pending, submitted, underReview, approved, declined }

class DownloadProgress {
  final DownloadStatus status;
  final String message;

  final double? progress;
  final String? error;

  DownloadProgress({
    required this.status,
    required this.message,
    this.progress,
    this.error,
  });
}

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

class LoanLineItem {
  String lineItem;
  double inspectionPercentage;
  double? draw1;
  double? draw2;
  double? draw3;
  double? draw4;
  String draw1Status;
  String draw2Status;
  String draw3Status;
  String draw4Status;
  double budget;

  LoanLineItem({
    required this.lineItem,
    required this.inspectionPercentage,
    this.draw1,
    this.draw2,
    this.draw3,
    this.draw4,
    this.draw1Status = "pending",
    this.draw2Status = "pending",
    this.draw3Status = "pending",
    this.draw4Status = "pending",
    required this.budget,
  });

  double get totalDrawn {
    return (draw1 ?? 0) + (draw2 ?? 0) + (draw3 ?? 0) + (draw4 ?? 0);
  }

  /// TODO:
  /// Modify those other functions and put them in here.
  ///
}

class LenderLoanScreen extends StatefulWidget {
  final String loanId;
  const LenderLoanScreen({super.key, required this.loanId});

  @override
  State<LenderLoanScreen> createState() => _LenderLoanScreenState();
}

class _LenderLoanScreenState extends State<LenderLoanScreen> {
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

  List<LoanLineItem> _loanLineItems = [
    LoanLineItem(
      lineItem: 'Default Value: Foundation Work',
      inspectionPercentage: 0.3,
      draw1: 0,
      draw2: 25000,
      draw1Status: "pending",
      draw2Status: "pending",
      budget: 153000,
    ),
    LoanLineItem(
      lineItem: 'Default Value: Framing',
      inspectionPercentage: 0.34,
      draw1: 0,
      draw1Status: "pending",
      budget: 153000,
    ),
    LoanLineItem(
      lineItem: 'Default Value: Electrical',
      inspectionPercentage: .55,
      draw1: 0,
      draw1Status: "pending",
      budget: 111000,
    ),
    LoanLineItem(
      lineItem: 'Default Value: Plumbing',
      inspectionPercentage: .13,
      draw1: 0,
      draw2: 10000,
      draw1Status: "pending",
      draw2Status: "pending",
      budget: 153000,
    ),
    LoanLineItem(
      lineItem: 'Default Value: HVAC Installation',
      inspectionPercentage: 0,
      draw1: 0,
      draw1Status: "pending",
      budget: 153000,
    ),
    LoanLineItem(
      lineItem: 'Default Value: Roofing',
      inspectionPercentage: .4,
      draw1: 0,
      draw1Status: "pending",
      budget: 153000,
    ),
    LoanLineItem(
      lineItem: 'Default Value: Interior Finishing',
      inspectionPercentage: .45,
      draw1: 0,
      draw1Status: "pending",
      budget: 153000,
    ),
  ];

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

  String companyName = "Loading...";
  String contractorName = "Loading...";
  String contractorEmail = "Loading...";
  String contractorPhone = "Loading...";
  int numberOfDraws = 4;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  late String _selectedCategory;

  /// -- HELPER FUNCTIONS ----
  ///
  ///

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

  /// ---- SEARCH LINE ITEMS FUNCTIONALITY ----
  String _searchQuery = '';
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

  /// TODO:
  /// Can the below couple of functions be in their own helper
  /// functions dart file, OR do they reference
  /// state variables here in LenderLoanScreen?

  /// ---- FILE FUNCTIONS ( I don't know if these are necessary ) ----
  ///

  Future<bool> _checkFileExists(String filePath) async {
    return false;
  }

  Future<void> _downloadFile(String fileUrl, String fileName) async {}

  Future<void> _openFile(String fileUrl, String fileName) async {}

  Future<void> _downloadMultipleFiles(List<Map<String, dynamic>> files) async {}

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

  Future<void> cleanupOrphanedFileReferences() async {}

  Future<void> _shareLoanDashboard() async {}

  Map<int, DrawStatus> drawStatuses = {};

  @override
  void initState() {
    super.initState();

    _selectedCategory = documentRequirements[0].category;

    // sets as pending all of the objects in the drawStatuses map.
    // I don't know if we actually use the drawStatus map.
    for (int i = 1; i <= numberOfDraws; i++) {
      drawStatuses[i] = DrawStatus.pending;
    }

    _fetchContractorDetails();
    fetchLoanLineItems();

    // Is this at all necessary?
    // // Add automatic cleanup of orphaned file references
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cleanupOrphanedFileReferences();
    });
  }

  /// calls the DB and puts the values into the
  /// state values contractorName, etc.
  Future<void> _fetchContractorDetails() async {
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

  Future<void> fetchLoanLineItems() async {
    try {
      final response = await supabase
          .from('construction_loan_line_items')
          .select()
          .eq('loan_id', widget.loanId);

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
                  draw1: entity['draw1_amount']?.toDouble(),
                  draw2: entity['draw2_amount']?.toDouble(),
                  draw3: entity['draw3_amount']?.toDouble(),
                  draw1Status: (entity['draw1_status']).toString(),
                  draw2Status: (entity['draw2_status']).toString(),
                  draw3Status: entity['draw3_status'].toString(),
                  budget: entity['budgeted_amount']?.toDouble() ?? 0.0,
                ),
              )
              .toList();
        },
      );
    } catch (e) {
      print('Error fetching line items: $e');
    }
  }

  /// ---- BUILD FUNCTIONS ----
  ///

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

  Widget _buildDataTable() {
    return const Placeholder(); 
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
                  '''<svg width="32" height="32" viewBox="0 0 1531 1531" fill="none" xmlns=http://www.w3.org/2000/svg
SVG namespace - World Wide Web Consortium (W3C)
http://www.w3.org/2000/svg is an XML namespace, first defined in the Scalable Vector Graphics (SVG) 1.0 Specification and subsequently added to by SVG 1.1, SVG 1.2 ...
www.w3.org
>

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
                leading: const Icon(
                  Icons.notifications_active,
                ),
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

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Change to min

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
                  _buildFileList(),
                ],
              ),
            ),

            // Remove Spacer widget since we're now using SingleChildScrollView
          ],
        ),
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

  Widget _buildFileList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('project_documents')
          .stream(primaryKey: ['id'])
          .eq('loan_id', widget.loanId)
          .order('uploaded_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final files = snapshot.data!;

        final filesByCategory = groupBy(files,
            (Map<String, dynamic> file) => file['file_category'] as String);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_outlined,

                    size: 20,

                    color: Colors.grey[800], // Darker icon color
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Project Files',
                    style: TextStyle(
                      fontSize: 14,

                      fontWeight: FontWeight.w600,

                      color: Colors.grey[900], // Very dark text for header
                    ),
                  ),
                ],
              ),
            ),

            // File categories

            ...filesByCategory.entries.map((entry) {
              return ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: SizedBox(
                  width: 20,
                  child: Icon(
                    _getCategoryIcon(entry.key),
                    color: const Color(0xFF6500E9),
                    size: 18,
                  ),
                ),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 12,

                          fontWeight: FontWeight.w500,

                          color: Colors
                              .grey[850], // Darker text for category names
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6500E9).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${entry.value.length}',
                        style: const TextStyle(
                          color: Color(0xFF6500E9),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: Icon(
                  Icons.chevron_right,

                  size: 18,

                  color: Colors.grey[700], // Darker chevron
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

  Widget _buildFileListItem(Map<String, dynamic> file) {
    final fileName = file['file_name'] as String;

    final uploadDate = DateTime.parse(file['uploaded_at'] as String);

    final fileStatus = file['file_status'] as String? ?? 'pending';

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      title: Text(
        fileName,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        'Uploaded ${_formatDate(uploadDate)}',
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[600],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusBadge(fileStatus),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            iconSize: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: Colors.grey[600],
            onPressed: () => _openFile(file['file_url'] as String, fileName),
          ),
        ],
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
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
        padding: const EdgeInsets.symmetric(
          horizontal: 28,
          vertical: 20,
        ),
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
}
