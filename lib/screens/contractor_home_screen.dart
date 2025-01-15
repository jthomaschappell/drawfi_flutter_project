import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tester/screens/gc_settings_screen.dart';
import 'package:tester/screens/contractor_loan_screen.dart';
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
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> _projectCards = [];
  List<Map<String, dynamic>> filteredProjectCards = [];
  String searchQuery = '';

// 1. First, update initState to initialize filteredProjectCards
  @override
  void initState() {
    super.initState();
    filteredProjectCards =
        List.from(_projectCards); // Initialize with empty list
    _loadLoans();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLoans() async {
    try {
      final contractorId = widget.userProfile['user_id'];
      print(
        "The contractor id here in load loans is $contractorId",
      );
      if (contractorId == null) {
        throw Exception('No contractor ID found in user profile');
      }

      final response = await _supabase
          .from('construction_loans')
          .select()
          .eq('contractor_id', contractorId);

      setState(() {
        _projectCards = List<Map<String, dynamic>>.from(response);
        filteredProjectCards =
            List.from(_projectCards); // Initialize filtered list
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
            'Are you sure you want to delete ${loan['project_name']}? This action cannot be undone.',
          ),
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
      print('Before deletion: ${_projectCards.length} loans');
      print('Trying to delete loan with ID: ${loan['loan_id']}');

      // Use loan_id instead of id
      _projectCards.removeWhere((item) => item['loan_id'] == loan['loan_id']);

      // Print after deletion
      print('After deletion: ${_projectCards.length} loans');
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
          builder: (context) => ContractorLoanScreen(loanId: actualLoanId)),
    );
  }

  // Update _navigateToProjectDetails method
  void _navigateToProjectDetails(BuildContext context, String loanId) {
    /// DONE:
    /// Press the project card and see if THIS shows up.
    print("\n");
    print("HEY Y'ALL");
    print("What is the loan ID passed into navigate to project details?");
    print("Loan ID: $loanId");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContractorLoanScreen(loanId: loanId),
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

// 3. Update the ListView in _buildMainContent to use filteredProjectCards
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
                : filteredProjectCards
                        .isEmpty // Changed from _projectCards to filteredProjectCards
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
                              searchQuery.isEmpty
                                  ? 'No projects found'
                                  : 'No matching projects found', // Updated message for search results
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black.withOpacity(0.4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (searchQuery
                                .isEmpty) // Only show refresh button if not searching
                              TextButton(
                                onPressed: _loadLoans,
                                child: const Text('Refresh'),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredProjectCards
                            .length, // Changed from _projectCards to filteredProjectCards
                        itemBuilder: (context, index) => _buildProjectCard(
                          filteredProjectCards[
                              index], // Changed from _projectCards to filteredProjectCards
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    print("\n");
    print("This is the widget user profile: ${widget.userProfile}");
    print("\n");
    // Header remains mostly the same, but we'll update the project count
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi ${widget.userProfile['email']?.split(' ')[0]}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_projectCards.length} Active Projects',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Help us solve this problem.
  /// TODO:
  /// The problem is probably here.

  Widget _buildSearchBar() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: searchController,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF111827),
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value.toLowerCase();
            // Filter the projects based on search query
            if (searchQuery.isEmpty) {
              // If search is empty, show all items
              filteredProjectCards = List.from(_projectCards);
            } else {
              // Filter items based on search query
              filteredProjectCards = _projectCards.where(
                (project) {
                  final projectName =
                      project['project_name']?.toString().toLowerCase() ?? '';
                  print('Searching project: $projectName'); // Debug print
                  return projectName.contains(searchQuery);
                },
              ).toList();
            }
          });
        },
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: 'Search projects...',
          hintStyle: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: Colors.grey[700],
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      searchController.clear();
                      searchQuery = '';
                      filteredProjectCards = List.from(_projectCards);
                    });
                  },
                )
              : null,
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

  void _testNavigationSetup(Map<String, dynamic> loan) {
    /// DONE:
    /// Run the app
    /// See if it comes up with a whole bunch of these.
    print("");
    print("Testing navigation setup...");
    print("Loan ID being passed: ${loan['loan_id']}");
    print("Full loan object: $loan");
    print("");
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

    _testNavigationSetup(loan);

    return InkWell(
      onTap: () => _navigateToProjectDetails(
        context,
        loan['loan_id'].toString(),
      ),
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
