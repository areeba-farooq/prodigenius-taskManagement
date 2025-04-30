// lib/models/app_notification.dart



// Notification types
enum NotificationType {
  task, // Task due reminder
  deadline, // Task deadline
  digest, // Daily task digest
  scheduled, // AI-scheduled task time
}
class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String? taskId; // Optional task reference
  bool isRead;
  final NotificationType type;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.taskId,
    this.isRead = false,
    required this.type,
  });

  // Create from notification data
  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'],
      title: map['title'],
      body: map['body'],
      timestamp: DateTime.parse(map['timestamp']),
      taskId: map['taskId'],
      isRead: map['isRead'] ?? false,
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => NotificationType.task,
      ),
    );
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'taskId': taskId,
      'isRead': isRead,
      'type': type.toString().split('.').last,
    };
  }
}

