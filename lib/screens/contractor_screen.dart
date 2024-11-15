import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tester/services/auth_service.dart';
import 'package:tester/screens/draw_request_screen.dart';

class ContractorScreen extends StatefulWidget {
  final User user;
  const ContractorScreen({
    super.key,
    required this.user,
  });

  @override
  State<ContractorScreen> createState() => _ContractorScreenState();
}

class _ContractorScreenState extends State<ContractorScreen> {
  final authService = AuthService();
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? userProfile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final data = await supabase
          .from('user_profiles')
          .select()
          .eq('id', widget.user.id)
          .limit(1)
          .single();

      setState(() {
        userProfile = data;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading user profile: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  String get welcomeMessage {
    if (userProfile == null) return 'Welcome!';

    String fullName = [userProfile!['full_name'] ?? '']
        .where((name) => name.isNotEmpty)
        .join(' ');

    return fullName.isEmpty ? 'Welcome!' : 'Welcome, Contractor: $fullName!';
  }

  @override
  Widget build(BuildContext context) {
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                    if (userProfile != null) ...[
                      _buildProfileCard(),
                      const SizedBox(height: 20),
                    ],
                    _buildQuickActionsCard(context),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileCard() {
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
            ...userProfile!.entries.map((entry) {
              if (entry.value == null || entry.value.toString().isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatFieldName(entry.key),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        entry.value.toString(),
                      ),
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