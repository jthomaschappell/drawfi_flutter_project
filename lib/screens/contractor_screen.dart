import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tester/screens/draw_request_screen.dart';

class ContractorScreen extends StatelessWidget {
  final Map<String, dynamic> userProfile;

  const ContractorScreen({
    super.key,
    this.userProfile = const {
      'full_name': 'John Doe',
      'email': 'johndoe@example.com',
      'user_role': 'contractor',
    },
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
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
                <stop stop-color="#FF1970"/><stop offset="0.145" stop-color="#E81766"/>
                <stop offset="0.307358" stop-color="#DB12AF"/><stop offset="0.43385" stop-color="#BF09D5"/>
                <stop offset="0.556871" stop-color="#A200FA"/><stop offset="0.698313" stop-color="#6500E9"/>
                <stop offset="0.855" stop-color="#3C17DB"/><stop offset="1" stop-color="#2800D7"/>
                </linearGradient></defs></svg>''',
              ),
            ),
            actions: [
              CircleAvatar(
                backgroundColor: const Color(0xFF6500E9).withOpacity(0.1),
                child: Text(
                  userProfile['full_name']?[0] ?? 'U',
                  style: TextStyle(
                    color: const Color(0xFF6500E9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Hello, ${userProfile['full_name']?.split(' ')[0]}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'What would you like to do today?',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildQuickActions(context),
                  const SizedBox(height: 32),
                  _buildDrawHistory(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6500E9).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add_chart,
                  color: Color(0xFF6500E9),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const DrawRequestScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6500E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'New Draw Request',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  Widget _buildDrawHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Draws',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to full history
              },
              child: Text(
                'See All',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDrawItem(
          date: 'Mar 15, 2024',
          amount: '\$25,000',
          status: 'Pending',
          statusColor: Colors.orange,
        ),
        _buildDrawItem(
          date: 'Mar 1, 2024',
          amount: '\$30,000',
          status: 'Completed',
          statusColor: Colors.green,
        ),
        _buildDrawItem(
          date: 'Feb 15, 2024',
          amount: '\$28,000',
          status: 'Completed',
          statusColor: Colors.green,
        ),
      ],
    );
  }

  Widget _buildDrawItem({
    required String date,
    required String amount,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6500E9).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.receipt_outlined,
              color: Color(0xFF6500E9),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  amount,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
