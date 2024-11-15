import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tester/services/auth_service.dart';

class LenderScreen extends StatefulWidget {
  final User user;
  const LenderScreen({
    super.key,
    required this.user,
  });

  @override
  State<LenderScreen> createState() => _LenderScreenState();
}

class _LenderScreenState extends State<LenderScreen> {
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

    // Assuming your table has 'first_name' and 'last_name' fields
    // Adjust the field names based on your actual database structure
    String fullName = [userProfile!['full_name'] ?? '']
        .where((name) => name.isNotEmpty)
        .join(' ');

    // If no name is available, return a default message
    return fullName.isEmpty ? 'Welcome!' : 'Welcome, $fullName!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[200], // Lighter green
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                          if (userProfile != null) ...[
                            _buildProfileCard(),
                            const SizedBox(height: 20),
                          ],
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
              // Skip null values and empty strings
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

  String _formatFieldName(String name) {
    // Convert snake_case to Title Case
    return name
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
