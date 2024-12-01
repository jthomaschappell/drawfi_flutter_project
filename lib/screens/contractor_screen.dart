// File: contractor_screen.dart
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
      'id': '12345',
      'created_at': '2024-01-01T00:00:00',
      'updated_at': '2024-11-01T12:00:00',
    },
  });

  String get welcomeMessage {
    String fullName = userProfile['full_name'] ?? '';
    String userRole = userProfile['user_role'] ?? '';

    if (fullName.isEmpty) return 'Welcome!';
    return 'Welcome, ${userRole.capitalize()}: $fullName!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 0,
        title: Row(
          children: [
            SvgPicture.string(
              '''
              <svg width="40" height="40" viewBox="0 0 1531 1531" fill="none" xmlns="http://www.w3.org/2000/svg">
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
              height: 40,
              width: 40,
            ),
            const SizedBox(width: 8),
            const Text(
              'Contractor Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Handle logout action
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.deepPurpleAccent,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    welcomeMessage,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildProfileCard(),
              const SizedBox(height: 20),
              _buildQuickActionsCard(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'New Draw',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          // Handle navigation
        },
      ),
    );
  }

  Widget _buildProfileCard() {
    final fieldDisplayOrder = [
      'full_name',
      'email',
      'user_role',
      'id',
      'created_at',
      'updated_at',
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...fieldDisplayOrder.map((fieldName) {
              final value = userProfile[fieldName];
              if (value == null || value.toString().isEmpty) {
                return const SizedBox.shrink();
              }

              String displayValue = value.toString();
              if (fieldName.contains('_at')) {
                final dateTime = DateTime.parse(value.toString());
                displayValue = '${dateTime.toLocal()}'.split('.')[0];
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatFieldName(fieldName),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(displayValue),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DrawRequestScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('New Draw Request'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.deepPurpleAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFieldName(String name) {
    return name
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
