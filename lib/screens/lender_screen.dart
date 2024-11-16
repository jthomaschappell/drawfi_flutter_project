import 'package:flutter/material.dart';
import 'package:tester/services/auth_service.dart';

class LenderScreen extends StatelessWidget {
  final Map<String, dynamic> userProfile;

  const LenderScreen({
    super.key,
    required this.userProfile,
  });

  String get welcomeMessage {
    String fullName = userProfile['full_name'] ?? '';
    String userRole = userProfile['user_role'] ?? '';

    if (fullName.isEmpty) return 'Welcome!';
    return 'Welcome, ${userRole.capitalize()}: $fullName!';
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      backgroundColor: const Color.fromARGB(200, 224, 251, 252),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Text(
                      welcomeMessage,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildProfileCard(context),
                    const SizedBox(height: 20),
                    _buildDrawRequestButton(context),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: authService.signOut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawRequestButton(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DrawRequestsView(userProfile: userProfile),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Icon(
                Icons.description,
                size: 48,
                color: Colors.blue,
              ),
              const SizedBox(height: 12),
              Text(
                'View Draw Requests',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Review and manage payment applications',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    // Your existing _buildProfileCard implementation
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Information',
              style: Theme.of(context).textTheme.headlineSmall,
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
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

  String _formatFieldName(String name) {
    return name
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

// Keep your existing StringExtension
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

// Create a new widget for the Draw Requests view
class DrawRequestsView extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const DrawRequestsView({
    super.key,
    required this.userProfile,
  });

  @override
  State<DrawRequestsView> createState() => _DrawRequestsViewState();
}

class _DrawRequestsViewState extends State<DrawRequestsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(200, 224, 251, 252),
      appBar: AppBar(
        title: const Text('Draw Requests'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          // Add your DrawRequestsView content here
          // This is where you'll implement the payment applications view
        ),
      ),
    );
  }
}
