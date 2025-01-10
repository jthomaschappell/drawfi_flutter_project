import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tester/screens/gc_settings_screen.dart';
import 'package:tester/screens/draw_request_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ProjectDetailsScreen definition remains the same
class ProjectDetailsScreen extends StatelessWidget {
  const ProjectDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1F36)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Project Details',
          style: TextStyle(
            color: Color(0xFF1A1F36),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: const Center(
        child: Text('Project Details Content'),
      ),
    );
  }
}

// ContractorScreen definition
class ContractorScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const ContractorScreen({
    super.key,
    this.userProfile = const {
      'full_name': 'Hannah',
      'email': 'hannah@example.com',
      'user_role': 'contractor',
    },
  });

  @override
  State<ContractorScreen> createState() => _ContractorScreenState();
}

class _ContractorScreenState extends State<ContractorScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _loans = [];

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  // Future<void> _loadLoans() async {
  //   try {
  //     final response = await _supabase.from('construction_loans').select();

  //     setState(() {
  //       _loans = List<Map<String, dynamic>>.from(response ?? []);
  //       _isLoading = false;
  //     });
  //   } catch (e) {
  //     print('Error loading loans: $e');
  //     setState(() => _isLoading = false);
  //   }
  // }
  /// TODO: 
  /// I expect that when the page loads it will grab the customer ID: 
  /// Sun: 
  /// sun@gmail.com
  /// 36432c33-0aec-4d5d-8b52-dc0c38281e61 
  Future<void> _loadLoans() async {
    try {
      final contractorId = widget.userProfile['user_id'];
      print("The contractor id here in load loans is $contractorId");
      if (contractorId == null) {
        throw Exception('No contractor ID found in user profile');
      }

      final response = await _supabase
          .from('construction_loans')
          .select()
          .eq('contractor_id', contractorId);

      setState(() {
        _loans = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading loans: $e');
      setState(() => _isLoading = false);
    }
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GcSettingsScreen(userProfile: widget.userProfile),
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, Map<String, dynamic> loan) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Project'),
          content: Text(
              'Are you sure you want to delete ${loan['project_name']}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleDelete(loan);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _handleDelete(Map<String, dynamic> loan) {
    setState(() {
      // Print debug information
      print('Before deletion: ${_loans.length} loans');
      print('Trying to delete loan with ID: ${loan['loan_id']}');

      // Use loan_id instead of id
      _loans.removeWhere((item) => item['loan_id'] == loan['loan_id']);

      // Print after deletion
      print('After deletion: ${_loans.length} loans');
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project removed from view'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // When navigating to the DrawRequestScreen, pass the actual loan ID
  void _navigateToDrawRequest(BuildContext context, String actualLoanId) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => DrawRequestScreen(loanId: actualLoanId)),
    );
  }

  // Update _navigateToProjectDetails method
  void _navigateToProjectDetails(BuildContext context, String loanId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DrawRequestScreen(loanId: loanId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          _buildLeftNavigation(),
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftNavigation() {
    // Left navigation remains the same
    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            child: SvgPicture.string(
              '''<svg width="40" height="40" viewBox="0 0 1531 1531" fill="none" xmlns="http://www.w3.org/2000/svg">
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
              width: 40,
              height: 40,
            ),
          ),
          const SizedBox(height: 32),
          _buildNavItem(Icons.home_outlined, true),
          _buildNavItem(Icons.notifications_outlined, false),
          _buildNavItem(Icons.grid_view_outlined, false),
          _buildNavItem(Icons.settings_outlined, false,
              onTap: () => _navigateToSettings(context)),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isSelected, {VoidCallback? onTap}) {
    // Nav item remains the same
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isSelected ? const Color(0xFF6500E9) : Colors.transparent,
              width: 3,
            ),
          ),
          color: isSelected
              ? const Color(0xFF6500E9).withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Icon(
          icon,
          color: isSelected ? const Color(0xFF6500E9) : const Color(0xFF6B7280),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSearchBar(),
          const SizedBox(height: 24),
          const Text(
            'Recently Opened',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _loans.isEmpty // Add this check
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Icon(
                              Icons.folder_open_outlined,
                              size: 48,
                              color: Colors.black.withOpacity(0.2),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No projects found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black.withOpacity(0.4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _loadLoans,
                              child: const Text('Refresh'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _loans.length,
                        itemBuilder: (context, index) =>
                            _buildProjectCard(_loans[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    /// TODO: 
    /// 
    print("This is ");
    // Header remains mostly the same, but we'll update the project count
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi ${widget.userProfile['full_name']?.split(' ')[0]}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_loans.length} Active Projects',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        // If you have access to a loan ID when creating the button:
        ElevatedButton(
          onPressed: () =>
              _navigateToDrawRequest(context, "your-actual-loan-id"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6500E9),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 20),
              SizedBox(width: 8),
              Text('New Project'),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildSearchBar() {
    // Search bar remains the same
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.black54, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search by name, loan & etc',
                hintStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                border: InputBorder.none,
                fillColor: Colors.white,
                filled: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> loan) {
    final projectName = loan['project_name'] ?? 'Unknown Project';
    final location = loan['location'] ?? 'Unknown Location';
    final initials = projectName
        .split(' ')
        .take(2)
        .map((word) => word.isNotEmpty ? word[0] : '')
        .join('')
        .toUpperCase();

    return InkWell(
      onTap: () => _navigateToProjectDetails(context, loan['id'].toString()),
      hoverColor: Colors.grey[50],
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
          color: Colors.white,
        ),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6500E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      projectName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: Color(0xFF6B7280)),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Add delete button here
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red.withOpacity(0.7),
                onPressed: () => _showDeleteConfirmation(
                    context, loan), // Pass the entire loan object
                tooltip: 'Delete project',
              ),
              const Icon(Icons.chevron_right,
                  color: Color(0xFF6B7280), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
