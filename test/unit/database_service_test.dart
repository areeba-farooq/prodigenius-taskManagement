import 'package:flutter_test/flutter_test.dart';
import 'package:taskgenius/models/task.dart';
import 'package:taskgenius/models/notification.dart';
import 'package:taskgenius/models/goal.dart';

void main() {
  group('Task Model Basic Tests', () {
    test('Task creation with minimum properties', () {
      final task = Task(
        id: 'test-id',
        title: 'Simple Task',
        category: 'Work',
        dueDate: DateTime.now(),
        urgencyLevel: 3,
        priority: 'Medium',
        isCompleted: false,
        estimatedDuration: Duration(seconds: 60),
      );

      expect(task.id, equals('test-id'));
      expect(task.title, equals('Simple Task'));
      expect(task.isCompleted, equals(false));
    });

    test('Task.toMap returns a map', () {
      final task = Task(
        id: 'test-id',
        title: 'Simple Task',
        category: 'Work',
        dueDate: DateTime.now(),
        urgencyLevel: 3,
        priority: 'Medium',
        isCompleted: false,
        estimatedDuration: Duration(seconds: 60),
      );

      final map = task.toMap();
      expect(map, isA<Map>());
      expect(map.containsKey('id'), isTrue);
      expect(map.containsKey('title'), isTrue);
    });
  });

  group('Notification Model Basic Tests', () {
    test('AppNotification creation with minimum properties', () {
      final notification = AppNotification(
        id: 'test-id',
        title: 'Test Notification',
        body: 'Test Body',
        timestamp: DateTime.now(),
        type: NotificationType.task,
      );

      expect(notification.id, equals('test-id'));
      expect(notification.title, equals('Test Notification'));
      expect(notification.type, equals(NotificationType.task));
    });

    test('AppNotification.toMap returns a map', () {
      final notification = AppNotification(
        id: 'test-id',
        title: 'Test Notification',
        body: 'Test Body',
        timestamp: DateTime.now(),
        type: NotificationType.task,
      );

      final map = notification.toMap();
      expect(map, isA<Map>());
      expect(map.containsKey('id'), isTrue);
      expect(map.containsKey('title'), isTrue);
    });
  });

  group('Goal Model Basic Tests', () {
    test('Goal creation with minimum properties', () {
      final goal = Goal(
        id: 'test-id',
        title: 'Test Goal',
        targetTaskCount: 5,
        period: GoalPeriod.daily,
        taskCategories: ['Work'],
        isActive: true,
        createdAt: DateTime.now(),
      );

      expect(goal.id, equals('test-id'));
      expect(goal.title, equals('Test Goal'));
      expect(goal.targetTaskCount, equals(5));
    });

    test('Goal.toMap returns a map', () {
      final goal = Goal(
        id: 'test-id',
        title: 'Test Goal',
        targetTaskCount: 5,
        period: GoalPeriod.daily,
        taskCategories: ['Work'],
        isActive: true,
        createdAt: DateTime.now(),
      );

      final map = goal.toMap();
      expect(map, isA<Map>());
      expect(map.containsKey('id'), isTrue);
      expect(map.containsKey('title'), isTrue);
    });
  });
}
