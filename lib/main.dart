import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tester/screens/contractor_screen.dart';
import 'package:tester/screens/inspector_screen.dart';
import 'package:tester/screens/lender_screen.dart';

// project specific import
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  print("This is the supabase url: $supabaseUrl");
  print("This is the supabase anon key: $supabaseAnonKey");

  // Check if any required environment variables are null
  if (supabaseUrl == null || supabaseAnonKey == null) {
    // CHANGE WAS MADE HERE
    throw Exception(
        "Supabase configuration error: SUPABASE_URL or SUPABASE_ANON_KEY is missing.");
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    debug: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E1F),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1F35),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const AuthPage(),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
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
        const SnackBar(
            content: Text('Password must be at least 8 characters')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        // /**
        //  * TODO:
        //  * IDEA:
        //  * Take the role out of the authService.signUp()
        //  */
        role: _selectedRole,
        /**
         * TODO: 
         * Try adding something to the database without "data" parameters.
         */
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
                  /**
                   * TODO: 
                   * Test that all is the same after 
                   * this new refactoring. 
                   */
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
          .from('user_profiles')
          .select()
          .eq('id', userId)
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

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "There was an error!",
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
      ),
    );
  }
}

bool isValidEmail(String emailText) {
  final emailPattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailPattern.hasMatch(emailText);
}
