import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class Notification {
  final String title;
  final String message;
  final DateTime time;
  bool isRead;

  Notification({
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
  });
}

class UserSettings {
  String name;
  String email;
  String phone;
  String role;

  UserSettings({
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });
}

class DrawRequest {
  final String lineItem;
  bool inspected;
  double? draw1;
  double? draw2;
  double? draw3;

  DrawRequest({
    required this.lineItem,
    required this.inspected,
    this.draw1,
    this.draw2,
    this.draw3,
  });

  double get totalDrawn => (draw1 ?? 0) + (draw2 ?? 0) + (draw3 ?? 0);
}

class LoanDashboardScreen extends StatefulWidget {
  const LoanDashboardScreen({super.key, required String loanId});

  @override
  State<LoanDashboardScreen> createState() => _LoanDashboardScreenState();
}

class _LoanDashboardScreenState extends State<LoanDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DrawRequest? _selectedRequest;

  final List<Notification> _notifications = [
    Notification(
      title: 'New Draw Request',
      message: 'Foundation work draw request submitted',
      time: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Notification(
      title: 'Inspection Complete',
      message: 'Framing inspection has been completed',
      time: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Notification(
      title: 'Payment Processed',
      message: 'Draw payment for electrical work processed',
      time: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  UserSettings _userSettings = UserSettings(
    name: 'Thomas Chappell',
    email: 'thomas@bigt.com',
    phone: '678-999-8212',
    role: 'Contractor',
  );

  final List<DrawRequest> _drawRequests = [
    DrawRequest(
      lineItem: 'Foundation Work',
      inspected: true,
      draw1: 15000,
      draw2: 25000,
    ),
    DrawRequest(
      lineItem: 'Framing',
      inspected: true,
      draw1: 30000,
    ),
    DrawRequest(
      lineItem: 'Electrical',
      inspected: false,
      draw1: 12000,
    ),
    DrawRequest(
      lineItem: 'Plumbing',
      inspected: true,
      draw1: 8000,
      draw2: 10000,
    ),
    DrawRequest(
      lineItem: 'HVAC Installation',
      inspected: false,
      draw1: 20000,
    ),
    DrawRequest(
      lineItem: 'Roofing',
      inspected: true,
      draw1: 25000,
    ),
    DrawRequest(
      lineItem: 'Interior Finishing',
      inspected: false,
      draw1: 18000,
    ),
  ];

  List<DrawRequest> get filteredRequests {
    if (_searchQuery.isEmpty) return _drawRequests;
    return _drawRequests
        .where((request) =>
            request.lineItem.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  double get totalDisbursed {
    return _drawRequests.fold(0, (sum, request) => sum + request.totalDrawn);
  }

  double get projectCompletion {
    int completedItems = _drawRequests.where((r) => r.inspected).length;
    return (completedItems / _drawRequests.length) * 100;
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Notifications'),
            TextButton(
              onPressed: () {
                setState(() {
                  for (var notification in _notifications) {
                    notification.isRead = true;
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('Mark all as read'),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          height: 300,
          child: ListView.builder(
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              final notification = _notifications[index];
              return ListTile(
                leading: Icon(
                  notification.isRead
                      ? Icons.notifications_none
                      : Icons.notifications_active,
                  color: notification.isRead ? Colors.grey : Colors.blue,
                ),
                title: Text(notification.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification.message),
                    Text(
                      '${notification.time.day}/${notification.time.month}/${notification.time.year} ${notification.time.hour}:${notification.time.minute}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                onTap: () {
                  setState(() {
                    notification.isRead = true;
                  });
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showUserConfig() {
    final nameController = TextEditingController(text: _userSettings.name);
    final emailController = TextEditingController(text: _userSettings.email);
    final phoneController = TextEditingController(text: _userSettings.phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Configuration'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  icon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  icon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  icon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _userSettings.role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  icon: Icon(Icons.work),
                ),
                items: ['Contractor', 'Inspector', 'Admin']
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _userSettings.role = value!;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _userSettings = UserSettings(
                  name: nameController.text,
                  email: emailController.text,
                  phone: phoneController.text,
                  role: _userSettings.role,
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.notifications_active),
                title: const Text('Email Notifications'),
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Dark Mode'),
                trailing: Switch(
                  value: false,
                  onChanged: (value) {},
                ),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                trailing: DropdownButton<String>(
                  value: 'English',
                  items: ['English', 'Spanish', 'French']
                      .map((lang) => DropdownMenuItem(
                            value: lang,
                            child: Text(lang),
                          ))
                      .toList(),
                  onChanged: (value) {},
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDrawEditDialog(DrawRequest request, int drawNumber) {
    final controller = TextEditingController(
        text: drawNumber == 1
            ? request.draw1?.toString()
            : drawNumber == 2
                ? request.draw2?.toString()
                : request.draw3?.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Draw $drawNumber'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: '\$',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                final amount = double.tryParse(controller.text);
                switch (drawNumber) {
                  case 1:
                    request.draw1 = amount;
                    break;
                  case 2:
                    request.draw2 = amount;
                    break;
                  case 3:
                    request.draw3 = amount;
                    break;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 14),
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search by name, loan #, etc...',
          hintStyle: const TextStyle(
            fontSize: 14,
            color: Color.fromARGB(255, 107, 7, 7),
          ),
          prefixIcon: const Icon(Icons.search,
              size: 20, color: Color.fromARGB(255, 154, 203, 7)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: Color.fromARGB(255, 209, 206, 14)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: Color.fromARGB(255, 0, 13, 162)),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildProgressCircle({
    required double percentage,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        height: 130,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              height: 80,
              width: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: percentage / 100,
                    strokeWidth: 8,
                    backgroundColor: color.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                  Text(
                    '${percentage.toInt()}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  if (label == 'Amount Disbursed')
                    Text(
                      '\$${totalDisbursed.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNav() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.home, color: Colors.white),
            label: const Text(
              'Home',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _showNotifications,
            icon: Stack(
              children: [
                const Icon(Icons.notifications, color: Colors.white),
                if (_notifications.any((n) => !n.isRead))
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
              ],
            ),
            label: const Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _showUserConfig,
            icon: const Icon(Icons.person, color: Colors.white),
            label: const Text(
              'User Config',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _showSettings,
            icon: const Icon(Icons.settings, color: Colors.white),
            label: const Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({required String count, required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              count,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildSearchBar(),
          ),
          const Text(
            "BIG T",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Text(
            "Construction",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _userSettings.name,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          Text(
            _userSettings.phone,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          _buildSidebarItem(count: "2", label: "Draw Requests"),
          _buildSidebarItem(count: "6", label: "Inspections"),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text, {bool isFirst = false}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.only(left: isFirst ? 16 : 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(String text,
      {bool isFirst = false, bool isAmount = false}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.only(left: isFirst ? 16 : 8),
        child: Text(
          isAmount ? '\$${double.parse(text).toStringAsFixed(2)}' : text,
          style: TextStyle(
            fontSize: 14,
            color: isAmount ? Colors.green[700] : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildEditableTableCell(String text,
      {bool isFirst = false, bool isAmount = false, VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.only(left: isFirst ? 16 : 8),
          child: Text(
            isAmount ? '\$${double.parse(text).toStringAsFixed(2)}' : text,
            style: TextStyle(
              fontSize: 14,
              color: isAmount ? Colors.green[700] : Colors.black87,
              decoration: onTap != null ? TextDecoration.underline : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  _buildTableHeader('Line Item', isFirst: true),
                  _buildTableHeader('INSP'),
                  _buildTableHeader('Draw 1'),
                  _buildTableHeader('Draw 2'),
                  _buildTableHeader('Draw 3'),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: filteredRequests.length,
                itemBuilder: (context, index) {
                  final item = filteredRequests[index];
                  return InkWell(
                    onTap: () => setState(() => _selectedRequest = item),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _selectedRequest == item
                            ? Colors.blue.withOpacity(0.1)
                            : null,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildTableCell(item.lineItem, isFirst: true),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                item.inspected = !item.inspected;
                              }),
                              child: Container(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(
                                  item.inspected
                                      ? Icons.check_circle
                                      : Icons.warning,
                                  color: item.inspected
                                      ? Colors.green
                                      : Colors.orange,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          _buildEditableTableCell(item.draw1?.toString() ?? '-',
                              isAmount: item.draw1 != null,
                              onTap: () => _showDrawEditDialog(item, 1)),
                          _buildEditableTableCell(item.draw2?.toString() ?? '-',
                              isAmount: item.draw2 != null,
                              onTap: () => _showDrawEditDialog(item, 2)),
                          _buildEditableTableCell(item.draw3?.toString() ?? '-',
                              isAmount: item.draw3 != null,
                              onTap: () => _showDrawEditDialog(item, 3)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTopNav(),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSidebar(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildProgressCircle(
                              percentage: (totalDisbursed / 200000) * 100,
                              label: 'Amount Disbursed',
                              color: const Color(0xFFE91E63),
                            ),
                            const SizedBox(width: 16),
                            _buildProgressCircle(
                              percentage: projectCompletion,
                              label: 'Project Completion',
                              color: const Color.fromARGB(255, 51, 7, 163),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDataTable(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
