import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  task, 
  deadline, 
  digest, 
  scheduled, 
  achievement,
}
class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String? taskId; 
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

  
  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'],
      title: map['title'],
      body: map['body'],
      
          timestamp: (map['timestamp'] as Timestamp).toDate(), 

      taskId: map['taskId'],
      isRead: map['isRead'] ?? false,
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => NotificationType.task,
      ),
    );
  }

  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      
          'timestamp': Timestamp.fromDate(timestamp), 

      'taskId': taskId,
      'isRead': isRead,
      'type': type.toString().split('.').last,
    };
  }
}

