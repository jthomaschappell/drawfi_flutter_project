import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tester/loan_dashboard/lender_loan_screen.dart';
import 'package:tester/screens/inspector_loan_screen.dart';
import 'package:tester/screens/path_to_auth_screen/auth_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tester/screens/notification_screen.dart';

final supabase = Supabase.instance.client;

class InspectorScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const InspectorScreen({
    super.key,
    required this.userProfile,
  });

  @override
  State<InspectorScreen> createState() => _InspectorScreenState();
}

class _InspectorScreenState extends State<InspectorScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _projectCards = [];
  List<Map<String, dynamic>> filteredProjectCards = [];
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    filteredProjectCards = List.from(_projectCards);
    _loadProjects();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    try {
      final inspectorId = widget.userProfile['user_id'];
      print("Loading projects for inspector ID: $inspectorId");
      
      if (inspectorId == null) {
        throw Exception('No inspector ID found in user profile');
      }

      final response = await _supabase
          .from('construction_loans')
          .select()
          .eq('inspector_id', inspectorId);

      setState(() {
        _projectCards = List<Map<String, dynamic>>.from(response)
          ..sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
        filteredProjectCards = List.from(_projectCards);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading projects: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? 24.0 : 16.0;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: _buildHeader(),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi ${widget.userProfile['full_name']?.split(' ')[0] ?? 'Inspector'},',
                        style: TextStyle(
                          fontSize: screenWidth > 600 ? 28 : 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_projectCards.length} Active Projects',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _buildSearchBar(),
            _buildTabBar(),
            Expanded(
              child: _buildProjectsList(),
            ),
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SvgPicture.string(
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
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: searchController,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value.toLowerCase();
            if (searchQuery.isEmpty) {
              filteredProjectCards = List.from(_projectCards);
            } else {
              filteredProjectCards = _projectCards.where((project) {
                final projectName = project['project_name']?.toString().toLowerCase() ?? '';
                final location = project['location']?.toString().toLowerCase() ?? '';
                return projectName.contains(searchQuery) || location.contains(searchQuery);
              }).toList();
            }
          });
        },
        decoration: InputDecoration(
          hintText: 'Search projects...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
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
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          fillColor: Colors.white,
          filled: true,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            'Recently Opened',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 24),
          Text(
            'All Projects',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredProjectCards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 48,
              color: Colors.black.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isEmpty ? 'No projects found' : 'No matching projects found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black.withOpacity(0.4),
              ),
            ),
            if (searchQuery.isEmpty)
              TextButton(
                onPressed: _loadProjects,
                child: const Text('Refresh'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredProjectCards.length,
      itemBuilder: (context, index) {
        final project = filteredProjectCards[index];
        return _buildProjectCard(project);
      },
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final projectName = project['project_name'] ?? 'Unknown Project';
    final location = project['location'] ?? 'Unknown Location';
    final lastInspection = project['last_inspection_date'] ?? 'Not inspected';
    final completion = project['completion_percentage']?.toString() ?? '0';
    final nextInspection = project['next_inspection_date'] ?? 'Not scheduled';
    
    final initials = projectName
        .split(' ')
        .take(2)
        .map((word) => word.isNotEmpty ? word[0] : '')
        .join('')
        .toUpperCase();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InspectorLoanScreen(
              projectData: {
                'name': projectName,
                'location': location,
                'lastInspection': lastInspection,
                'completion': completion,
                'nextInspection': nextInspection,
                'loan_id': project['loan_id'],
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6500E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              location,
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'On track',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoColumn('Last Inspection', lastInspection),
                  _buildInfoColumn('Completed', '$completion%'),
                  _buildInfoColumn('Next Inspection', nextInspection),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavBarItem(Icons.home, true, 'Home'),
          _buildNavBarItem(Icons.notifications_none, false, 'Notifications', onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationScreen()),
            );
          }),
          _buildNavBarItem(Icons.calendar_today, false, 'Calendar'),
          _buildNavBarItem(Icons.settings, false, 'Settings', onTap: () {
            _showSettingsDialog();
          }),
        ],
      ),
    );
  }

  Widget _buildNavBarItem(IconData icon, bool isSelected, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF6500E9) : Colors.grey[600],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? const Color(0xFF6500E9) : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF6500E9),
                  ),
                  title: const Text('Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    // Add profile navigation here
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.notifications_outlined,
                    color: Color(0xFF6500E9),
                  ),
                  title: const Text('Notification Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    // Add notification settings navigation here
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Log out',
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context); // Close dialog
                    await _handleLogout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    try {
      await _supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const AuthScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error logging out. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}