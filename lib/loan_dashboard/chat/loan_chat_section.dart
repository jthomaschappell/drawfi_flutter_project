import 'package:flutter/material.dart';
import 'package:tester/loan_dashboard/models/loan_chat_message.dart';

class LoanChatSection extends StatefulWidget {
  const LoanChatSection({super.key});

  @override
  State<LoanChatSection> createState() => _LoanChatSectionState();
}

class _LoanChatSectionState extends State<LoanChatSection> {
  final TextEditingController _messageController = TextEditingController();
  String _selectedChat = 'contractor'; // 'contractor' or 'inspector'

  final Map<String, List<LoanChatMessage>> _chats = {
    'contractor': [
      LoanChatMessage(
        sender: 'Thomas Chappell',
        message: 'Hi Sarah, do you have a moment to discuss the timeline?',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        role: 'Contractor',
        avatarUrl: 'TC',
      ),
      LoanChatMessage(
        sender: 'Sarah Lender',
        message: 'Of course, what would you like to know?',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        role: 'Lender',
        avatarUrl: 'SL',
      ),
    ],
    'inspector': [
      LoanChatMessage(
        sender: 'John Inspector',
        message: 'Sarah, I noticed some concerns with the electrical work.',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        role: 'Inspector',
        avatarUrl: 'JI',
      ),
      LoanChatMessage(
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

  Widget _buildMessage(LoanChatMessage message, bool isMe) {
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
                        _chats[_selectedChat]!.add(LoanChatMessage(
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