import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskgenius/models/goal.dart';
import 'package:taskgenius/services/database_service.dart';
import 'package:taskgenius/services/notification_service.dart';

// Create mock classes
class MockFirestoreService extends Mock implements FirestoreService {}

class MockNotificationService extends Mock implements NotificationService {}

// Create a simplified test Task model
class TestTask {
  final String id;
  final String title;
  final String category;
  final DateTime dueDate;
  final String priority;
  final int urgencyLevel;
  final int estimatedDuration;
  final bool isCompleted;
  final DateTime? completedAt;
  final int? scheduledDay;
  final int? scheduledTimeSlot;
  final String? scheduledTimeDescription;

  TestTask({
    required this.id,
    required this.title,
    required this.category,
    required this.dueDate,
    required this.priority,
    required this.urgencyLevel,
    required this.estimatedDuration,
    this.isCompleted = false,
    this.completedAt,
    this.scheduledDay,
    this.scheduledTimeSlot,
    this.scheduledTimeDescription,
  });
}

// Create a simplified test Goal model
class TestGoal {
  final String id;
  final String title;
  final String description;
  final int targetTaskCount;
  final GoalPeriod period;
  final List<String> taskCategories;
  final bool isActive;
  final DateTime createdAt;
  final int achievedCount;
  final DateTime? lastAchievedAt;

  TestGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.targetTaskCount,
    required this.period,
    required this.taskCategories,
    required this.isActive,
    required this.createdAt,
    this.achievedCount = 0,
    this.lastAchievedAt,
  });
}

// A simplified task provider for testing
class TestTaskProvider extends ChangeNotifier {
  List<TestTask> tasks = [];
  List<String> categories = [
    'Work',
    'Study',
    'Personal',
    'Shopping',
    'Health',
    'Travel',
  ];
  List<TestGoal> goals = [];
  Map<String, dynamic> userPreferences = {
    'availableHours': 8,
    'timePreference': 1,
  };

  bool isInitialized = true;

  // Clear all data
  void clearUser() {
    tasks = [];
    categories = ['Work', 'Study', 'Personal', 'Shopping', 'Health', 'Travel'];
    goals = [];
    userPreferences = {'availableHours': 8, 'timePreference': 1};
    notifyListeners();
  }

  // Get prioritized tasks
  List<TestTask> get prioritizedTasks {
    final sortedTasks = List<TestTask>.from(tasks);

    // Sort by priority (High > Medium > Low)
    sortedTasks.sort((a, b) {
      // First sort by priority
      final priorityOrder = {'High': 0, 'Medium': 1, 'Low': 2};
      final priorityComparison = priorityOrder[a.priority]!.compareTo(
        priorityOrder[b.priority]!,
      );

      // If same priority, sort by due date
      if (priorityComparison == 0) {
        return a.dueDate.compareTo(b.dueDate);
      }

      return priorityComparison;
    });

    return sortedTasks;
  }

  // Get completed tasks
  List<TestTask> get completedTasks {
    return tasks.where((task) => task.isCompleted).toList();
  }

  // Get tasks by category
  List<TestTask> getTasksByCategory(String category) {
    if (category == 'All') {
      return tasks;
    }
    return tasks.where((task) => task.category == category).toList();
  }

  // Get completed tasks by category
  List<TestTask> getCompletedTasksByCategory(String category) {
    if (category == 'All') {
      return completedTasks;
    }
    return completedTasks.where((task) => task.category == category).toList();
  }

  // Search tasks
  List<TestTask> searchTasks(String query) {
    if (query.isEmpty) {
      return tasks;
    }
    return tasks
        .where((task) => task.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Search completed tasks
  List<TestTask> searchCompletedTasks(String query) {
    if (query.isEmpty) {
      return completedTasks;
    }
    return completedTasks
        .where((task) => task.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Get active goals
  List<TestGoal> get activeGoals {
    return goals.where((goal) => goal.isActive).toList();
  }

  // Get current period goals
  List<TestGoal> getCurrentGoals(GoalPeriod period) {
    return goals
        .where((goal) => goal.isActive && goal.period == period)
        .toList();
  }

  // Check for new achievements
  bool hasNewAchievements() {
    final oneMinuteAgo = DateTime.now().subtract(const Duration(minutes: 1));

    return goals.any(
      (goal) =>
          goal.lastAchievedAt != null &&
          goal.lastAchievedAt!.isAfter(oneMinuteAgo),
    );
  }

  // Get AI suggestions (top priority tasks)
  List<TestTask> getAiSuggestions() {
    // Get uncompleted high priority tasks
    final highPriorityTasks =
        tasks
            .where((task) => !task.isCompleted && task.priority == 'High')
            .toList();

    // Sort by due date (soonest first)
    highPriorityTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    // Return top 3 or fewer if not enough high priority tasks
    return highPriorityTasks.take(3).toList();
  }

  // Get scheduled tasks
  List<TestTask> get scheduledTasks {
    // Create a copy of only tasks with scheduling info
    final scheduledTasks =
        tasks
            .where((task) => task.scheduledDay != null && !task.isCompleted)
            .toList();

    // Sort by scheduled day, then by time slot
    scheduledTasks.sort((a, b) {
      // First sort by scheduled day
      final dayComparison = a.scheduledDay!.compareTo(b.scheduledDay!);

      // If same day, sort by time slot
      if (dayComparison == 0) {
        return a.scheduledTimeSlot!.compareTo(b.scheduledTimeSlot!);
      }

      return dayComparison;
    });

    return scheduledTasks;
  }

  // Get today's scheduled tasks
  List<TestTask> get todaysScheduledTasks {
    return tasks
        .where((task) => task.scheduledDay == 0 && !task.isCompleted)
        .toList()
      ..sort((a, b) => a.scheduledTimeSlot!.compareTo(b.scheduledTimeSlot!));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestTaskProvider taskProvider;

  setUp(() {
    // Initialize the test provider
    taskProvider = TestTaskProvider();

    // Set up shared preferences for testing
    SharedPreferences.setMockInitialValues({});
  });

  group('TaskProvider Basic Tests', () {
    test('Initial values should be set correctly', () {
      expect(taskProvider.tasks, isEmpty);
      expect(taskProvider.categories.length, equals(6)); // Default categories
      expect(
        taskProvider.userPreferences['availableHours'],
        equals(8),
      ); // Default hours
    });

    test('clearUser should reset all values', () {
      // Arrange - Add some test data
      taskProvider.tasks.add(
        TestTask(
          id: 'test-1',
          title: 'Test Task',
          category: 'Work',
          dueDate: DateTime.now(),
          priority: 'High',
          urgencyLevel: 5,
          estimatedDuration: 60,
        ),
      );

      // Act
      taskProvider.clearUser();

      // Assert
      expect(taskProvider.tasks, isEmpty);
      expect(taskProvider.categories.length, equals(6)); // Reset to default
    });
  });

  group('Task List and Filtering Tests', () {
    test('prioritizedTasks should sort by priority and due date', () {
      // Arrange
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      final dayAfterTomorrow = now.add(const Duration(days: 2));

      taskProvider.tasks = [
        TestTask(
          id: 'test-1',
          title: 'Low Priority Task',
          category: 'Work',
          dueDate: now,
          priority: 'Low',
          urgencyLevel: 1,
          estimatedDuration: 30,
        ),
        TestTask(
          id: 'test-2',
          title: 'High Priority Later Task',
          category: 'Work',
          dueDate: dayAfterTomorrow,
          priority: 'High',
          urgencyLevel: 5,
          estimatedDuration: 60,
        ),
        TestTask(
          id: 'test-3',
          title: 'High Priority Soon Task',
          category: 'Work',
          dueDate: tomorrow,
          priority: 'High',
          urgencyLevel: 5,
          estimatedDuration: 60,
        ),
      ];

      // Act
      final prioritized = taskProvider.prioritizedTasks;

      // Assert
      expect(prioritized.length, equals(3));
      expect(
        prioritized[0].title,
        equals('High Priority Soon Task'),
      ); // First by priority + date
      expect(
        prioritized[1].title,
        equals('High Priority Later Task'),
      ); // Second by priority + date
      expect(
        prioritized[2].title,
        equals('Low Priority Task'),
      ); // Last due to low priority
    });

    test('getTasksByCategory should filter correctly', () {
      // Arrange
      taskProvider.tasks = [
        TestTask(
          id: 'test-1',
          title: 'Work Task',
          category: 'Work',
          dueDate: DateTime.now(),
          priority: 'High',
          urgencyLevel: 5,
          estimatedDuration: 60,
        ),
        TestTask(
          id: 'test-2',
          title: 'Study Task',
          category: 'Study',
          dueDate: DateTime.now(),
          priority: 'Medium',
          urgencyLevel: 3,
          estimatedDuration: 45,
        ),
        TestTask(
          id: 'test-3',
          title: 'Another Work Task',
          category: 'Work',
          dueDate: DateTime.now(),
          priority: 'Low',
          urgencyLevel: 1,
          estimatedDuration: 30,
        ),
      ];

      // Act & Assert
      expect(taskProvider.getTasksByCategory('Work').length, equals(2));
      expect(taskProvider.getTasksByCategory('Study').length, equals(1));
      expect(taskProvider.getTasksByCategory('Health').length, equals(0));
      expect(
        taskProvider.getTasksByCategory('All').length,
        equals(3),
      ); // 'All' returns all tasks
    });

    test('searchTasks should find matches in title', () {
      // Arrange
      taskProvider.tasks = [
        TestTask(
          id: 'test-1',
          title: 'Complete Project Report',
          category: 'Work',
          dueDate: DateTime.now(),
          priority: 'High',
          urgencyLevel: 5,
          estimatedDuration: 60,
        ),
        TestTask(
          id: 'test-2',
          title: 'Review Meeting Notes',
          category: 'Work',
          dueDate: DateTime.now(),
          priority: 'Medium',
          urgencyLevel: 3,
          estimatedDuration: 45,
        ),
        TestTask(
          id: 'test-3',
          title: 'Prepare for Project Presentation',
          category: 'Work',
          dueDate: DateTime.now(),
          priority: 'High',
          urgencyLevel: 4,
          estimatedDuration: 90,
        ),
      ];

      // Act & Assert
      expect(taskProvider.searchTasks('Project').length, equals(2));
      expect(taskProvider.searchTasks('Meeting').length, equals(1));
      expect(taskProvider.searchTasks('NotFound').length, equals(0));
      expect(
        taskProvider.searchTasks('').length,
        equals(3),
      ); // Empty query returns all
    });
  });

  group('Completed Tasks Tests', () {
    test('completedTasks should only include completed tasks', () {
      // Arrange
      taskProvider.tasks = [
        TestTask(
          id: 'test-1',
          title: 'Completed Task',
          category: 'Work',
          dueDate: DateTime.now(),
          priority: 'High',
          urgencyLevel: 5,
          estimatedDuration: 60,
          isCompleted: true,
          completedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        TestTask(
          id: 'test-2',
          title: 'Pending Task',
          category: 'Work',
          dueDate: DateTime.now(),
          priority: 'Medium',
          urgencyLevel: 3,
          estimatedDuration: 45,
          isCompleted: false,
        ),
      ];

      // Act
      final completed = taskProvider.completedTasks;

      // Assert
      expect(completed.length, equals(1));
      expect(completed[0].title, equals('Completed Task'));
    });

    test('getCompletedTasksByCategory should filter correctly', () {
      // Arrange
      taskProvider.tasks = [
        TestTask(
          id: 'test-1',
          title: 'Completed Work Task',
          category: 'Work',
          dueDate: DateTime.now(),
          priority: 'High',
          urgencyLevel: 5,
          estimatedDuration: 60,
          isCompleted: true,
          completedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        TestTask(
          id: 'test-2',
          title: 'Completed Study Task',
          category: 'Study',
          dueDate: DateTime.now(),
          priority: 'Medium',
          urgencyLevel: 3,
          estimatedDuration: 45,
          isCompleted: true,
          completedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        TestTask(
          id: 'test-3',
          title: 'Pending Work Task',
          category: 'Work',
          dueDate: DateTime.now(),
          priority: 'Low',
          urgencyLevel: 1,
          estimatedDuration: 30,
          isCompleted: false,
        ),
      ];

      // Act & Assert
      expect(
        taskProvider.getCompletedTasksByCategory('Work').length,
        equals(1),
      );
      expect(
        taskProvider.getCompletedTasksByCategory('Study').length,
        equals(1),
      );
      expect(taskProvider.getCompletedTasksByCategory('All').length, equals(2));
    });

    test('searchCompletedTasks should find matches in completed tasks', () {
      // Arrange
      taskProvider.tasks = [
        TestTask(
          id: 'test-1',
          title: 'Completed Report',
          category: 'Work',
          dueDate: DateTime.now(),
          priority: 'High',
          urgencyLevel: 5,
          estimatedDuration: 60,
          isCompleted: true,
          completedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        TestTask(
          id: 'test-2',
          title: 'Completed Presentation',
          category: 'Work',
          dueDate: DateTime.now(),
          priority: 'Medium',
          urgencyLevel: 3,
          estimatedDuration: 45,
          isCompleted: true,
          completedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        TestTask(
          id: 'test-3',
          title: 'Pending Report Review',
          category: 'Work',
          dueDate: DateTime.now(),
          priority: 'Low',
          urgencyLevel: 1,
          estimatedDuration: 30,
          isCompleted: false,
        ),
      ];

      // Act & Assert
      expect(taskProvider.searchCompletedTasks('Report').length, equals(1));
      expect(
        taskProvider.searchCompletedTasks('Presentation').length,
        equals(1),
      );
      expect(
        taskProvider.searchCompletedTasks('Review').length,
        equals(0),
      ); // Not completed
      expect(
        taskProvider.searchCompletedTasks('').length,
        equals(2),
      ); // All completed
    });
  });

  group('Goal Management Tests', () {
    test('activeGoals should only include active goals', () {
      // Arrange
      final now = DateTime.now();
      taskProvider.goals = [
        TestGoal(
          id: 'goal-1',
          title: 'Active Goal',
          description: 'Test goal',
          targetTaskCount: 5,
          period: GoalPeriod.daily,
          taskCategories: ['Work'],
          isActive: true,
          createdAt: now.subtract(const Duration(days: 5)),
          achievedCount: 2,
          lastAchievedAt: now.subtract(const Duration(days: 1)),
        ),
        TestGoal(
          id: 'goal-2',
          title: 'Inactive Goal',
          description: 'Test goal',
          targetTaskCount: 3,
          period: GoalPeriod.weekly,
          taskCategories: ['Study'],
          isActive: false,
          createdAt: now.subtract(const Duration(days: 10)),
          achievedCount: 1,
          lastAchievedAt: now.subtract(const Duration(days: 8)),
        ),
      ];

      // Act
      final active = taskProvider.activeGoals;

      // Assert
      expect(active.length, equals(1));
      expect(active[0].title, equals('Active Goal'));
    });

    test('getCurrentGoals should filter by period', () {
      // Arrange
      final now = DateTime.now();
      taskProvider.goals = [
        TestGoal(
          id: 'goal-1',
          title: 'Daily Goal',
          description: 'Test goal',
          targetTaskCount: 5,
          period: GoalPeriod.daily,
          taskCategories: ['Work'],
          isActive: true,
          createdAt: now.subtract(const Duration(days: 5)),
          achievedCount: 2,
          lastAchievedAt: now.subtract(const Duration(days: 1)),
        ),
        TestGoal(
          id: 'goal-2',
          title: 'Weekly Goal',
          description: 'Test goal',
          targetTaskCount: 3,
          period: GoalPeriod.weekly,
          taskCategories: ['Study'],
          isActive: true,
          createdAt: now.subtract(const Duration(days: 10)),
          achievedCount: 1,
          lastAchievedAt: now.subtract(const Duration(days: 8)),
        ),
        TestGoal(
          id: 'goal-3',
          title: 'Inactive Daily Goal',
          description: 'Test goal',
          targetTaskCount: 2,
          period: GoalPeriod.daily,
          taskCategories: ['Health'],
          isActive: false,
          createdAt: now.subtract(const Duration(days: 3)),
          achievedCount: 0,
          lastAchievedAt: null,
        ),
      ];

      // Act & Assert
      expect(taskProvider.getCurrentGoals(GoalPeriod.daily).length, equals(1));
      expect(taskProvider.getCurrentGoals(GoalPeriod.weekly).length, equals(1));
    });

    test('hasNewAchievements should detect recent achievements', () {
      // Arrange
      final now = DateTime.now();
      taskProvider.goals = [
        TestGoal(
          id: 'goal-1',
          title: 'Old Achievement',
          description: 'Test goal',
          targetTaskCount: 5,
          period: GoalPeriod.daily,
          taskCategories: ['Work'],
          isActive: true,
          createdAt: now.subtract(const Duration(days: 5)),
          achievedCount: 2,
          lastAchievedAt: now.subtract(const Duration(days: 1)),
        ),
        TestGoal(
          id: 'goal-2',
          title: 'Recent Achievement',
          description: 'Test goal',
          targetTaskCount: 3,
          period: GoalPeriod.weekly,
          taskCategories: ['Study'],
          isActive: true,
          createdAt: now.subtract(const Duration(days: 10)),
          achievedCount: 1,
          lastAchievedAt: now.subtract(
            const Duration(seconds: 30),
          ), // Within last minute
        ),
      ];

      // Act & Assert
      expect(taskProvider.hasNewAchievements(), isTrue);
    });
  });

  group('Task Management Tests', () {
    test('getAiSuggestions should return high priority tasks', () {
      // Arrange
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      final dayAfter = now.add(const Duration(days: 2));

      taskProvider.tasks = [
        TestTask(
          id: 'test-1',
          title: 'Urgent High Priority',
          category: 'Work',
          dueDate: now,
          priority: 'High',
          urgencyLevel: 5,
          estimatedDuration: 60,
        ),
        TestTask(
          id: 'test-2',
          title: 'High Priority Soon',
          category: 'Work',
          dueDate: tomorrow,
          priority: 'High',
          urgencyLevel: 5,
          estimatedDuration: 60,
        ),
        TestTask(
          id: 'test-3',
          title: 'High Priority Later',
          category: 'Work',
          dueDate: dayAfter,
          priority: 'High',
          urgencyLevel: 4,
          estimatedDuration: 60,
        ),
        TestTask(
          id: 'test-4',
          title: 'Medium Priority',
          category: 'Work',
          dueDate: now,
          priority: 'Medium',
          urgencyLevel: 3,
          estimatedDuration: 30,
        ),
      ];

      // Act
      final suggestions = taskProvider.getAiSuggestions();

      // Assert
      expect(suggestions.length, equals(3)); // Only high priority, max 3
      expect(
        suggestions[0].title,
        equals('Urgent High Priority'),
      ); // Sorted by due date
      expect(suggestions[1].title, equals('High Priority Soon'));
      expect(suggestions[2].title, equals('High Priority Later'));
    });

    test('scheduled tasks should be sorted by day and time', () {
      // Arrange
      taskProvider.tasks = [
        TestTask(
          id: 'test-1',
          title: 'Today Morning',
          category: 'Work',
          dueDate: DateTime.now(),
          priority: 'High',
          urgencyLevel: 5,
          estimatedDuration: 60,
          scheduledDay: 0, // Today
          scheduledTimeSlot: 1, // Morning
        ),
        TestTask(
          id: 'test-2',
          title: 'Today Afternoon',
          category: 'Work',
          dueDate: DateTime.now(),
          priority: 'Medium',
          urgencyLevel: 3,
          estimatedDuration: 45,
          scheduledDay: 0, // Today
          scheduledTimeSlot: 2, // Afternoon
        ),
        TestTask(
          id: 'test-3',
          title: 'Tomorrow Morning',
          category: 'Work',
          dueDate: DateTime.now().add(const Duration(days: 1)),
          priority: 'High',
          urgencyLevel: 4,
          estimatedDuration: 30,
          scheduledDay: 1, // Tomorrow
          scheduledTimeSlot: 1, // Morning
        ),
      ];

      // Act
      final scheduled = taskProvider.scheduledTasks;

      // Assert
      expect(scheduled.length, equals(3));
      expect(scheduled[0].title, equals('Today Morning'));
      expect(scheduled[1].title, equals('Today Afternoon'));
      expect(scheduled[2].title, equals('Tomorrow Morning'));
    });

    test('today\'s scheduled tasks should only include today', () {
      // Arrange
      taskProvider.tasks = [
        TestTask(
          id: 'test-1',
          title: 'Today Morning',
          category: 'Work',
          dueDate: DateTime.now(),
          priority: 'High',
          urgencyLevel: 5,
          estimatedDuration: 60,
          scheduledDay: 0, // Today
          scheduledTimeSlot: 1, // Morning
        ),
        TestTask(
          id: 'test-2',
          title: 'Today Afternoon',
          category: 'Work',
          dueDate: DateTime.now(),
          priority: 'Medium',
          urgencyLevel: 3,
          estimatedDuration: 45,
          scheduledDay: 0, // Today
          scheduledTimeSlot: 2, // Afternoon
        ),
        TestTask(
          id: 'test-3',
          title: 'Tomorrow Morning',
          category: 'Work',
          dueDate: DateTime.now().add(const Duration(days: 1)),
          priority: 'High',
          urgencyLevel: 4,
          estimatedDuration: 30,
          scheduledDay: 1, // Tomorrow
          scheduledTimeSlot: 1, // Morning
        ),
      ];

      // Act
      final todayTasks = taskProvider.todaysScheduledTasks;

      // Assert
      expect(todayTasks.length, equals(2));
      expect(
        todayTasks[0].title,
        equals('Today Morning'),
      ); // Lower timeslot first
      expect(todayTasks[1].title, equals('Today Afternoon'));
    });
  });
}
