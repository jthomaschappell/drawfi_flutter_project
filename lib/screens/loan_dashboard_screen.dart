import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tester/screens/lender_screen.dart';

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
  String? draw1Status;
  String? draw2Status;
  String? draw3Status;

  DrawRequest({
    required this.lineItem,
    required this.inspected,
    this.draw1,
    this.draw2,
    this.draw3,
    this.draw1Status = 'pending',
    this.draw2Status = 'pending',
    this.draw3Status = 'pending',
  });

  double get totalDrawn => (draw1 ?? 0) + (draw2 ?? 0) + (draw3 ?? 0);
}

class ChatMessage {
  final String sender;
  final String message;
  final DateTime timestamp;
  final String role;
  final String? avatarUrl;

  ChatMessage({
    required this.sender,
    required this.message,
    required this.timestamp,
    required this.role,
    this.avatarUrl,
  });
}

class ChatSection extends StatefulWidget {
  const ChatSection({super.key});

  @override
  State<ChatSection> createState() => _ChatSectionState();
}

class _ChatSectionState extends State<ChatSection> {
  final TextEditingController _messageController = TextEditingController();
  String _selectedChat = 'contractor'; // 'contractor' or 'inspector'

  final Map<String, List<ChatMessage>> _chats = {
    'contractor': [
      ChatMessage(
        sender: 'Thomas Chappell',
        message: 'Hi Sarah, do you have a moment to discuss the timeline?',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        role: 'Contractor',
        avatarUrl: 'TC',
      ),
      ChatMessage(
        sender: 'Sarah Lender',
        message: 'Of course, what would you like to know?',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        role: 'Lender',
        avatarUrl: 'SL',
      ),
    ],
    'inspector': [
      ChatMessage(
        sender: 'John Inspector',
        message: 'Sarah, I noticed some concerns with the electrical work.',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        role: 'Inspector',
        avatarUrl: 'JI',
      ),
      ChatMessage(
        sender: 'Sarah Lender',
        message: 'Can you provide more details?',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        role: 'Lender',
        avatarUrl: 'SL',
      ),
    ],
  };

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'contractor':
        return Colors.blue;
      case 'inspector':
        return Colors.green;
      case 'lender':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildMessage(ChatMessage message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getRoleColor(message.role).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  message.avatarUrl ?? message.sender[0],
                  style: TextStyle(
                    color: _getRoleColor(message.role),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 2.0),
                    child: Text(
                      message.sender,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.blue[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      color: isMe ? Colors.blue[900] : Colors.black87,
                      fontSize: 13,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2.0, left: 4.0),
                  child: Text(
                    '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildChatSelector() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(child: _buildChatTab('Contractor', 'contractor')),
          Expanded(child: _buildChatTab('Inspector', 'inspector')),
        ],
      ),
    );
  }

  Widget _buildChatTab(String label, String chatId) {
    final isSelected = _selectedChat == chatId;
    return GestureDetector(
      onTap: () => setState(() => _selectedChat = chatId),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.grey[600],
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = _chats[_selectedChat] ?? [];
    return Container(
      height: 359, // 240 + 189 (5cm in pixels)
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _buildChatSelector(),
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[messages.length - 1 - index];
                final isMe = message.role == 'Lender';
                return _buildMessage(message, isMe);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText:
                          'Message ${_selectedChat.substring(0, 1).toUpperCase()}${_selectedChat.substring(1)}...',
                      hintStyle:
                          TextStyle(color: Colors.grey[400], fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, size: 20),
                  color: Colors.blue,
                  onPressed: () {
                    if (_messageController.text.isNotEmpty) {
                      setState(() {
                        _chats[_selectedChat]!.add(ChatMessage(
                          sender: 'Sarah Lender',
                          message: _messageController.text,
                          timestamp: DateTime.now(),
                          role: 'Lender',
                          avatarUrl: 'SL',
                        ));
                        _messageController.clear();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

/**
 * TODO:
 * DELETE THIS MESSAGE WHEN YOU ARE DONE: 
 * Print out the loan ID. 
 */
class LoanDashboardScreen extends StatefulWidget {
  final String loanId;

  const LoanDashboardScreen({super.key, required this.loanId});

  @override
  State<LoanDashboardScreen> createState() => _LoanDashboardScreenState();
}

class _LoanDashboardScreenState extends State<LoanDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DrawRequest? _selectedRequest;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 20,
        ), // Increased padding
        child: Column(
          children: [
            _buildTopNav(),
            const SizedBox(
              height: 20,
            ), // Increased spacing
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSidebar(),
                  const SizedBox(width: 24), // Increased spacing
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
                            const SizedBox(width: 24), // Increased spacing
                            _buildProgressCircle(
                              percentage: projectCompletion,
                              label: 'Project Completion',
                              color: const Color.fromARGB(255, 51, 7, 163),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24), // Increased spacing
                        Expanded(
                          child: _buildDataTable(),
                        ),
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
      draw1Status: 'pending',
      draw2Status: 'pending',
    ),
    DrawRequest(
      lineItem: 'Framing',
      inspected: true,
      draw1: 30000,
      draw1Status: 'pending',
    ),
    DrawRequest(
      lineItem: 'Electrical',
      inspected: false,
      draw1: 12000,
      draw1Status: 'pending',
    ),
    DrawRequest(
      lineItem: 'Plumbing',
      inspected: true,
      draw1: 8000,
      draw2: 10000,
      draw1Status: 'pending',
      draw2Status: 'pending',
    ),
    DrawRequest(
      lineItem: 'HVAC Installation',
      inspected: false,
      draw1: 20000,
      draw1Status: 'pending',
    ),
    DrawRequest(
      lineItem: 'Roofing',
      inspected: true,
      draw1: 25000,
      draw1Status: 'pending',
    ),
    DrawRequest(
      lineItem: 'Interior Finishing',
      inspected: false,
      draw1: 18000,
      draw1Status: 'pending',
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

  void _updateDrawStatus(DrawRequest item, int drawNumber, String status) {
    setState(() {
      switch (drawNumber) {
        case 1:
          item.draw1Status = status;
          break;
        case 2:
          item.draw2Status = status;
          break;
        case 3:
          item.draw3Status = status;
          break;
      }
    });
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
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: 'Search by name, loan #, etc...',
          hintStyle: const TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: Colors.black,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildDrawStatusWidget(DrawRequest item, int drawNumber) {
    String? status;
    double? amount;

    switch (drawNumber) {
      case 1:
        status = item.draw1Status;
        amount = item.draw1;
        break;
      case 2:
        status = item.draw2Status;
        amount = item.draw2;
        break;
      case 3:
        status = item.draw3Status;
        amount = item.draw3;
        break;
    }

    if (amount == null) {
      return const Expanded(child: SizedBox());
    }

    Color getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'approved':
          return Colors.green;
        case 'declined':
          return Colors.red;
        case 'pending':
        default:
          return Colors.orange;
      }
    }

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Status text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: getStatusColor(status ?? 'pending').withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status?.toUpperCase() ?? 'PENDING',
              style: TextStyle(
                color: getStatusColor(status ?? 'pending'),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (status?.toLowerCase() == 'pending') const SizedBox(height: 4),
          // Action buttons
          if (status?.toLowerCase() == 'pending')
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: Colors.green,
                  onPressed: () =>
                      _updateDrawStatus(item, drawNumber, 'approved'),
                  tooltip: 'Approve',
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.cancel_outlined),
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: Colors.red,
                  onPressed: () =>
                      _updateDrawStatus(item, drawNumber, 'declined'),
                  tooltip: 'Decline',
                ),
              ],
            ),
        ],
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
        height: 140, // Increased height
        padding: const EdgeInsets.symmetric(
            horizontal: 28, vertical: 20), // Increased padding
        decoration: BoxDecoration(
          color: color.withOpacity(0.17),
          borderRadius: BorderRadius.circular(16), // Increased radius
        ),
        child: Row(
          children: [
            SizedBox(
              height: 110, // Increased size
              width: 130, // Increased size
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 110,
                    width: 110,
                    child: CircularProgressIndicator(
                      value: percentage / 100,
                      strokeWidth: 10, // Increased stroke width
                      backgroundColor: color.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  Text(
                    '${percentage.toInt()}%',
                    style: const TextStyle(
                      fontSize: 20, // Increased font size
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18, // Increased font size
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  if (label == 'Amount Disbursed')
                    Text(
                      '\$${totalDisbursed.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16, // Increased font size
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
              color: const Color.fromARGB(255, 208, 205, 205),
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

  Widget _buildTableHeader(String text, {bool isFirst = false}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.only(left: isFirst ? 16 : 78),
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
          padding: EdgeInsets.only(left: isFirst ? 16 : 68),
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
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 25),
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
          // Table content
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: filteredRequests.length,
              itemBuilder: (context, index) {
                final item = filteredRequests[index];
                return Container(
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildTableCell(item.lineItem, isFirst: true),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'INSP',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Icon(
                              item.inspected
                                  ? Icons.check_circle
                                  : Icons.warning,
                              color:
                                  item.inspected ? Colors.green : Colors.orange,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                      _buildEditableTableCell(
                        item.draw1?.toString() ?? '-',
                        isAmount: item.draw1 != null,
                        onTap: () => _showDrawEditDialog(item, 1),
                      ),
                      _buildEditableTableCell(
                        item.draw2?.toString() ?? '-',
                        isAmount: item.draw2 != null,
                        onTap: () => _showDrawEditDialog(item, 2),
                      ),
                      _buildEditableTableCell(
                        item.draw3?.toString() ?? '-',
                        isAmount: item.draw3 != null,
                        onTap: () => _showDrawEditDialog(item, 3),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Status lines at the bottom
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                // Empty space for Line Item and INSP columns
                Expanded(flex: 2, child: Container()),
                // Draw 1 Status
                Expanded(child: _buildVerticalDrawStatus(1)),
                // Draw 2 Status
                Expanded(child: _buildVerticalDrawStatus(2)),
                // Draw 3 Status
                Expanded(child: _buildVerticalDrawStatus(3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDrawStatus(int drawNumber) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.check_circle_outline),
          iconSize: 16,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          color: Colors.green,
          onPressed: () => _approveVerticalDraw(drawNumber),
          tooltip: 'Approve Draw $drawNumber',
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'PENDING',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.cancel_outlined),
          iconSize: 16,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          color: Colors.red,
          onPressed: () => _declineVerticalDraw(drawNumber),
          tooltip: 'Decline Draw $drawNumber',
        ),
      ],
    );
  }

  void _approveVerticalDraw(int drawNumber) {
    setState(() {
      for (var item in _drawRequests) {
        switch (drawNumber) {
          case 1:
            if (item.draw1 != null) item.draw1Status = 'approved';
            break;
          case 2:
            if (item.draw2 != null) item.draw2Status = 'approved';
            break;
          case 3:
            if (item.draw3 != null) item.draw3Status = 'approved';
            break;
        }
      }
    });
  }

  void _declineVerticalDraw(int drawNumber) {
    setState(() {
      for (var item in _drawRequests) {
        switch (drawNumber) {
          case 1:
            if (item.draw1 != null) item.draw1Status = 'declined';
            break;
          case 2:
            if (item.draw2 != null) item.draw2Status = 'declined';
            break;
          case 3:
            if (item.draw3 != null) item.draw3Status = 'declined';
            break;
        }
      }
    });
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildSearchBar(),
          ),
          const Text(
            "BIG T",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const Text(
            "Construction Loan",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _userSettings.name,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          Text(
            _userSettings.phone,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          _buildSidebarItem(count: "2", label: "Draw Requests"),
          _buildSidebarItem(count: "6", label: "Inspections"),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: ChatSection(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTopNav() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Row(
              children: [
                SvgPicture.string(
                  '''<svg width="32" height="32" viewBox="0 0 1531 1531" fill="none" xmlns="http://www.w3.org/2000/svg">
                <rect width="1531" height="1531" rx="200" fill="url(#paint0_linear_82_170)"/>
                <ellipse cx="528" cy="429.5" rx="136.5" ry="136" transform="rotate(-90 528 429.5)" fill="white"/>
                <circle cx="528" cy="1103" r="136" transform="rotate(-90 528 1103)" fill="white"/>
                <circle cx="1001" cy="773" r="136" fill="white"/>
                <ellipse cx="528" cy="774" rx="29" ry="28" fill="white"/>
                <ellipse cx="808" cy="494" rx="29" ry="28" fill="white"/>
                <ellipse cx="808" cy="1038.5" rx="29" ry="29.5" fill="white"/>
                <defs>
                <linearGradient id="paint0_linear_82_170" x1="1485.07" y1="0.00010633" x2="30.6199" y2="1485.07" gradientUnits="userSpaceOnUse">
                <stop stop-color="#FF1970"/><stop offset="0.145" stop-color="#E81766"/>
                <stop offset="0.307358" stop-color="#DB12AF"/><stop offset="0.43385" stop-color="#BF09D5"/>
                <stop offset="0.556871" stop-color="#A200FA"/><stop offset="0.698313" stop-color="#6500E9"/>
                <stop offset="0.855" stop-color="#3C17DB"/><stop offset="1" stop-color="#2800D7"/>
                </linearGradient></defs></svg>''',
                  width: 32,
                  height: 32,
                ),
                const SizedBox(width: 24),
                _buildNavItem(
                  icon: Icons.home_outlined,
                  isActive: true,
                  onTap: () => Navigator.of(context).pop(),
                ),
                _buildNavItem(
                  icon: Icons.settings_outlined,
                  onTap: _showSettings,
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Icon(
          icon,
          color: isActive ? const Color(0xFF6500E9) : Colors.grey[600],
          size: 24,
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
