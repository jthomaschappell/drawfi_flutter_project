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

  Color _getActionColor(String action) {
    switch (action.toUpperCase()) {
      case 'INSERT':
        return Colors.green.shade100;
      case 'UPDATE':
        return Colors.blue.shade100;
      case 'DELETE':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
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

  Widget _buildDiffText(Map<String, dynamic>? oldData, Map<String, dynamic>? newData) {
    if (oldData == null || newData == null) return const SizedBox.shrink();
    
    List<Widget> changes = [];
    
    // Compare fields that exist in both old and new data
    for (var key in oldData.keys) {
      if (newData.containsKey(key) && oldData[key] != newData[key]) {
        changes.add(
          Text(
            '$key: ${oldData[key]} → ${newData[key]}',
            style: const TextStyle(fontSize: 12),
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
                child: Container(
                  color: _getActionColor(log['action']),
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
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _formatDateTime(changedAt),
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatTableName(log['table_name']),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Record ID: ${log['record_id']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (log['changed_by'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Changed by: ${log['changed_by']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 8),
                        if (log['action'].toUpperCase() == 'UPDATE') ...[
                          const Divider(),
                          const Text(
                            'Changes:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildDiffText(oldData, newData),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}