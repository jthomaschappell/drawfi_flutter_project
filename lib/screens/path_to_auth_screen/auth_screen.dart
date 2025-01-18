import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tester/screens/contractor_home_screen.dart';
import 'package:tester/screens/error_screen.dart';
import 'package:tester/screens/inspector_screen.dart';
import 'package:tester/screens/lender_home_screen.dart';
import 'package:tester/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final supabase = Supabase.instance.client;
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();

  bool isLoading = false;
  bool isSignUpPage = false;
  UserRole _selectedRole = UserRole.lender;

  final Map<UserRole, String> roleLabels = {
    UserRole.lender: 'Lender',
    UserRole.contractor: 'Contractor',
    UserRole.inspector: 'Inspector',
  };

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<AuthState>(
        stream: _authService.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.data?.session != null) {
            return _buildAuthenticatedScreen(snapshot.data!.session!.user.id);
          }

          // Center content with max width for larger screens
          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _buildAuthScreen(isSmallScreen),
            ),
          );
        },
      ),
    );
  }

  /// TODO:
  /// 12.17.2024
  /// This function is a work in progress.
  /// When we are done with it, it will go into the auth_service.dart?
  void _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showErrorSnackbar('Please enter your email address');
      return;
    }

    setState(() => isLoading = true);

    try {
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.flutter://reset-callback/',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset link sent to $email'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Failed to send reset link: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildAuthScreen(bool isSmallScreen) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 24 : 32,
            vertical: isSmallScreen ? 20 : 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: isSmallScreen ? 40 : 60),
              Center(child: _buildLogo()),
              SizedBox(height: isSmallScreen ? 40 : 60),
              Text(
                isSignUpPage ? 'Create Account' : 'Sign In',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSignUpPage
                    ? 'Enter your details to get started'
                    : 'Welcome back',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),
              if (isSignUpPage) ...[
                _buildTextField(
                  controller: _fullNameController,
                  label: 'Full Name',
                ),
                const SizedBox(height: 16),
              ],
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                obscureText: true,
              ),
              if (!isSignUpPage) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isLoading ? null : _handleForgotPassword,
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
              if (isSignUpPage) ...[
                const SizedBox(height: 24),
                _buildRoleSelector(),
              ],
              const SizedBox(height: 32),
              _buildSubmitButton(),
              const SizedBox(height: 16),
              _buildAuthToggle(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black, // Make input text black
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF5F5F5), // Light gray background
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6500E9), width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Your Role',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...roleLabels.entries
            .map((entry) => _buildRoleOption(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildRoleOption(UserRole role, String label) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6500E9) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading ? null : _handleAuth,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF6500E9),
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
                isSignUpPage ? 'Create Account' : 'Sign In',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildAuthToggle() {
    return Center(
      // child: TextButton(
      //   onPressed: isLoading
      //       ? null
      //       : () => setState(() => isSignUpPage = !isSignUpPage),
      //   child: Text(
      //     isSignUpPage
      //         ? 'Already have an account? Sign In'
      //         : 'Don\'t have an account? Sign Up',
      //     style: TextStyle(
      //       color: Colors.grey[800],
      //       fontSize: 14,
      //     ),
      //   ),
      // ),
    );
  }

  Widget _buildLogo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.string(
          '''
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
        ''',
          height: 80,
          width: 80,
        ),
        const SizedBox(height: 12), // Space between logo and text
        const Text(
          "DrawFi",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6500E9),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthenticatedScreen(String userId) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserProfile(userId),
      builder: (context, profileSnapshot) {
        if (profileSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF6500E9),
            ),
          );
        }

        final userProfile = profileSnapshot.data;
        print("Profile snapshot data is ${profileSnapshot.data}");

        if (userProfile == null) {
          print("User profile is null");
          return const ErrorScreen();
        }

        switch (userProfile['user_role']?.toString().toLowerCase() ?? '') {
          case 'contractor':
            return ContractorScreen(userProfile: userProfile);
          case 'lender':
            return LenderScreen(userProfile: userProfile);
          case 'inspector':
            return InspectorScreen(userProfile: userProfile);
          default:
            print("Unknown role: ${userProfile['user_role']}");
            return const ErrorScreen();
        }
      },
    );
  }

  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      print(
          "Fetching profile for userId (happens inside of _getUserProfile): $userId");

      // Get basic user info
      final userResponse =
          await supabase.from('users').select().eq('user_id', userId).single();

      // print(
      //   "(Inside of getUserProfile, we grab this from the 'users' table) Basic user info: $userResponse",
      // );
      // Determine role by checking each table
      try {
        // Check lenders table
        final lenderCheck = await supabase
            .from('lenders')
            .select()
            .eq('lender_id', userId)
            .single();
        // print("Found lender role (inside function getUserProfile)");
        return {...userResponse, 'user_role': 'lender'};
      } catch (e) {
        // Not a lender, continue checking
      }

      try {
        // Check contractors table
        final contractorCheck = await supabase
            .from('contractors')
            .select()
            .eq('contractor_id', userId)
            .single();
        print("Found contractor role (inside function getUserProfile)");
        return {...userResponse, 'user_role': 'contractor'};
      } catch (e) {
        // Not a contractor, continue checking
      }

      try {
        // Check inspectors table
        final inspectorCheck = await supabase
            .from('inspectors')
            .select()
            .eq('inspector_id', userId)
            .single();
        print("Found inspector role (inside function getUserProfile)");
        return {...userResponse, 'user_role': 'inspector'};
      } catch (e) {
        // Not an inspector
        print("No role found for user");
      }

      // If no role found, return user info with null role
      print("No role found in any table (inside function getUserProfile)");
      return {...userResponse, 'user_role': null};
    } catch (e) {
      print(
          "Error fetching user profile: $e. (inside function getUserProfile)");
      return null;
    }
  }

  Future<void> _handleAuth() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        (isSignUpPage && _fullNameController.text.isEmpty)) {
      _showErrorSnackbar('Please fill in all fields');
      return;
    }

    setState(() => isLoading = true);

    try {
      if (isSignUpPage) {
        // 1. Create auth user
        print("Attempting to create new user");
        final AuthResponse res = await supabase.auth.signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            data: {
              'full_name': _fullNameController.text.trim(),
            });

        if (res.user == null) throw Exception('User creation failed');

        final userId = res.user!.id;
        final now = DateTime.now().toIso8601String();

        // 2. Create user profile (with user_role field now)
        await supabase.from('users').insert({
          'user_id': userId,
          'name': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'user_role': _selectedRole
              .toString()
              .split('.')
              .last
              .toLowerCase(), // Added this line
          'created_at': now,
          'updated_at': now,
        });

// Create user_profile (keep this part as is)
        await supabase.from('user_profiles').insert({
          'id': userId,
          'full_name': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'user_role': _selectedRole.toString().split('.').last.toLowerCase(),
          'created_at': now,
          'updated_at': now,
        });

        // 3. Insert into role-specific table based on role
        switch (_selectedRole) {
          case UserRole.lender:
            await supabase.from('lenders').insert({
              'lender_id': userId,
              'name': _fullNameController.text.trim(),
              'email': _emailController.text.trim(),
              'created_at': now,
              'updated_at': now,
            });
            break;

          case UserRole.contractor:
            await supabase.from('contractors').insert({
              'contractor_id': userId,
              'name': _fullNameController.text.trim(),
              'email': _emailController.text.trim(),
              'created_at': now,
              'updated_at': now,
            });
            break;

          case UserRole.inspector:
            await supabase.from('inspectors').insert({
              'inspector_id': userId,
              'name': _fullNameController.text.trim(),
              'email': _emailController.text.trim(),
              'created_at': now,
              'updated_at': now,
            });
            break;
          case UserRole.borrower:
          // : Handle this case.
        }

        // 4. Sign out after successful registration
        await supabase.auth.signOut();

        // 5. Clear form fields
        _emailController.clear();
        _passwordController.clear();
        _fullNameController.clear();

        // 6. Switch to sign in page
        if (mounted) {
          setState(() {
            isSignUpPage = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please sign in.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Handle sign in
        print("Attempting to sign in user: ${_emailController.text.trim()}");
        final AuthResponse res = await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (res.user == null) throw Exception('Login failed');
        print("Successfully signed in user (Auth list): ${res.user!.id}");
      }
    } catch (e) {
      print("Error in auth process: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    print("ERROR MESSAGE: $message");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }
}
