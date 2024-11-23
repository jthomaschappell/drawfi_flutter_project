import 'package:flutter/material.dart';
import 'package:tester/screens/loan_dashboard_screen.dart';
import 'package:tester/services/auth_service.dart';

class RecentLoan {
  final String id;
  final String companyName;
  final String address;
  final String location;
  final double disbursed;
  final int actions;
  final String status;
  final String initials;
  final Color color;

  RecentLoan({
    required this.id,
    required this.companyName,
    required this.address,
    required this.location,
    required this.disbursed,
    required this.actions,
    required this.status,
    required this.initials,
    required this.color,
  });
}

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
  String _searchQuery = '';
  int _selectedNavIndex = 0;

  final List<RecentLoan> recentLoans = [
    RecentLoan(
      id: '1',
      companyName: 'KDK Construction',
      address: '1024 S. Parkway Ave',
      location: 'American Fork, UT',
      disbursed: 0.16,
      actions: 0,
      status: 'On Track',
      initials: 'KD',
      color: const Color(0xFF4F46E5), // Indigo
    ),
    RecentLoan(
      id: '2',
      companyName: 'Solution Painting',
      address: '2116 N. Sundrive Ave',
      location: 'Park City, UT',
      disbursed: 0.25,
      actions: 1,
      status: 'On Track',
      initials: 'SP',
      color: const Color(0xFFE11D48), // Pink
    ),
    RecentLoan(
      id: '3',
      companyName: 'Big T Construction',
      address: '2601 N. University Ave',
      location: 'Provo, UT',
      disbursed: 0.81,
      actions: 2,
      status: 'On Track',
      initials: 'BT',
      color: const Color(0xFF16A34A), // Green
    ),
  ];

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Notifications'),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Mark all as read'),
            ),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNotificationItem(
                'New Draw Request',
                'Foundation work draw request submitted',
                '2 hours ago',
              ),
              _buildNotificationItem(
                'Inspection Complete',
                'Framing inspection has been completed',
                '1 day ago',
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

  Widget _buildNotificationItem(String title, String message, String time) {
    return ListTile(
      leading: const Icon(Icons.circle_notifications, color: Color(0xFF2563EB)),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            time,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSettingsItem(
              'Email Notifications',
              Icons.notifications,
              trailing: Switch(
                value: true,
                onChanged: (value) {},
                activeColor: const Color(0xFF2563EB),
              ),
            ),
            _buildSettingsItem(
              'Dark Mode',
              Icons.dark_mode,
              trailing: Switch(
                value: false,
                onChanged: (value) {},
                activeColor: const Color(0xFF2563EB),
              ),
            ),
            _buildSettingsItem(
              'Language',
              Icons.language,
              trailing: DropdownButton<String>(
                value: 'English',
                items: ['English', 'Spanish', 'French']
                    .map((lang) => DropdownMenuItem(
                          value: lang,
                          child: Text(lang),
                        ))
                    .toList(),
                onChanged: (value) {},
                underline: const SizedBox(),
              ),
            ),
          ],
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

  Widget _buildSettingsItem(String title, IconData icon, {Widget? trailing}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      trailing: trailing,
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Navigation Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                _buildNavButton(
                  'Home',
                  isSelected: _selectedNavIndex == 0,
                  onTap: () => setState(() => _selectedNavIndex = 0),
                ),
                const SizedBox(width: 32),
                _buildNavButton(
                  'Notifications',
                  isSelected: _selectedNavIndex == 1,
                  hasNotification: true,
                  onTap: () {
                    setState(() => _selectedNavIndex = 1);
                    _showNotifications();
                  },
                ),
                const SizedBox(width: 32),
                _buildNavButton(
                  'Loans',
                  isSelected: _selectedNavIndex == 2,
                  onTap: () {
                    setState(() => _selectedNavIndex = 2);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoanDashboardScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 32),
                _buildNavButton(
                  'Settings',
                  isSelected: _selectedNavIndex == 3,
                  onTap: () {
                    setState(() => _selectedNavIndex = 3);
                    _showSettings();
                  },
                ),
                const Spacer(),
                IconButton(
                  onPressed: () async {
                    final authService = AuthService();
                    await authService.signOut();
                  },
                  icon: const Icon(Icons.logout),
                  tooltip: 'Sign Out',
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hi ${widget.userProfile['full_name']?.split(' ')[0] ?? 'Hannah'},',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      _buildNewProjectButton(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Active Projects Counter
                  Row(
                    children: [
                      Text(
                        '${recentLoans.length}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.grid_view, color: Colors.grey[600], size: 24),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Search Bar
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: const InputDecoration(
                        hintText: 'Search by name, loan #, etc...',
                        hintStyle: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Color(0xFF666666),
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Recently Opened Section
                  const Text(
                    'Recently Opened',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Loan Cards
                  ...recentLoans
                      .where((loan) => loan.companyName
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                      .map((loan) => _buildLoanCard(loan))
                      .toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(
    String title, {
    bool isSelected = false,
    bool hasNotification = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF666666),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (hasNotification) ...[
              const SizedBox(width: 8),
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '1',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNewProjectButton() {
    return ElevatedButton.icon(
      onPressed: () {
        // TODO: Implement new project creation
        debugPrint('New Project button pressed');
      },
      icon: const Icon(Icons.add, size: 20),
      label: const Text('New Project'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLoanCard(RecentLoan loan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LoanDashboardScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Company Badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: loan.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    loan.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Company Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.companyName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loan.address,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loan.location,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              // Stats
              _buildStat('Disbursed', '${(loan.disbursed * 100).toInt()}%'),
              const SizedBox(width: 32),
              _buildStat('Actions', loan.actions.toString()),
              const SizedBox(width: 32),
              _buildStat('Status', loan.status, isStatus: true),
              const SizedBox(width: 16),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, {bool isStatus = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isStatus ? const Color(0xFF16A34A) : const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
