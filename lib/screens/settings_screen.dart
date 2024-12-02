import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart';

// Gradient Text Widget
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    required this.gradient,
    this.style,
  });

  final String text;
  final TextStyle? style;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final Map userProfile;

  const SettingsScreen({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
  String _userName = 'Loading...';
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _loadSettingsFromDatabase();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSettingsFromDatabase() async {
    try {
      setState(() => _isLoading = true);

      final response = await Supabase.instance.client
          .from('user_settings')
          .select()
          .eq('user_id', widget.userProfile['id'])
          .maybeSingle();

      if (response != null) {
        setState(() {
          _isDarkMode = response['dark_mode'] ?? false;
          _notificationsEnabled = response['notifications_enabled'] ?? true;
          _selectedLanguage = response['language'] ?? 'English';
          _userName = response['username'] ??
              widget.userProfile['full_name'] ??
              'Unknown User';
        });
      } else {
        await _createDefaultSettings();
      }
    } catch (error) {
      print('Error loading settings: $error');
      _showError('Error loading settings');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createDefaultSettings() async {
    try {
      await Supabase.instance.client.from('user_settings').insert({
        'user_id': widget.userProfile['id'],
        'dark_mode': false,
        'notifications_enabled': true,
        'language': 'English',
        'username': widget.userProfile['full_name'] ?? 'Unknown User',
      });
      await _loadSettingsFromDatabase();
    } catch (error) {
      print('Error creating default settings: $error');
      _showError('Error creating settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator(radius: 14))
          : CustomScrollView(
              slivers: [
                // Modern App Bar with Gradient
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  stretch: true,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFF1970), Color(0xFF6500E9)],
                        ),
                      ),
                      child: SafeArea(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),
                              // Profile Avatar with Gradient Initial
                              Hero(
                                tag: 'profile_avatar',
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: GradientText(
                                      _userName[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF1970),
                                          Color(0xFF6500E9),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _userName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Settings Content
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildSettingsSection(
                            title: 'Preferences',
                            children: [
                              _buildModernSwitch(
                                icon: CupertinoIcons.moon_fill,
                                title: 'Dark Mode',
                                value: _isDarkMode,
                                onChanged: (value) {
                                  setState(() => _isDarkMode = value);
                                  _updateSetting('dark_mode', value);
                                },
                              ),
                              _buildModernSwitch(
                                icon: CupertinoIcons.bell_fill,
                                title: 'Notifications',
                                value: _notificationsEnabled,
                                onChanged: (value) {
                                  setState(() => _notificationsEnabled = value);
                                  _updateSetting(
                                      'notifications_enabled', value);
                                },
                              ),
                              _buildLanguageSelector(),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildSettingsSection(
                            title: 'Account',
                            children: [
                              _buildSettingsTile(
                                icon: CupertinoIcons.lock_fill,
                                title: 'Change Password',
                                onTap: () {
                                  // Implement password change
                                },
                              ),
                              _buildSettingsTile(
                                icon: CupertinoIcons.person_fill,
                                title: 'Edit Profile',
                                onTap: () {
                                  // Implement profile editing
                                },
                              ),
                              _buildSettingsTile(
                                icon: CupertinoIcons.square_arrow_right,
                                title: 'Sign Out',
                                isDestructive: true,
                                onTap: _handleSignOut,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildModernSwitch({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF6500E9)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF6500E9),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isDestructive ? Colors.red : const Color(0xFF6500E9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDestructive ? Colors.red : null,
                  ),
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: Colors.grey.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              CupertinoIcons.globe,
              size: 20,
              color: Color(0xFF6500E9),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Language',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                Text(
                  _selectedLanguage,
                  style: const TextStyle(
                    color: Color(0xFF6500E9),
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: Color(0xFF6500E9),
                ),
              ],
            ),
            onPressed: () => _showLanguagePicker(),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select Language'),
        actions: ['English', 'Spanish', 'French'].map((language) {
          return CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedLanguage = language);
              Navigator.pop(context);
              _updateSetting('language', language);
            },
            child: Text(language),
            isDefaultAction: language == _selectedLanguage,
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
          isDestructiveAction: true,
        ),
      ),
    );
  }

  Future<void> _handleSignOut() async {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
            isDefaultAction: true,
          ),
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Supabase.instance.client.auth.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const AuthScreen(),
                    ),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  _showError('Error signing out: ${e.toString()}');
                }
              }
            },
            child: const Text('Sign Out'),
            isDestructiveAction: true,
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      await Supabase.instance.client
          .from('user_settings')
          .update({key: value}).eq('user_id', widget.userProfile['id']);
    } catch (e) {
      if (mounted) {
        _showError('Error updating settings: ${e.toString()}');
      }
    }
  }

  Future<void> _updateProfile(Map<String, dynamic> data) async {
    try {
      await Supabase.instance.client
          .from('user_profiles')
          .update(data)
          .eq('id', widget.userProfile['id']);

      await _loadSettingsFromDatabase();
    } catch (e) {
      if (mounted) {
        _showError('Error updating profile: ${e.toString()}');
      }
    }
  }

  Future<void> _showProfileEditDialog() async {
    final nameController = TextEditingController(text: _userName);

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Edit Profile'),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: CupertinoTextField(
            controller: nameController,
            placeholder: 'Enter your name',
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(
                color: CupertinoColors.systemGrey4,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
            isDefaultAction: true,
          ),
          CupertinoDialogAction(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(context);
                await _updateProfile({'full_name': newName});
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPasswordChangeDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Change Password'),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              CupertinoTextField(
                controller: currentPasswordController,
                placeholder: 'Current Password',
                obscureText: true,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: newPasswordController,
                placeholder: 'New Password',
                obscureText: true,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: confirmPasswordController,
                placeholder: 'Confirm New Password',
                obscureText: true,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
            isDefaultAction: true,
          ),
          CupertinoDialogAction(
            onPressed: () async {
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                _showError('New passwords do not match');
                return;
              }
              try {
                // Implement password change logic here
                Navigator.pop(context);
              } catch (e) {
                _showError('Error changing password: ${e.toString()}');
              }
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }
}
