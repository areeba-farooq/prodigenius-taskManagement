//******************************************* */

// lib/screens/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:taskgenius/models/notification.dart';
import 'package:taskgenius/state/notification_provider.dart';
import 'package:taskgenius/state/task_provider.dart';
import 'package:taskgenius/screens/task_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();

    // Update the last viewed timestamp when the screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).updateLastViewed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final notifications = notificationProvider.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notificationProvider.hasUnread)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Mark all as read',
              onPressed: () => notificationProvider.markAllAsRead(),
            ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear all',
            onPressed: () => _confirmClearAll(context, notificationProvider),
          ),
        ],
      ),
      body:
          notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _buildNotificationItem(context, notification);
                },
              ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see your task reminders, deadlines,\nand daily digests here',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    AppNotification notification,
  ) {
    // Format timestamp as relative time (e.g., "2 hours ago")
    final now = DateTime.now();
    final difference = now.difference(notification.timestamp);
    String timeAgo;

    if (difference.inMinutes < 1) {
      timeAgo = 'Just now';
    } else if (difference.inMinutes < 60) {
      timeAgo = '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      timeAgo = '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      timeAgo = '${difference.inDays}d ago';
    } else {
      timeAgo = DateFormat('MMM d').format(notification.timestamp);
    }

    // Icon based on notification type
    IconData notificationIcon;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.task:
        notificationIcon = Icons.access_time;
        iconColor = Colors.orange;
        break;
      case NotificationType.deadline:
        notificationIcon = Icons.event;
        iconColor = Colors.red;
        break;
      case NotificationType.digest:
        notificationIcon = Icons.article;
        iconColor = Colors.blue;
        break;
      case NotificationType.scheduled:
        notificationIcon = Icons.schedule;
        iconColor = Colors.green;
        break;
    }

    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        // Remove the notification (you should implement this method)
        Provider.of<NotificationProvider>(
          context,
          listen: false,
        ).removeNotification(notification.id);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.2),
            child: Icon(notificationIcon, color: iconColor),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.body),
              const SizedBox(height: 4),
              Text(
                timeAgo,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          isThreeLine: true,
          trailing:
              !notification.isRead
                  ? IconButton(
                    icon: const Icon(Icons.mark_email_read),
                    tooltip: 'Mark as read',
                    onPressed: () {
                      Provider.of<NotificationProvider>(
                        context,
                        listen: false,
                      ).markAsRead(notification.id);
                    },
                  )
                  : null,
          onTap: () {
            // Mark as read when tapped
            if (!notification.isRead) {
              Provider.of<NotificationProvider>(
                context,
                listen: false,
              ).markAsRead(notification.id);
            }

            // Navigate to task details if notification has a task ID
            if (notification.taskId != null) {
              _navigateToTaskDetails(context, notification.taskId!);
            }
          },
        ),
      ),
    );
  }

  void _navigateToTaskDetails(BuildContext context, String taskId) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final task = taskProvider.tasks.firstWhere((task) => task.id == taskId);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
    );
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    NotificationProvider notificationProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear All Notifications'),
            content: const Text(
              'Are you sure you want to clear all notifications? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('CLEAR ALL'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      notificationProvider.clearAll();
    }
  }
}
