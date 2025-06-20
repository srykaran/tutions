import 'package:flutter/material.dart';
import '../../../constants/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String? _selectedBatch;
  String? _selectedType;

  final List<String> _batches = [
    'All Batches',
    'Morning Batch',
    'Afternoon Batch',
    'Evening Batch',
  ];

  final List<String> _notificationTypes = [
    'All Types',
    'Fee Reminder',
    'Homework',
    'Attendance',
    'General',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Show send notification dialog
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Send Notification'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Filters
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedBatch,
                    decoration: const InputDecoration(
                      labelText: 'Select Batch',
                      prefixIcon: Icon(Icons.class_),
                    ),
                    items: _batches.map((batch) {
                      return DropdownMenuItem(
                        value: batch,
                        child: Text(batch),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBatch = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Notification Type',
                      prefixIcon: Icon(Icons.notifications),
                    ),
                    items: _notificationTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Notifications List
            Expanded(
              child: ListView.builder(
                itemCount: 15, // Dummy data
                itemBuilder: (context, index) {
                  final types = [
                    'Fee Reminder',
                    'Homework',
                    'Attendance',
                    'General',
                  ];
                  final messages = [
                    'Fee payment due for March 2024',
                    'New homework assigned for Mathematics',
                    'Attendance report for today',
                    'Parent-teacher meeting scheduled',
                  ];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getNotificationColor(types[index % types.length]).withOpacity(0.1),
                        child: Icon(
                          _getNotificationIcon(types[index % types.length]),
                          color: _getNotificationColor(types[index % types.length]),
                        ),
                      ),
                      title: Text(types[index % types.length]),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(messages[index % messages.length]),
                          const SizedBox(height: 4),
                          Text(
                            '${DateTime.now().subtract(Duration(hours: index)).hour}:${DateTime.now().subtract(Duration(hours: index)).minute}',
                            style: const TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          // Delete notification
                        },
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

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'Fee Reminder':
        return AppTheme.errorColor;
      case 'Homework':
        return AppTheme.primaryColor;
      case 'Attendance':
        return AppTheme.secondaryColor;
      case 'General':
        return AppTheme.accentColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'Fee Reminder':
        return Icons.payments;
      case 'Homework':
        return Icons.assignment;
      case 'Attendance':
        return Icons.calendar_today;
      case 'General':
        return Icons.notifications;
      default:
        return Icons.notifications;
    }
  }
} 