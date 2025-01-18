import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _future = Supabase.instance.client
      .from('audit_log')
      .select()
      .order('changed_at', ascending: false)
      .limit(10);

  Widget _getActionIndicator(String action) {
    Color color;
    switch (action.toUpperCase()) {
      case 'INSERT':
        color = Colors.green;
        break;
      case 'UPDATE':
        color = Colors.blue;
        break;
      case 'DELETE':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      width: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown time';
    return DateFormat('MMM d, y h:mm a').format(dateTime.toLocal());
  }

  String _formatTableName(String tableName) {
    return tableName
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Widget _buildChanges(Map<String, dynamic>? oldData, Map<String, dynamic>? newData) {
    if (oldData == null || newData == null) return const SizedBox.shrink();
    
    List<Widget> changes = [];
    
    for (var key in oldData.keys) {
      if (newData.containsKey(key) && oldData[key] != newData[key]) {
        changes.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    key,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${oldData[key]} → ${newData[key]}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: changes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Activity'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: FutureBuilder(
        future: _future,
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final logs = snapshot.data as List;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final DateTime? changedAt = DateTime.tryParse(log['changed_at'] ?? '');
              final oldData = log['old_data'] as Map<String, dynamic>?;
              final newData = log['new_data'] as Map<String, dynamic>?;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 1,
                child: Row(
                  children: [
                    _getActionIndicator(log['action']),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  log['action'].toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  _formatDateTime(changedAt),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatTableName(log['table_name']),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${log['record_id']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (log['changed_by'] != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Modified by: ${log['changed_by']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                            if (log['action'].toUpperCase() == 'UPDATE' && 
                                (oldData?.isNotEmpty ?? false)) ...[
                              const SizedBox(height: 12),
                              const Text(
                                'Changes:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildChanges(oldData, newData),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}