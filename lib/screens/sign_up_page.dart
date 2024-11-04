import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _organizationController = TextEditingController();
  String? _role;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _contactNumberController.dispose();
    _organizationController.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    final email = _emailController.text;
    final password = _passwordController.text;
    final fullName = _fullNameController.text;
    final contactNumber = _contactNumberController.text;
    final organization = _organizationController.text;
    print('Email: $email, Password: $password, Full Name: $fullName, Contact Number: $contactNumber, Organization: $organization, Role: $_role');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1F),
      body: SafeArea(
        child: Stack(
          children: [
            // Background design elements
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.purple.withOpacity(0.1),
                ),
              ),
            ),

            // Main content
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button and logo
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.blue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Drawfi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join Drawfi to access financial solutions',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Form fields
                    _buildTextField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      prefixIcon: const Icon(Icons.person_outline, color: Colors.blue),
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined, color: Colors.blue),
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _contactNumberController,
                      label: 'Contact Number',
                      hint: 'Enter your contact number',
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_outlined, color: Colors.blue),
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _organizationController,
                      label: 'Organization',
                      hint: 'Enter your organization name',
                      prefixIcon: const Icon(Icons.business_outlined, color: Colors.blue),
                    ),
                    const SizedBox(height: 16),

                    _buildDropdown(),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Create a password',
                      obscureText: !_isPasswordVisible,
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.blue),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                          color: Colors.blue,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Sign Up Button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Colors.blue, Colors.purple],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: _handleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login link
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: RichText(
                          text: const TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(color: Colors.grey),
                            children: [
                              TextSpan(
                                text: 'Sign In',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600]),
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonFormField<String>(
        value: _role,
        dropdownColor: const Color(0xFF1A1F35),
        decoration: InputDecoration(
          labelText: 'Role',
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.work_outline, color: Colors.blue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.all(20),
        ),
        style: const TextStyle(color: Colors.white),
        items: const [
          DropdownMenuItem(value: 'GC', child: Text('General Contractor')),
          DropdownMenuItem(value: 'Lender', child: Text('Lender')),
        ],
        onChanged: (value) {
          setState(() {
            _role = value;
          });
        },
        hint: Text('Select your role', style: TextStyle(color: Colors.grey[600])),
      ),
    );
  }
}