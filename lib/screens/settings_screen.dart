import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Map userProfile;

  const SettingsScreen({super.key, required this.userProfile});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Notification Settings
  bool _drawRequestAlerts = true;
  bool _inspectionReportAlerts = true;
  bool _budgetOverageAlerts = true;
  bool _completionUpdateAlerts = true;
  
  // Approval Settings
  bool _requireInspectionForApproval = true;
  bool _requireInvoicesForApproval = true;
  bool _requireW9ForApproval = true;

  // View Settings
  String _defaultView = 'Active Projects';
  bool _showCompletedProjects = false;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettingsFromDatabase();
  }

  Future<void> _loadSettingsFromDatabase() async {
    try {
      setState(() => _isLoading = true);

      final response = await Supabase.instance.client
          .from('lender_settings')
          .select()
          .eq('user_id', widget.userProfile['id'])
          .maybeSingle();

      if (response != null) {
        setState(() {
          _drawRequestAlerts = response['draw_request_alerts'] ?? true;
          _inspectionReportAlerts = response['inspection_report_alerts'] ?? true;
          _budgetOverageAlerts = response['budget_overage_alerts'] ?? true;
          _completionUpdateAlerts = response['completion_update_alerts'] ?? true;
          _requireInspectionForApproval = response['require_inspection_approval'] ?? true;
          _requireInvoicesForApproval = response['require_invoices_approval'] ?? true;
          _requireW9ForApproval = response['require_w9_approval'] ?? true;
          _defaultView = response['default_view'] ?? 'Active Projects';
          _showCompletedProjects = response['show_completed_projects'] ?? false;
        });
      } else {
        await _createDefaultSettings();
      }
    } catch (error) {
      _showError('Error loading settings');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createDefaultSettings() async {
    try {
      await Supabase.instance.client.from('lender_settings').insert({
        'user_id': widget.userProfile['id'],
        'draw_request_alerts': true,
        'inspection_report_alerts': true,
        'budget_overage_alerts': true,
        'completion_update_alerts': true,
        'require_inspection_approval': true,
        'require_invoices_approval': true,
        'require_w9_approval': true,
        'default_view': 'Active Projects',
        'show_completed_projects': false,
      });
      await _loadSettingsFromDatabase();
    } catch (error) {
      _showError('Error creating settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF1A1F36),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1F36)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Section
                      _buildSettingsSection(
                        'Profile Information',
                        [
                          _buildProfileInfo('Name', widget.userProfile['full_name'] ?? 'N/A'),
                          _buildProfileInfo('Institution', widget.userProfile['institution'] ?? 'N/A'),
                          _buildProfileInfo('Role', 'Construction Lender'),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Notification Settings
                      _buildSettingsSection(
                        'Notifications',
                        [
                          _buildSwitchTile(
                            'Draw Request Alerts',
                            'Get notified when new draw requests are submitted',
                            _drawRequestAlerts,
                            (value) {
                              setState(() => _drawRequestAlerts = value);
                              _updateSetting('draw_request_alerts', value);
                            },
                          ),
                          _buildSwitchTile(
                            'Inspection Report Alerts',
                            'Get notified when new inspection reports are filed',
                            _inspectionReportAlerts,
                            (value) {
                              setState(() => _inspectionReportAlerts = value);
                              _updateSetting('inspection_report_alerts', value);
                            },
                          ),
                          _buildSwitchTile(
                            'Budget Overage Alerts',
                            'Get notified when project expenses exceed budget limits',
                            _budgetOverageAlerts,
                            (value) {
                              setState(() => _budgetOverageAlerts = value);
                              _updateSetting('budget_overage_alerts', value);
                            },
                          ),
                          _buildSwitchTile(
                            'Completion Updates',
                            'Get notified of project completion milestone updates',
                            _completionUpdateAlerts,
                            (value) {
                              setState(() => _completionUpdateAlerts = value);
                              _updateSetting('completion_update_alerts', value);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Approval Requirements
                      _buildSettingsSection(
                        'Approval Requirements',
                        [
                          _buildSwitchTile(
                            'Require Inspection',
                            'Require inspection reports before approving draw requests',
                            _requireInspectionForApproval,
                            (value) {
                              setState(() => _requireInspectionForApproval = value);
                              _updateSetting('require_inspection_approval', value);
                            },
                          ),
                          _buildSwitchTile(
                            'Require Invoices',
                            'Require supplier invoices for draw request approval',
                            _requireInvoicesForApproval,
                            (value) {
                              setState(() => _requireInvoicesForApproval = value);
                              _updateSetting('require_invoices_approval', value);
                            },
                          ),
                          _buildSwitchTile(
                            'Require W-9',
                            'Require W-9 forms for new contractors',
                            _requireW9ForApproval,
                            (value) {
                              setState(() => _requireW9ForApproval = value);
                              _updateSetting('require_w9_approval', value);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // View Preferences
                      _buildSettingsSection(
                        'View Preferences',
                        [
                          _buildDropdownTile(
                            'Default View',
                            'Set your default project view',
                            _defaultView,
                            ['Active Projects', 'Pending Approvals', 'All Projects'],
                            (value) {
                              setState(() => _defaultView = value!);
                              _updateSetting('default_view', value);
                            },
                          ),
                          _buildSwitchTile(
                            'Show Completed Projects',
                            'Display completed projects in project list',
                            _showCompletedProjects,
                            (value) {
                              setState(() => _showCompletedProjects = value);
                              _updateSetting('show_completed_projects', value);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Security Section
                      _buildSettingsSection(
                        'Security',
                        [
                          _buildActionTile(
                            'Change Password',
                            'Update your account password',
                            onTap: () {
                              // Implement password change
                            },
                          ),
                          _buildActionTile(
                            'Sign Out',
                            'Log out of your account',
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
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1F36),
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProfileInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A1F36),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1F36),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF6500E9),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1F36),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: value,
            items: options.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: onChanged,
            style: const TextStyle(
              color: Color(0xFF1A1F36),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle, {
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? Colors.red : const Color(0xFF1A1F36),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      await Supabase.instance.client
          .from('lender_settings')
          .update({key: value})
          .eq('user_id', widget.userProfile['id']);
    } catch (e) {
      if (mounted) {
        _showError('Error updating settings');
      }
    }
  }

  Future<void> _handleSignOut() async {
    final shouldSignOut = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      try {
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          _showError('Error signing out');
        }
      }
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}