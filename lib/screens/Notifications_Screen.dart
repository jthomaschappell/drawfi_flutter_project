import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'New Draw Request',
      'message': 'Foundation work draw request submitted.',
      'time': DateTime.now().subtract(const Duration(hours: 2)),
      'isRead': false,
      'type': 'request',
    },
    {
      'title': 'Inspection Complete',
      'message': 'Framing inspection has been completed.',
      'time': DateTime.now().subtract(const Duration(days: 1)),
      'isRead': false,
      'type': 'success',
    },
    {
      'title': 'Payment Processed',
      'message': 'Draw payment for electrical work processed.',
      'time': DateTime.now().subtract(const Duration(days: 2)),
      'isRead': true,
      'type': 'payment',
    },
  ];

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
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'request':
        return const Color(0xFF6500E9);
      case 'success':
        return const Color(0xFF34D399);
      case 'payment':
        return const Color(0xFFFBBF24);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'request':
        return CupertinoIcons.doc_text_fill;
      case 'success':
        return CupertinoIcons.checkmark_circle_fill;
      case 'payment':
        return CupertinoIcons.money_dollar_circle_fill;
      default:
        return CupertinoIcons.bell_fill;
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['isRead'] = true;
      }
    });
    _showSuccessMessage('All notifications marked as read');
  }

  void _markAsRead(int index) {
    setState(() {
      _notifications[index]['isRead'] = true;
    });
    _showSuccessMessage('Notification marked as read');
  }

  void _showSuccessMessage(String message) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        content: Row(
          children: [
            const Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: Color(0xFF34D399),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Color(0xFF1F2937)),
              ),
            ),
          ],
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.of(context).pop();
    });
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          color: const Color(0xFF6500E9),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Mark all read',
              style: TextStyle(
                color: _notifications.any((n) => !n['isRead'])
                    ? const Color(0xFF6500E9)
                    : Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed:
                _notifications.any((n) => !n['isRead']) ? _markAllAsRead : null,
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.bell_slash,
                      size: 48,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: () async {
                    // Implement refresh logic
                    await Future.delayed(const Duration(seconds: 1));
                  },
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final notification = _notifications[index];
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: Offset(0, index * 0.1),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: _animationController,
                                curve: Curves.easeOut,
                              ),
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
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
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      if (!notification['isRead']) {
                                        _markAsRead(index);
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: _getNotificationColor(
                                                notification['type'],
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              _getNotificationIcon(
                                                notification['type'],
                                              ),
                                              color: _getNotificationColor(
                                                notification['type'],
                                              ),
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      notification['title'],
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            notification[
                                                                    'isRead']
                                                                ? FontWeight
                                                                    .w500
                                                                : FontWeight
                                                                    .w600,
                                                        color: const Color(
                                                            0xFF1F2937),
                                                      ),
                                                    ),
                                                    Text(
                                                      _formatTime(
                                                          notification['time']),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[500],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  notification['message'],
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                if (!notification[
                                                    'isRead']) ...[
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: const Color(
                                                              0xFF6500E9),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: _notifications.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
