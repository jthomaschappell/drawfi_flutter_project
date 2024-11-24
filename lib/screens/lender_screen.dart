import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tester/screens/loan_dashboard_screen.dart';
import 'package:tester/screens/new_project_screen.dart';

const String _logoSvg = '''
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
  ];

  void _onNavItemTap(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F5F5), // Grey background for the main content
      body: Column(
        children: [
          // Top Bar
          Container(
            color: Colors.white, // TopBar remains white
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                SvgPicture.string(_logoSvg, height: 40, width: 40),
                const SizedBox(width: 16),
                _buildNavItem(Icons.home_outlined, 0),
                _buildNavItem(Icons.notifications_outlined, 1),
                _buildNavItem(Icons.apartment_outlined, 2),
                _buildNavItem(Icons.settings_outlined, 3),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi ${widget.userProfile['full_name'] ?? 'Hannah'},',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '36', // The number
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.bold, // Make the number bold
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      ' Active Projects', // The rest of the text
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.w400, // Regular weight
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NewProjectScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('New Project'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
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
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      style: const TextStyle(color: Colors.black),
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
                        fillColor: Colors.white,
                        filled: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Recently Opened',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: recentLoans
                        .map((loan) => _buildLoanCard(loan))
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

  Widget _buildLoanCard(RecentLoan loan) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoanDashboardScreen(loanId: loan.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: loan.color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  loan.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loan.companyName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${loan.address}, ${loan.location}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Disbursed',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '${(loan.disbursed * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Actions',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '${loan.actions}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    loan.status,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: loan.status == 'On Track'
                          ? const Color(0xFF16A34A)
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = index == _selectedNavIndex;
    return GestureDetector(
      onTap: () => _onNavItemTap(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF6366F1) : Colors.grey[600],
              size: 24,
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 2,
                width: 20,
                color: const Color(0xFF6366F1),
              ),
          ],
        ),
      ),
    );
  }
}
