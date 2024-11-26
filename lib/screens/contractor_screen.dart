import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tester/services/auth_service.dart';
import 'package:tester/screens/draw_request_form.dart';

class ContractorScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const ContractorScreen({
    super.key,
    required this.userProfile,
  });

  @override
  State<ContractorScreen> createState() => _ContractorScreenState();
}

class _ContractorScreenState extends State<ContractorScreen> {
  String get welcomeMessage {
    String fullName = widget.userProfile['full_name'] ?? '';
    String userRole = widget.userProfile['user_role'] ?? '';

    if (fullName.isEmpty) return 'Welcome!';
    return 'Welcome, ${userRole.capitalize()}: $fullName!';
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      backgroundColor: const Color.fromARGB(200, 255, 186, 8),
      appBar: AppBar(
        title: const Text('Contractor Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: authService.signOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                welcomeMessage,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _buildProfileCard(context),
              const SizedBox(height: 20),
              _buildQuickActionsCard(context),
              const SizedBox(height: 20),
              _buildRecentDrawsCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
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
              final value = widget.userProfile[fieldName];
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

  Widget _buildQuickActionsCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DrawRequestForm(),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDrawsCard(BuildContext context) {
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
            const Text(
              'Recent Draw Requests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadRecentDrawRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final draws = snapshot.data ?? [];
                if (draws.isEmpty) {
                  return const Center(
                    child: Text('No recent draw requests'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: draws.length,
                  itemBuilder: (context, index) {
                    final draw = draws[index];
                    return _buildDrawRequestCard(context, draw);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawRequestCard(
      BuildContext context, Map<String, dynamic> draw) {
    final status = draw['status'] ?? 'pending';
    final amount = draw['total_requested_amount'] ?? 0.0;
    final date = DateTime.parse(draw['submission_date'] ?? draw['created_at']);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('Draw Request #${draw['id']}'),
        subtitle:
            Text('Submitted on ${date.toLocal().toString().split('.')[0]}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              status.toUpperCase(),
              style: TextStyle(
                color: _getStatusColor(status),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        onTap: () {
          // TODO: Implement draw request details navigation
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadRecentDrawRequests() async {
    try {
      final response = await Supabase.instance.client
          .from('draw_requests')
          .select()
          .eq('contractor_id', widget.userProfile['contractor_id'])
          .order('created_at', ascending: false)
          .limit(5);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading draw requests: $e');
      return [];
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
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
