import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final int inspections;
  final String status;
  final DateTime lastUpdated;
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
    required this.inspections,
    required this.status,
    required this.lastUpdated,
    required this.updates,
    required this.documents,
  });
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
}

// Custom Widgets
class NavigationIconButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String label;

  const NavigationIconButton({
    Key? key,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.label,
  }) : super(key: key);

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

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const ProjectCard({
    Key? key,
    required this.project,
    required this.onTap,
  }) : super(key: key);

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
      onTap: onTap,
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
              _buildMetric('Inspections', project.inspections.toString()),

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
              const SizedBox(width: 16),
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
    Key? key,
    required this.userProfile,
  }) : super(key: key);

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
  Project? _selectedProject;

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterProjects();
    });
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);

    // Simulated API call with mock data
    await Future.delayed(const Duration(milliseconds: 800));

    final mockProjects = List.generate(
      10,
      (index) => Project(
        id: 'PRJ-${1000 + index}',
        companyInitials: 'KD',
        companyName: 'KDK Construction ${index + 1}',
        location: 'American Fork, UT',
        disbursed: 50.0 + (index * 5),
        completed: 50.0 + (index * 3),
        draws: 3,
        inspections: 2,
        status: index % 3 == 0
            ? 'On track'
            : index % 3 == 1
                ? 'At risk'
                : 'Behind',
        lastUpdated: DateTime.now().subtract(Duration(days: index)),
        updates: List.generate(
          3,
          (i) => ProjectUpdate(
            action: 'Updated project status',
            user: 'JD',
            timestamp: DateTime.now().subtract(Duration(hours: i * 2)),
            details: 'Updated project completion percentage',
          ),
        ),
        documents: List.generate(
          4,
          (i) => ProjectDocument(
            id: 'DOC-${1000 + i}',
            name: 'Document ${i + 1}',
            type: i % 2 == 0 ? 'PDF' : 'Image',
            uploadDate: DateTime.now().subtract(Duration(days: i)),
            uploadedBy: 'John Doe',
            status: 'Active',
            url: 'https://example.com/doc${i + 1}',
          ),
        ),
      ),
    );

    setState(() {
      _projects = mockProjects;
      _isLoading = false;
    });
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

  @override
  Widget build(BuildContext context) {
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

                // Navigation
                NavigationIconButton(
                  icon: Icons.home_outlined,
                  isSelected: _selectedNavIndex == 0,
                  onTap: () => setState(() => _selectedNavIndex = 0),
                  label: 'Home',
                ),
                NavigationIconButton(
                  icon: Icons.notifications_outlined,
                  isSelected: _selectedNavIndex == 1,
                  onTap: () => setState(() => _selectedNavIndex = 1),
                  label: 'Notifications',
                ),
                NavigationIconButton(
                  icon: Icons.grid_view_outlined,
                  isSelected: _selectedNavIndex == 2,
                  onTap: () => setState(() => _selectedNavIndex = 2),
                  label: 'Projects',
                ),
                NavigationIconButton(
                  icon: Icons.settings_outlined,
                  isSelected: _selectedNavIndex == 3,
                  onTap: () => setState(() => _selectedNavIndex = 3),
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
                        widget.userProfile['full_name'] ?? 'Hannah Smith',
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
                                  'Hi ${widget.userProfile['first_name'] ?? 'Hannah'},',
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
                              onPressed: () => _showNewProjectModal(),
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search by name, loan #, etc...',
                                    hintStyle: TextStyle(
                                      color: Colors.black.withOpacity(0.4),
                                      fontSize: 14,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: Colors.black.withOpacity(0.4),
                                      size: 20,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recently Opened',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: _loadProjects,
                              tooltip: 'Refresh projects',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Projects List
                        if (_projects.isEmpty)
                          Center(
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
                              ],
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _projects.length,
                            itemBuilder: (context, index) => ProjectCard(
                              project: _projects[index],
                              onTap: () =>
                                  _showProjectDetails(_projects[index]),
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

  void _showProjectDetails(Project project) {
    // Implementation of project details modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProjectDetailsModal(project: project),
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
    Key? key,
    required this.project,
  }) : super(key: key);

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

//   Future<Widget> buildLoanInfo() async {
//   final loan = await Supabase.instance.client
//       .from('construction_loans')
//       .select()
//       .eq('id', '31a98faf-c77c-4d1f-b7d4-2aa12546b3ba')
//       .single();

//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Text('Amount: \$${loan['amount']}'),
//       Text('Muffin: ${loan['start_date']}'),
//     ],
//   );
// }

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
