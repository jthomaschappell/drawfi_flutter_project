import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tester/main.dart';
import 'package:tester/screens/contractor_screen.dart';
import 'package:tester/screens/error_screen.dart';
import 'package:tester/screens/inspector_screen.dart';
import 'package:tester/screens/lender_screen.dart';
import 'package:tester/services/auth_service.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // service connection.
  final supabase = Supabase.instance.client;
  final _authService = AuthService();

  // form input boilerplate.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();

  bool isLoading = false;
  bool isSignUpPage = false;
  UserRole _selectedRole = UserRole.lender;

  final Map<UserRole, Map<String, String>> roleDetails = {
    UserRole.lender: {
      'label': 'Lender',
      'description': 'Provide funding for construction projects'
    },
    UserRole.contractor: {
      'label': 'Contractor',
      'description': 'Manage and execute construction projects'
    },
    UserRole.inspector: {
      'label': 'Inspector',
      'description': 'Verify and approve construction progress'
    },
  };

  Future<void> _handleSignUp() async {
    print("Sign up was called!");

    // Validation: Ensure all fields are filled in.
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _fullNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    // Validation: Ensure email is valid.
    if (!isValidEmail(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid email address"),
        ),
      );
      return;
    }
    // Validation: Ensure password length is over 8.
    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        role: _selectedRole,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully signed up!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        print("Error: ${e.toString()}");
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleSignIn() async {
    print("Sign in was called!");

    // see if fields are empty.
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // how do we restrict if there is an error.
      // signInWorked boolean???
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        print("Error: ${e.toString()}");
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<AuthState>(
        stream: _authService.authStateChanges(),
        builder: (context, snapshot) {
          /// This gets rendered with a specific page when we log in.
          final snapshotDataSession = snapshot.data?.session;
          if (snapshotDataSession != null) {
            return FutureBuilder<Map<String, dynamic>?>(
              // Get the user id.
              // This is useful for getting the user_role from user_profiles table.
              future: _getUserProfile(snapshotDataSession.user.id),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                final userProfile = profileSnapshot.data;
                // print(userProfile);
                final userRole = userProfile!['user_role'];

                // display a different screen based on the role of the user.
                if (userRole == 'contractor') {
                  return ContractorScreen(
                    userProfile: userProfile,
                  );
                } else if (userRole == 'lender') {
                  return LenderScreen(
                    userProfile: userProfile,
                  );
                } else if (userRole == 'inspector') {
                  return InspectorScreen(
                    userProfile: userProfile,
                  );
                } else {
                  print("The enum is invalid.");
                  return const ErrorScreen();
                }
              },
            );
          }

          /// This block renders ONLY if the snapshot has no session data.
          else {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Auth Test',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    // if it's the sign up page, we add extra fields.
                    // these extra fields are 'Full Name' and 'Role'.
                    if (isSignUpPage) ...[
                      TextField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1F35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Your Role',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...UserRole.values.map(
                              (role) => RadioListTile<UserRole>(
                                title: Text(roleDetails[role]!['label']!),
                                subtitle: Text(
                                  roleDetails[role]!['description']!,
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                                value: role,
                                groupValue: _selectedRole,
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _selectedRole = value);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // these always render. For signup page OR login page.
                    const SizedBox(height: 24),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : (isSignUpPage ? _handleSignUp : _handleSignIn),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isSignUpPage ? 'Sign Up' : 'Sign In',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => setState(() => isSignUpPage = !isSignUpPage),
                      child: Text(
                        isSignUpPage
                            ? 'Already have an account? Sign In'
                            : 'Don\'t have an account? Sign Up',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          bigTestFunction();
                        },
                        child: const Text(
                          "Big Test Button",
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      final data = await supabase
          .from('users')
          .select()
          .eq('user_id', userId)
          .limit(1)
          .single();
      return data;
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }

  void bigTestFunction() async {
    print("The big button was pressed!");
    print("Hello Peter");
    print("Hello Doc Ock");
    String works = "4a47abba-3c39-47bd-b0f3-b7aa2b4fad82";
    String fails = "7f73c0c5-e038-495a";
    final muffins = await _getUserProfile(fails);
    if (muffins == null) {
      print("It's null!");
    } else {
      print("It's not null!");
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }
}

class DashboardScreen extends StatelessWidget {
  final Map<String, dynamic> userProfile;

  const DashboardScreen({
    super.key,
    required this.userProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top Navigation Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  label: 'Home',
                  isSelected: true,
                  onTap: () {},
                ),
                _NavItem(
                  label: 'Notifications',
                  isSelected: false,
                  onTap: () {},
                ),
                _NavItem(
                  label: 'User Config',
                  isSelected: false,
                  onTap: () {},
                ),
                _NavItem(
                  label: 'Settings',
                  isSelected: false,
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Main Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Panel
                  Expanded(
                    flex: 2,
                    child: _LeftPanel(userProfile: userProfile),
                  ),
                  const SizedBox(width: 16),

                  // Right Panel with Progress Indicators and Table
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        // Progress Indicators Row
                        const Row(
                          children: [
                            Expanded(
                              child: _ProgressCard(
                                title: 'Amount Disbursed',
                                percentage: 0.45,
                                color: Colors.pink,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _ProgressCard(
                                title: 'Project Completion',
                                percentage: 0.50,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Table
                        Expanded(
                          child: _DrawTable(),
                        ),
                      ],
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
}

class _NavItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.black54,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _LeftPanel extends StatelessWidget {
  final Map<String, dynamic> userProfile;

  const _LeftPanel({required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        TextField(
          decoration: InputDecoration(
            hintText: 'Search by name, loan #, etc...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Company Info Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BIG T Construction',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Text('Thomas Chappell'),
                const Text('678-999-8212'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Action Buttons
        _ActionButton(
          number: '2',
          label: 'Draw Requests',
          onTap: () {},
        ),
        const SizedBox(height: 8),
        _ActionButton(
          number: '6',
          label: 'Inspections',
          onTap: () {},
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String number;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.number,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Text(number),
            ),
            const SizedBox(width: 16),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String title;
  final double percentage;
  final Color color;

  const _ProgressCard({
    required this.title,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircularPercentIndicator(
              radius: 30.0,
              lineWidth: 8.0,
              percent: percentage,
              progressColor: color,
              backgroundColor: color.withOpacity(0.2),
              center: Text('${(percentage * 100).toInt()}%'),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Line Item')),
            DataColumn(label: Text('INSP')),
            DataColumn(label: Text('Draw 1')),
            DataColumn(label: Text('Draw 2')),
            DataColumn(label: Text('Draw 3')),
          ],
          rows: List.generate(
            8,
            (index) => DataRow(
              cells: [
                DataCell(Text('Item ${index + 1}')),
                const DataCell(Text('-')),
                const DataCell(Text('-')),
                const DataCell(Text('-')),
                const DataCell(Text('-')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
