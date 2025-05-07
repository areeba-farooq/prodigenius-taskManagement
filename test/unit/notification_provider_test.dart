import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskgenius/models/notification.dart';
import 'package:taskgenius/models/task.dart';

// Mock classes
class MockTask extends Mock implements Task {
  @override
  final String id;
  @override
  final String title;
  @override
  final String priority;

  MockTask({required this.id, required this.title, this.priority = 'Medium'});
}

// A simplified test notification class
class TestNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String? taskId;
  final NotificationType type;
  bool isRead;

  TestNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.taskId,
    required this.type,
    this.isRead = false,
  });
}

// A simplified version of NotificationProvider for testing
class TestNotificationProvider extends ChangeNotifier {
  List<TestNotification> notifications = [];

  int get unreadCount => notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;

  // Add a notification
  void addNotification(TestNotification notification) {
    notifications.add(notification);
    notifyListeners();
  }

  // Clear all notifications
  void clearAll() {
    notifications.clear();
    notifyListeners();
  }

  // Count notifications by type
  int countNotificationsByType(NotificationType type) {
    return notifications.where((n) => n.type == type).length;
  }

  // Count unread notifications by type
  int getUnreadCountByType(NotificationType type) {
    return notifications.where((n) => n.type == type && !n.isRead).length;
  }

  // Mark a notification as read
  void markAsRead(String notificationId) {
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !notifications[index].isRead) {
      notifications[index].isRead = true;
      notifyListeners();
    }
  }

  // Mark all as read
  void markAllAsRead() {
    for (var notification in notifications) {
      notification.isRead = true;
    }
    notifyListeners();
  }

  // Create and add a task reminder notification
  void addTaskReminderNotification(Task task) {
    String title;
    if (task.priority == 'High') {
      title = '🔴 High Priority Task Reminder';
    } else if (task.priority == 'Medium') {
      title = '🟠 Task Reminder';
    } else {
      title = '🟢 Task Reminder';
    }

    final notification = TestNotification(
      id: 'reminder-${task.id}-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: '${task.title} is due soon!',
      timestamp: DateTime.now(),
      taskId: task.id,
      type: NotificationType.task,
    );

    addNotification(notification);
  }

  // Create and add a deadline notification
  void addDeadlineNotification(Task task) {
    final notification = TestNotification(
      id: 'deadline-${task.id}-${DateTime.now().millisecondsSinceEpoch}',
      title: '⏰ Task Deadline',
      body: '${task.title} is due now!',
      timestamp: DateTime.now(),
      taskId: task.id,
      type: NotificationType.deadline,
    );

    addNotification(notification);
  }

  // Create and add a daily digest notification
  void addDigestNotification(int totalTasks, int highPriorityTasks) {
    String body = 'You have $totalTasks tasks today';

    if (highPriorityTasks > 0) {
      body +=
          ', including $highPriorityTasks high priority ${highPriorityTasks == 1 ? 'task' : 'tasks'}.';
    } else {
      body += '.';
    }

    final notification = TestNotification(
      id: 'digest-${DateTime.now().millisecondsSinceEpoch}',
      title: '📋 Today\'s Tasks',
      body: body,
      timestamp: DateTime.now(),
      type: NotificationType.digest,
    );

    addNotification(notification);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestNotificationProvider notificationProvider;

  setUp(() {
    // Set up shared preferences for testing
    SharedPreferences.setMockInitialValues({});

    // Initialize the test provider
    notificationProvider = TestNotificationProvider();
  });

  group('Notification Provider Tests', () {
    test('Initial values should be empty', () {
      expect(notificationProvider.notifications, isEmpty);
      expect(notificationProvider.unreadCount, equals(0));
      expect(notificationProvider.hasUnread, isFalse);
    });

    test('Adding notification should update lists and counts', () {
      // Arrange
      final notification = TestNotification(
        id: 'test-1',
        title: 'Test Title',
        body: 'Test Body',
        timestamp: DateTime.now(),
        type: NotificationType.task,
      );

      // Act
      notificationProvider.addNotification(notification);

      // Assert
      expect(notificationProvider.notifications.length, equals(1));
      expect(notificationProvider.unreadCount, equals(1));
      expect(notificationProvider.hasUnread, isTrue);
    });

    test('clearAll should reset all values', () {
      // Arrange - Add some test data
      notificationProvider.addNotification(
        TestNotification(
          id: 'test-1',
          title: 'Test Title',
          body: 'Test Body',
          timestamp: DateTime.now(),
          type: NotificationType.task,
        ),
      );

      // Act
      notificationProvider.clearAll();

      // Assert
      expect(notificationProvider.notifications, isEmpty);
      expect(notificationProvider.unreadCount, equals(0));
    });

    test('markAsRead should update isRead and unreadCount', () {
      // Arrange
      final notification = TestNotification(
        id: 'test-1',
        title: 'Test Title',
        body: 'Test Body',
        timestamp: DateTime.now(),
        type: NotificationType.task,
      );
      notificationProvider.addNotification(notification);

      // Act
      notificationProvider.markAsRead('test-1');

      // Assert
      expect(notificationProvider.notifications[0].isRead, isTrue);
      expect(notificationProvider.unreadCount, equals(0));
    });

    test('markAllAsRead should update all notifications', () {
      // Arrange
      notificationProvider.addNotification(
        TestNotification(
          id: 'test-1',
          title: 'Test 1',
          body: 'Test Body',
          timestamp: DateTime.now(),
          type: NotificationType.task,
        ),
      );
      notificationProvider.addNotification(
        TestNotification(
          id: 'test-2',
          title: 'Test 2',
          body: 'Test Body',
          timestamp: DateTime.now(),
          type: NotificationType.deadline,
        ),
      );

      // Act
      notificationProvider.markAllAsRead();

      // Assert
      expect(notificationProvider.notifications[0].isRead, isTrue);
      expect(notificationProvider.notifications[1].isRead, isTrue);
      expect(notificationProvider.unreadCount, equals(0));
    });
  });

  group('Notification Type Tests', () {
    test('countNotificationsByType should return correct count', () {
      // Arrange
      final now = DateTime.now();
      notificationProvider.addNotification(
        TestNotification(
          id: 'test-1',
          title: 'Task 1',
          body: 'Test Body',
          timestamp: now,
          type: NotificationType.task,
        ),
      );
      notificationProvider.addNotification(
        TestNotification(
          id: 'test-2',
          title: 'Task 2',
          body: 'Test Body',
          timestamp: now,
          type: NotificationType.task,
        ),
      );
      notificationProvider.addNotification(
        TestNotification(
          id: 'test-3',
          title: 'Deadline',
          body: 'Test Body',
          timestamp: now,
          type: NotificationType.deadline,
        ),
      );

      // Act & Assert
      expect(
        notificationProvider.countNotificationsByType(NotificationType.task),
        equals(2),
      );
      expect(
        notificationProvider.countNotificationsByType(
          NotificationType.deadline,
        ),
        equals(1),
      );
      expect(
        notificationProvider.countNotificationsByType(NotificationType.digest),
        equals(0),
      );
    });

    test('getUnreadCountByType should return correct count', () {
      // Arrange
      final now = DateTime.now();
      notificationProvider.addNotification(
        TestNotification(
          id: 'test-1',
          title: 'Task 1',
          body: 'Test Body',
          timestamp: now,
          type: NotificationType.task,
        ),
      );

      final readNotification = TestNotification(
        id: 'test-2',
        title: 'Task 2',
        body: 'Test Body',
        timestamp: now,
        type: NotificationType.task,
      );
      readNotification.isRead = true;
      notificationProvider.addNotification(readNotification);

      // Act & Assert
      expect(
        notificationProvider.getUnreadCountByType(NotificationType.task),
        equals(1),
      );
      expect(notificationProvider.unreadCount, equals(1));
    });
  });

  group('Task Notification Tests', () {
    test('addTaskReminderNotification should create correct notification', () {
      // Arrange
      final task = MockTask(
        id: 'task-1',
        title: 'Complete Project',
        priority: 'High',
      );

      // Act
      notificationProvider.addTaskReminderNotification(task);

      // Assert
      expect(notificationProvider.notifications.length, equals(1));
      expect(
        notificationProvider.notifications[0].title,
        contains('High Priority'),
      );
      expect(
        notificationProvider.notifications[0].body,
        contains('Complete Project'),
      );
      expect(notificationProvider.notifications[0].taskId, equals('task-1'));
      expect(
        notificationProvider.notifications[0].type,
        equals(NotificationType.task),
      );
    });

    test('addDeadlineNotification should create correct notification', () {
      // Arrange
      final task = MockTask(id: 'task-2', title: 'Submit Report');

      // Act
      notificationProvider.addDeadlineNotification(task);

      // Assert
      expect(notificationProvider.notifications.length, equals(1));
      expect(notificationProvider.notifications[0].title, contains('Deadline'));
      expect(
        notificationProvider.notifications[0].body,
        contains('Submit Report'),
      );
      expect(notificationProvider.notifications[0].taskId, equals('task-2'));
      expect(
        notificationProvider.notifications[0].type,
        equals(NotificationType.deadline),
      );
    });

    test('addDigestNotification should create correct notification', () {
      // Act
      notificationProvider.addDigestNotification(5, 2);

      // Assert
      expect(notificationProvider.notifications.length, equals(1));
      expect(
        notificationProvider.notifications[0].title,
        contains('Today\'s Tasks'),
      );
      expect(notificationProvider.notifications[0].body, contains('5 tasks'));
      expect(
        notificationProvider.notifications[0].body,
        contains('2 high priority'),
      );
      expect(
        notificationProvider.notifications[0].type,
        equals(NotificationType.digest),
      );
    });
  });
}
