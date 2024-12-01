import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatefulWidget {
  final Map userProfile;

  const SettingsScreen({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
  String _userName = 'Loading...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettingsFromDatabase();
  }

  Future<void> _loadSettingsFromDatabase() async {
    try {
      setState(() => _isLoading = true);

      // Fetch user settings from Supabase
      final response = await Supabase.instance.client
          .from('user_settings')
          .select()
          .eq('user_id', widget.userProfile['id'])
          .maybeSingle();

      if (response != null) {
        // Safely parse response
        setState(() {
          _isDarkMode = response['dark_mode'] ?? false;
          _notificationsEnabled = response['notifications_enabled'] ?? true;
          _selectedLanguage = response['language'] ?? 'English';
          _userName = response['username'] ??
              widget.userProfile['full_name'] ??
              'Unknown User';
        });
      } else {
        // If no record exists, populate defaults and optionally create a record
        await _createDefaultSettings();
      }
    } catch (error) {
      print('Error loading settings: $error');
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
      print('Default settings created successfully.');
    } catch (error) {
      print('Error creating default settings: $error');
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      await Supabase.instance.client
          .from('user_settings')
          .update({key: value}).eq('user_id', widget.userProfile['id']);
      print('$key updated successfully.');
    } catch (error) {
      print('Error updating $key: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4F46E5),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4F46E5),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Branding Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFFFF1970)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _userName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _userName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Customize your app preferences',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Preferences Section
                  const Text(
                    'Preferences',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildListTile(
                    icon: Icons.dark_mode,
                    title: 'Dark Mode',
                    trailing: Switch(
                      value: _isDarkMode,
                      onChanged: (value) {
                        setState(() => _isDarkMode = value);
                        _updateSetting('dark_mode', value);
                      },
                    ),
                  ),
                  _buildListTile(
                    icon: Icons.notifications_active,
                    title: 'Notifications',
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                        _updateSetting('notifications_enabled', value);
                      },
                    ),
                  ),
                  _buildListTile(
                    icon: Icons.language,
                    title: 'Language',
                    trailing: DropdownButton<String>(
                      value: _selectedLanguage,
                      underline: const SizedBox(),
                      items: ['English', 'Spanish', 'French']
                          .map((language) => DropdownMenuItem(
                                value: language,
                                child: Text(language),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedLanguage = value!);
                        _updateSetting('language', value);
                      },
                    ),
                  ),

                  const Divider(height: 32),

                  // Account Section
                  const Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildListTile(
                    icon: Icons.lock,
                    title: 'Change Password',
                    onTap: () {
                      // Add logic for changing password
                    },
                  ),
                  _buildListTile(
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: () {
                      // Add logic for logout
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF4F46E5)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF111827),
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
