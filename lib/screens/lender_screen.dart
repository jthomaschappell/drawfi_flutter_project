import 'package:flutter/material.dart';
import 'package:tester/screens/loan_dashboard_screen.dart';
import 'package:tester/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
                    // Add Draw Requests button here
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DrawRequestsView(
                              userProfile: userProfile,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('View Draw Requests'),
                    ),
                    const SizedBox(
                      height: 8.0,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        
                        print("The 'view loan dashboard' was pressed");

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoanDashboardScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('View Loan Dashboard'),
                    ),
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

// Add DrawRequestsView below
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
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(200, 224, 251, 252),
      appBar: AppBar(
        title: const Text('Draw Requests'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadPaymentApplications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final applications = snapshot.data ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final app = applications[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text('Application #${app['application_number']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app['project_name']),
                      Text('Contractor: ${app['contractor_name']}'),
                      Text('Amount: \$${app['current_payment_due']}'),
                    ],
                  ),
                  trailing: _buildStatusChip(app['status']),
                  onTap: () => _showDetails(app),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: color),
      ),
    );
  }

  void _showDetails(Map<String, dynamic> application) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Application #${application['application_number']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Project: ${application['project_name']}'),
              Text('Contractor: ${application['contractor_name']}'),
              Text('Owner: ${application['owner']}'),
              Text('Amount: \$${application['current_payment_due']}'),
              const SizedBox(height: 16),
              if (application['status'] == 'submitted')
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          _updateStatus(application['id'], 'approved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Approve'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          _updateStatus(application['id'], 'rejected'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Reject'),
                    ),
                  ],
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

  Future<void> _updateStatus(String id, String status) async {
    try {
      await _supabase
          .from('payment_applications')
          .update({'status': status}).eq('id', id);

      setState(() {});
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Application ${status.toUpperCase()}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _loadPaymentApplications() async {
    final response = await _supabase
        .from('payment_applications')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
