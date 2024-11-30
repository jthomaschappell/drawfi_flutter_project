import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tester/main.dart';
import 'package:tester/screens/contractor_screen.dart';
import 'package:tester/screens/error_screen.dart';
import 'package:tester/screens/inspector_screen.dart';
import 'package:tester/screens/lender_screen.dart';
import 'package:tester/services/auth_service.dart';

// Constants section
const String appLogo = '''
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
''';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool isLoading = false;
  bool isSignUpPage = false;
  bool _isPasswordVisible = false;
  UserRole _selectedRole = UserRole.lender;

  final Map<UserRole, Map<String, dynamic>> roleDetails = {
    UserRole.lender: {
      'label': 'Lender',
      'description': 'Manage construction loans and disbursements',
      'icon': Icons.account_balance,
      'gradient': [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
    },
    UserRole.contractor: {
      'label': 'Contractor',
      'description': 'Submit and track draw requests',
      'icon': Icons.construction,
      'gradient': [const Color(0xFFEC4899), const Color(0xFFDB2777)],
    },
    UserRole.inspector: {
      'label': 'Inspector',
      'description': 'Verify construction progress',
      'icon': Icons.assignment,
      'gradient': [const Color(0xFF10B981), const Color(0xFF059669)],
    },
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  Future<void> _handleSignIn() async {
    if (!_validateInputs(isSignIn: true)) return;

    setState(() => isLoading = true);

    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleSignUp() async {
    if (!_validateInputs()) return;

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
            backgroundColor: Color(0xFF4F46E5),
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
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  bool _validateInputs({bool isSignIn = false}) {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Please fill in all required fields');
      return false;
    }

    if (!isSignIn && _fullNameController.text.trim().isEmpty) {
      _showError('Please enter your full name');
      return false;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(_emailController.text)) {
      _showError('Please enter a valid email address');
      return false;
    }

    if (_passwordController.text.length < 8) {
      _showError('Password must be at least 8 characters long');
      return false;
    }

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: StreamBuilder<AuthState>(
        stream: _authService.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.data?.session != null) {
            return FutureBuilder<Map<String, dynamic>?>(
              future: _getUserProfile(snapshot.data!.session!.user.id),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4F46E5),
                    ),
                  );
                }
                final userProfile = profileSnapshot.data;
                final userRole = userProfile!['user_role'];

                switch (userRole) {
                  case 'contractor':
                    return ContractorScreen(userProfile: userProfile);
                  case 'lender':
                    return LenderScreen(userProfile: userProfile);
                  case 'inspector':
                    return InspectorScreen(userProfile: userProfile);
                  default:
                    return const ErrorScreen();
                }
              },
            );
          }

          return Stack(
            children: [
              // Animated Background Elements
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF4F46E5).withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -150,
                left: -150,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFEC4899).withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Main Layout
              Row(
                children: [
                  // Left Panel - Branding
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(48.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo and Brand Name
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: SvgPicture.string(
                                  appLogo,
                                  width: 32,
                                  height: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                'DrawFi',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),

                          // Main Content
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Streamline Your\nConstruction Finance',
                                  style: TextStyle(
                                    fontSize: 56,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.1,
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Simplify draw requests, accelerate approvals,\nand keep projects moving forward.',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white.withOpacity(0.8),
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),

                          // Stats Section
                          _buildStatCards(),
                        ],
                      ),
                    ),
                  ),

                  // Right Panel - Auth Form
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E293B),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          bottomLeft: Radius.circular(40),
                        ),
                      ),
                      padding: const EdgeInsets.all(48),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              isSignUpPage ? 'Create Account' : 'Welcome Back',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isSignUpPage
                                  ? 'Start streamlining your construction finance'
                                  : 'Sign in to manage your projects',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 48),

                            // Form Fields
                            if (isSignUpPage) ...[
                              _buildTextField(
                                controller: _fullNameController,
                                label: 'Full Name',
                                icon: Icons.person_outline,
                              ),
                              const SizedBox(height: 24),
                              _buildRoleSelector(),
                              const SizedBox(height: 24),
                            ],

                            _buildTextField(
                              controller: _emailController,
                              label: 'Email Address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 24),
                            _buildTextField(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock_outline,
                              isPassword: true,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Action Buttons
                            ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : (isSignUpPage
                                      ? _handleSignUp
                                      : _handleSignIn),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
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
                                      isSignUpPage
                                          ? 'Create Account'
                                          : 'Sign In',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          isSignUpPage = !isSignUpPage;
                                          _emailController.clear();
                                          _passwordController.clear();
                                          _fullNameController.clear();
                                        });
                                      },
                                child: Text(
                                  isSignUpPage
                                      ? 'Already have an account? Sign In'
                                      : 'Don\'t have an account? Sign Up',
                                  style: const TextStyle(
                                    color: Color(0xFF4F46E5),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCards() {
    final stats = [
      {'value': '50%', 'label': 'Faster Approvals'},
      {'value': '100%', 'label': 'Digital Process'},
      {'value': '24/7', 'label': 'Real-time Updates'},
    ];

    return Row(
      children: stats.map((stat) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat['value']!,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  stat['label']!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF242B42),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2D3555),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: Colors.grey[400]),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF242B42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2D3555),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Your Role',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...UserRole.values.map((role) => _buildRoleOption(role)),
        ],
      ),
    );
  }

  Widget _buildRoleOption(UserRole role) {
    final isSelected = _selectedRole == role;
    final gradientColors = roleDetails[role]!['gradient'] as List<Color>;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  gradientColors[0].withOpacity(0.1),
                  gradientColors[1].withOpacity(0.05),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? gradientColors[0] : Colors.transparent,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _selectedRole = role),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSelected
                          ? gradientColors
                          : [
                              const Color(0xFF2D3555),
                              const Color(0xFF2D3555),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    roleDetails[role]!['icon'] as IconData,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        roleDetails[role]!['label'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        roleDetails[role]!['description'] as String,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Radio<UserRole>(
                  value: role,
                  groupValue: _selectedRole,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedRole = value);
                    }
                  },
                  fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                    if (states.contains(MaterialState.selected)) {
                      return gradientColors[0];
                    }
                    return Colors.grey[400]!;
                  }),
                ),
              ],
            ),
          ),
        ),
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
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
