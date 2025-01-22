import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tester/loan_dashboard/lender_loan_screen.dart';
import 'package:tester/screens/notification_screen.dart';
import 'package:tester/screens/invitation_screen.dart';
import 'package:tester/screens/settings_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Constants
const String appLogo = '''
<svg width="1531" height="1531" viewBox="0 0 1531 1531" fill="none" xmlns="http://www.w3.org/2000/svg">
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
''';

// Models
class Project {
  final String id;
  final String companyInitials;
  final String companyName;
  final String location;
  final double disbursed;
  final double completed;
  final int draws;
  final DateTime? nextInspectionDate; // New field
  final String status;
  final DateTime lastUpdated;
  final DateTime startDate;
  final List<ProjectUpdate> updates;
  final List<ProjectDocument> documents;

  Project({
    required this.id,
    required this.companyInitials,
    required this.companyName,
    required this.location,
    required this.disbursed,
    required this.completed,
    required this.draws,
    this.nextInspectionDate, // Made optional
    required this.status,
    required this.lastUpdated,
    required this.startDate,
    required this.updates,
    required this.documents,
  });

  // yo thomas

  // In the Project.fromSupabase method, replace the current completion calculation with:

  factory Project.fromSupabase(Map<String, dynamic> data) {
    // Get total budget
    final totalBudget = (data['total_amount'] is int)
        ? (data['total_amount'] as int).toDouble()
        : data['total_amount']?.toDouble() ?? 0.0;

    // Calculate completion based on the completed inspection percentages
    double completionPercentage = 0.0;
    if (data['inspections'] != null) {
      // Sum up (INSP × Budget) for each line item
      double weightedSum = 0.0;
      double totalBudgetSum = 0.0;

      // Iterate through inspection items
      for (var item in data['inspections']) {
        double inspectionPercentage = item['inspection_percentage'] ?? 0.0;
        double itemBudget = item['budget'] ?? 0.0;

        weightedSum += (inspectionPercentage * itemBudget);
        totalBudgetSum += itemBudget;
      }

      // Calculate final weighted percentage
      if (totalBudgetSum > 0) {
        completionPercentage = (weightedSum / totalBudgetSum);
      }
    }

    // TODO:
    // Test this function that Claude gave us.
    /// Make a New Project that has project_name as null.
    ///
    return Project(
      companyInitials:
          (data['contractor_id'] as String?)?.substring(0, 2).toUpperCase() ??
              'UN',
      id: data['loan_id']?.toString() ?? 'UNKNOWN',
      companyName: data['project_name']?.toString() ?? 'Unknown Project',
      location: data['location']?.toString() ?? 'Location TBD',
      disbursed: 0.0,
      completed: 0.0,
      draws: 0,
      status: 'On track',
      lastUpdated: DateTime.now(),
      startDate: DateTime.now(),
      updates: [],
      documents: [],
    );
  }

  get inspections => null;
}

class ProjectUpdate {
  final String action;
  final String user;
  final DateTime timestamp;
  final String details;

  ProjectUpdate({
    required this.action,
    required this.user,
    required this.timestamp,
    required this.details,
  });

  factory ProjectUpdate.fromSupabase(Map<String, dynamic> data) {
    return ProjectUpdate(
      action: data['action'] as String? ?? '',
      user: data['user'] as String? ?? '',
      timestamp: DateTime.parse(data['timestamp'] as String),
      details: data['details'] as String? ?? '',
    );
  }
}

class ProjectDocument {
  final String id;
  final String name;
  final String type;
  final DateTime uploadDate;
  final String uploadedBy;
  final String status;
  final String url;

  ProjectDocument({
    required this.id,
    required this.name,
    required this.type,
    required this.uploadDate,
    required this.uploadedBy,
    required this.status,
    required this.url,
  });

  factory ProjectDocument.fromSupabase(Map<String, dynamic> data) {
    return ProjectDocument(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      type: data['type'] as String? ?? '',
      uploadDate: DateTime.parse(data['upload_date'] as String),
      uploadedBy: data['uploaded_by'] as String? ?? '',
      status: data['status'] as String? ?? '',
      url: data['url'] as String? ?? '',
    );
  }
}

// Custom Widgets
class NavigationIconButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String label;

  const NavigationIconButton({
    super.key,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFF6B7280),
                size: 24,
              ),
              if (isSelected) ...[
                const SizedBox(height: 4),
                Container(
                  width: 16,
                  height: 2,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4F46E5),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(2)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CompletionDataProvider {
  static final Map<String, double> _completionPercentages = {};

  static void setCompletion(String loanId, double percentage) {
    _completionPercentages[loanId] = percentage;
  }

  static double getCompletion(String loanId) {
    return _completionPercentages[loanId] ?? 0.0;
  }
}

// In your LoanDashboardScreen, after calculating the completion percentage:
void updateCompletionPercentage(double completionPercentage, dynamic widget) {
  CompletionDataProvider.setCompletion(widget.loanId, completionPercentage);
}

//
// ADD THIS NEW CODE INSTEAD
// NEW CODE
class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap; // Make onTap nullable
  final VoidCallback onDelete;

  const ProjectCard({
    super.key,
    required this.project,
    this.onTap, // Remove required
    required this.onDelete,
  });

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Project'),
          content: Text(
              'Are you sure you want to delete ${project.companyName}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDelete(); // Changed to not pass project.id
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'on track':
        return const Color(0xFF059669);
      case 'at risk':
        return const Color(0xFFD97706);
      case 'behind':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, // InkWell accepts nullable callback
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Company Logo/Initials
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    project.companyInitials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Company Info
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.companyName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.location,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),

              // Metrics
              _buildMetric(
                  'Disbursed', '${project.disbursed.toStringAsFixed(0)}%'),
              _buildMetric(
                  'Completed', '${project.completed.toStringAsFixed(0)}%'),
              _buildMetric('Draws', project.draws.toString()),
              _buildMetric(
                  'Next Inspection',
                  project.nextInspectionDate != null
                      ? DateFormat('MMM d').format(project.nextInspectionDate!)
                      : 'N/A'),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(project.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  project.status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(project.status),
                  ),
                ),
              ),

              // Arrow
              // Arrow and Delete button
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red.withOpacity(0.7),
                onPressed: () => _showDeleteConfirmation(context),
                tooltip: 'Delete project',
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.black.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

// Main Screen Implementation
class LenderScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const LenderScreen({
    super.key,
    required this.userProfile,
  });

  @override
  State<LenderScreen> createState() => _LenderScreenState();
}

class _LenderScreenState extends State<LenderScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedNavIndex = 0;
  String _searchQuery = '';
  String _selectedStatus = 'All';
  bool _isLoading = false;
  List<Project> _projects = [];
  List<Project> _deletedProjects = []; // New: Track deleted projects
  bool _showingTrash = false; // New: Toggle between active and deleted projects
  Project? _selectedProject;
  static const String TRASH_KEY = 'deleted_projects';
  Future<void> _saveTrashState() async {
    final prefs = await SharedPreferences.getInstance();
    final deletedProjectsJson = _deletedProjects
        .map((project) => {
              'id': project.id,
              'companyInitials': project.companyInitials,
              'companyName': project.companyName,
              'location': project.location,
              'disbursed': project.disbursed,
              'completed': project.completed,
              'draws': project.draws,
              'nextInspectionDate':
                  project.nextInspectionDate?.toIso8601String(),
              'status': project.status,
              'lastUpdated': project.lastUpdated.toIso8601String(),
              'startDate': project.startDate.toIso8601String(),
            })
        .toList();

    await prefs.setString(TRASH_KEY, jsonEncode(deletedProjectsJson));
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _filterProjects();
  }

  Future<void> _loadTrashState() async {
    final prefs = await SharedPreferences.getInstance();
    final deletedProjectsJson = prefs.getString(TRASH_KEY);

    if (deletedProjectsJson != null) {
      final List<dynamic> decodedList = jsonDecode(deletedProjectsJson);
      setState(() {
        _deletedProjects = decodedList
            .map((json) => Project(
                  id: json['id'],
                  companyInitials: json['companyInitials'],
                  companyName: json['companyName'],
                  location: json['location'],
                  disbursed: json['disbursed'],
                  completed: json['completed'],
                  draws: json['draws'],
                  nextInspectionDate: json['nextInspectionDate'] != null
                      ? DateTime.parse(json['nextInspectionDate'])
                      : null,
                  status: json['status'],
                  lastUpdated: DateTime.parse(json['lastUpdated']),
                  startDate: DateTime.parse(json['startDate']),
                  updates: [],
                  documents: [],
                ))
            .toList();
      });
    }
  }

  // Add this method to handle UI-only deletion
  void _handleDelete(int index) {
    setState(() {
      final deletedProject = _projects.removeAt(index);
      _deletedProjects.add(deletedProject);
    });

    _saveTrashState(); // Save trash state

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Project moved to trash'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'UNDO',
            textColor: Colors.white,
            onPressed: () {
              setState(() {
                final restoredProject = _deletedProjects.removeLast();
                _projects.insert(index, restoredProject);
              });
              _saveTrashState(); // Save trash state after undo
              _loadProjects(); // Reload projects from server
            },
          ),
        ),
      );
    }
  }

  void _handleRestore(int index) {
    setState(() {
      final restoredProject = _deletedProjects.removeAt(index);
      _projects.add(restoredProject);
    });

    _saveTrashState(); // Save trash state
    _loadProjects(); // Reload projects from server

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project restored'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _loadTrashState(); // Add this line here
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadProjects() async {
    try {
      setState(() => _isLoading = true);

      final lenderId = widget.userProfile['user_id'];
      // print('Loading projects for lender: $lenderId');

      final response = await supabase.from('construction_loans').select('''
          loan_id,
          contractor_id,
          project_name,
          total_amount,
          draw_count,
          updated_at,
          location,
          start_date
        ''').eq('lender_id', lenderId).order('updated_at', ascending: false);

      // print('Response from Supabase: $response');

      // Convert response to projects and filter out trashed projects
      final projects = (response as List<dynamic>)
          .map((data) => Project.fromSupabase(data as Map<String, dynamic>))
          .where((project) =>
              !_deletedProjects.any((deleted) => deleted.id == project.id))
          .toList();

      setState(() {
        _projects = projects;
        _isLoading = false;
      });
    } catch (error) {
      print('Error loading projects: $error');
      setState(() {
        _isLoading = false;
        _projects = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading projects: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterProjects() {
    if (_searchQuery.isEmpty && _selectedStatus == 'All') {
      _loadProjects();
      return;
    }

    setState(() {
      _projects = _projects.where((project) {
        final matchesSearch = project.companyName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            project.id.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesStatus =
            _selectedStatus == 'All' || project.status == _selectedStatus;
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Widget _buildProgressCircles() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 140,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: 0.75,
                        strokeWidth: 10,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF6500E9)),
                      ),
                      const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '75%',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            Text(
                              'Complete',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
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
        Expanded(
          child: Container(
            height: 140,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: 0.45,
                        strokeWidth: 10,
                        backgroundColor: Colors.grey[200],
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                      const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '45%',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            Text(
                              'Disbursed',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
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
    // userProfile
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // App Bar
          Container(
            height: 72,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Logo
                SizedBox(
                  width: 40,
                  height: 40,
                  child: SvgPicture.string(appLogo),
                ),
                const SizedBox(width: 24),

                NavigationIconButton(
                  icon: Icons.notifications_outlined,
                  isSelected: _selectedNavIndex == 1,
                  onTap: () {
                    setState(() => _selectedNavIndex = 1);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // builder: (context) => NotificationScreen()),
                        builder: (context) => NotificationScreen(),
                      ),
                    );
                  },
                  label: 'Notifications',
                ),

                NavigationIconButton(
                  icon: Icons.grid_view_outlined,
                  isSelected: _selectedNavIndex == 2,
                  onTap: () => setState(() {
                    // _selectedNavIndex = 2;
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //       builder: (context) => const ProjectsScreen()),
                    // );
                  }),
                  label: 'Projects',
                ),

                NavigationIconButton(
                  icon: Icons.settings_outlined,
                  isSelected: _selectedNavIndex == 3,
                  onTap: () => setState(() {
                    _selectedNavIndex = 3;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsScreen(
                                userProfile: {},
                              )),
                    );
                  }),
                  label: 'Settings',
                ),

                const Spacer(),

                // User Profile
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF4F46E5),
                        child: Text(
                          widget.userProfile['initials'] ?? 'H',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.userProfile['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4F46E5),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hi ${widget.userProfile['name'] ?? 'No name found'},',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      '${_projects.length}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    const Text(
                                      ' Active Projects',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // New Project Button
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const InvitationScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add, size: 20),
                              label: const Text('New Project'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Search and Filter Bar
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors
                                .white, // Set the container background color to white
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(
                                0xFFE5E7EB,
                              ),
                            ), // Light gray border
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  style: const TextStyle(
                                    color: Colors
                                        .black, // Set input text color to black
                                    fontSize: 14,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Search by name, loan #, etc...',
                                    hintStyle: TextStyle(
                                      color: Colors
                                          .black, // Black letters for the hint text
                                      fontSize: 14,
                                      backgroundColor: Colors
                                          .white, // White background for hint text
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: Colors.black, // Black search icon
                                      size: 20,
                                    ),
                                    filled: true,
                                    fillColor: Colors
                                        .white, // White background for the hint field
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                height: 48,
                                width: 1,
                                color: const Color(0xFFE5E7EB),
                              ),
                              // Status Filter Dropdown
                              PopupMenuButton<String>(
                                offset: const Offset(0, 48),
                                onSelected: (value) {
                                  setState(() {
                                    _selectedStatus = value;
                                    _filterProjects();
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Status: $_selectedStatus',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.keyboard_arrow_down,
                                        size: 20,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ],
                                  ),
                                ),
                                itemBuilder: (context) => [
                                  'All',
                                  'On track',
                                  'At risk',
                                  'Behind',
                                ]
                                    .map((status) => PopupMenuItem(
                                          value: status,
                                          child: Text(status),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Projects List Header
                        // Projects List Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left side - Title and count
                            Row(
                              children: [
                                Icon(
                                  _showingTrash
                                      ? Icons.delete_outline
                                      : Icons.folder_outlined,
                                  color: _showingTrash
                                      ? Colors.red[400]
                                      : const Color(0xFF111827),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _showingTrash ? 'Trash' : 'Recently Opened',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: _showingTrash
                                        ? Colors.red[400]
                                        : const Color(0xFF111827),
                                  ),
                                ),
                                if (_deletedProjects.isNotEmpty &&
                                    !_showingTrash) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(16),
                                      border:
                                          Border.all(color: Colors.red[100]!),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          size: 16,
                                          color: Colors.red[400],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_deletedProjects.length}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.red[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            // Right side - Actions
                            Row(
                              children: [
                                if (_showingTrash &&
                                    _deletedProjects.isNotEmpty)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.red[100]!),
                                    ),
                                    child: TextButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Row(
                                                children: [
                                                  Icon(
                                                      Icons
                                                          .warning_amber_rounded,
                                                      color: Colors.red[400],
                                                      size: 24),
                                                  const SizedBox(width: 8),
                                                  const Text('Empty Trash?'),
                                                ],
                                              ),
                                              content: const Text(
                                                  'This action cannot be undone. Are you sure you want to permanently delete all items in trash?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _deletedProjects.clear();
                                                    });
                                                    _saveTrashState();
                                                    Navigator.of(context).pop();
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                              'Trash emptied'),
                                                          backgroundColor:
                                                              Colors.red,
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.red[400],
                                                    foregroundColor:
                                                        Colors.white,
                                                  ),
                                                  child:
                                                      const Text('Empty Trash'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        foregroundColor: Colors.red[400],
                                      ),
                                      icon: const Icon(Icons.delete_forever),
                                      label: const Text('Empty Trash',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500)),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: _showingTrash
                                        ? const Color(0xFF111827)
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      _showingTrash
                                          ? Icons.grid_view
                                          : Icons.delete_outline,
                                      color: _showingTrash
                                          ? Colors.white
                                          : Colors.grey[700],
                                    ),
                                    onPressed: () => setState(
                                        () => _showingTrash = !_showingTrash),
                                    tooltip: _showingTrash
                                        ? 'Show active projects'
                                        : 'Show trash',
                                  ),
                                ),
                                if (!_showingTrash)
                                  IconButton(
                                    icon: const Icon(Icons.refresh),
                                    onPressed: _loadProjects,
                                    tooltip: 'Refresh projects',
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Projects List
                        if ((_showingTrash && _deletedProjects.isEmpty) ||
                            (!_showingTrash && _projects.isEmpty))
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 40),
                                Icon(
                                  _showingTrash
                                      ? Icons.delete_outline
                                      : Icons.folder_open_outlined,
                                  size: 48,
                                  color: Colors.black.withOpacity(0.2),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _showingTrash
                                      ? 'Trash is empty'
                                      : 'No projects found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black.withOpacity(0.4),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _showingTrash
                                ? _deletedProjects.length
                                : _projects.length,
                            itemBuilder: (context, index) {
                              final project = _showingTrash
                                  ? _deletedProjects[index]
                                  : _projects[index];
                              return ProjectCard(
                                project: project,
                                onTap: _showingTrash
                                    ? null
                                    : () => _goToLoanDashboardScreen(project),
                                onDelete: _showingTrash
                                    ? () => _handleRestore(index)
                                    : () => _handleDelete(index),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showNewProjectModal() {
    // Implement new project modal
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Project'),
        content: const Text('New project form will go here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _goToLoanDashboardScreen(Project project) {
    print(
        "ATTENTION EVERYONE: What is the project ID here in showProjectDetails: ${project.id}");
    // Navigate to LoanDashboardScreen instead of showing modal
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LenderLoanScreen(
          loanId: project.id, // Pass the loan_id to the dashboard
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

class ProjectDetailsModal extends StatelessWidget {
  final Project project;

  const ProjectDetailsModal({
    super.key,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.companyName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Project ID: ${project.id}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 20,
                    color: const Color(0xFF6B7280),
                  ),
                ],
              ),
            ),

            // Tabs
            DefaultTabController(
              length: 3,
              child: Expanded(
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Overview'),
                        Tab(text: 'Documents'),
                        Tab(text: 'Activity'),
                      ],
                      labelColor: Color(0xFF4F46E5),
                      unselectedLabelColor: Color(0xFF6B7280),
                      indicatorColor: Color(0xFF4F46E5),
                      indicatorSize: TabBarIndicatorSize.tab,
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildOverviewTab(),
                          _buildDocumentsTab(),
                          _buildActivityTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    String theLoanId = '31a98faf-c77c-4d1f-b7d4-2aa12546b3ba';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project Progress
          _buildProgressSection(
            'Project Progress',
            project.completed,
            const Color(0xFF4F46E5),
          ),
          const SizedBox(height: 24),

          // Fund Disbursement
          _buildProgressSection(
            'Fund Disbursement',
            project.disbursed,
            const Color(0xFF059669),
          ),
          const SizedBox(height: 24),
          buildLoanInfoWidget(theLoanId),
          const SizedBox(height: 24),

          // Stats Grid
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  'Total Draws',
                  project.draws.toString(),
                  Icons.analytics_outlined,
                ),
                _buildStatCard(
                  'Inspections',
                  project.inspections.toString(),
                  Icons.assignment_outlined,
                ),
                _buildStatCard(
                  'Status',
                  project.status,
                  Icons.check_circle_outline,
                ),
                _buildStatCard(
                  'Last Updated',
                  DateFormat('MMM dd, yyyy').format(project.lastUpdated),
                  Icons.calendar_today_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(String title, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              height: 8,
              width: percentage *
                  2, // Multiply by 2 to make it look like the design
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF4F46E5)),
              const SizedBox(width: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: project.documents.length,
      itemBuilder: (context, index) {
        final document = project.documents[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  document.type == 'PDF' ? Icons.picture_as_pdf : Icons.image,
                  color: const Color(0xFF4F46E5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      'Uploaded on ${DateFormat('MMM dd, yyyy').format(document.uploadDate)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined),
                color: const Color(0xFF4F46E5),
                onPressed: () {},
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> getLoanInfo(String loanId) async {
    final loan = await Supabase.instance.client
        .from('construction_loans')
        .select()
        .eq('loan_id', loanId)
        .single();
    /**
     * Hey Chretien 
     * this is a useful function (called getLoanInfo()) that anyone can use to get construction_loan info. 
     * If you want to make a new function to get draw_request info, you can copy paste this and then change the query to match the new table.
     *  */
    // final loanData = await getLoanInfo();
    // print(loanData['total_amount']);
    // print(loanData['start_date']);
    return loan;
  }

  Widget buildLoanInfoWidget(String loanId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: getLoanInfo(loanId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Placeholder();

        final loan = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amount: \$${loan['total_amount']}',
              style: const TextStyle(color: Colors.black),
            ),
            Text(
              'Start Date: ${loan['start_date']}',
              style: const TextStyle(color: Colors.black),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActivityTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: project.updates.length,
      itemBuilder: (context, index) {
        final update = project.updates[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    update.user,
                    style: const TextStyle(
                      color: Color(0xFF4F46E5),
                      fontWeight: FontWeight.w500,
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
                      update.action,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy h:mm a')
                          .format(update.timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
