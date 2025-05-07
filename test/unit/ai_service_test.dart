import 'package:flutter_test/flutter_test.dart';
import 'package:taskgenius/models/task.dart';
import 'package:taskgenius/services/ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('PriorityPredictor Tests', () {
    test('Predict priority should return valid priority values', () {
      // Test with various due dates and urgency levels
      final dueToday = DateTime.now();
      final dueTomorrow = DateTime.now().add(const Duration(days: 1));
      final dueNextWeek = DateTime.now().add(const Duration(days: 7));
      
      // Due today with high urgency
      String priority = PriorityPredictor.predictPriority(dueToday, 5);
      expect(priority, isIn(['High', 'Medium', 'Low']));
      
      // Due tomorrow with medium urgency
      priority = PriorityPredictor.predictPriority(dueTomorrow, 3);
      expect(priority, isIn(['High', 'Medium', 'Low']));
      
      // Due next week with low urgency
      priority = PriorityPredictor.predictPriority(dueNextWeek, 1);
      expect(priority, isIn(['High', 'Medium', 'Low']));
    });
    
    test('Refresh model should complete without errors', () async {
      // Create a list of mock tasks
      final tasks = [
        Task(
          id: 'test-1',
          title: 'Test Task',
          category: 'Work',
          dueDate: DateTime.now(),
          priority: 'High',
          urgencyLevel: 5,
          estimatedDuration: Duration(minutes: 60),
          isCompleted: true,
          completedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];
      
      // This should complete without throwing exceptions
      await PriorityPredictor.refreshModel(tasks);
      
      // No assertions needed - we're just testing that it doesn't throw errors
    });
  });
  
  group('DurationEstimator Tests', () {
    test('Estimate task duration should return reasonable values', () {
      // Test with various categories, urgency levels, and due dates
      final dueToday = DateTime.now();
      final dueNextWeek = DateTime.now().add(const Duration(days: 7));
      
      // Work category, high urgency, due today
      Duration duration = DurationEstimator.estimateTaskDuration('Work', 5, dueToday);
      expect(duration.inMinutes, greaterThan(0));
      expect(duration.inMinutes, lessThan(180)); // Reasonable max for most tasks
      
      // Study category, medium urgency, due next week
      duration = DurationEstimator.estimateTaskDuration('Study', 3, dueNextWeek);
      expect(duration.inMinutes, greaterThan(0));
      
      // Personal category, low urgency, due next week
      duration = DurationEstimator.estimateTaskDuration('Personal', 1, dueNextWeek);
      expect(duration.inMinutes, greaterThan(0));
    });
    
    test('Duration formatting should format correctly', () {
      // Test hours and minutes
      String formatted = DurationEstimator.formatDuration(const Duration(hours: 2, minutes: 30));
      expect(formatted, equals('2 hr 30 min'));
      
      // Test only hours
      formatted = DurationEstimator.formatDuration(const Duration(hours: 1));
      expect(formatted, equals('1 hr '));
      
      // Test only minutes
      formatted = DurationEstimator.formatDuration(const Duration(minutes: 45));
      expect(formatted, equals('45 min'));
    });
    
    test('Recalibrate model should complete without errors', () async {
      // Create a list of mock tasks
      final tasks = [
        Task(
          id: 'test-1',
          title: 'Test Task',
          category: 'Work',
          dueDate: DateTime.now(),
          priority: 'High',
          urgencyLevel: 5,
          estimatedDuration: Duration(minutes: 60),
          isCompleted: true,
          completedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];
      
      // This should complete without throwing exceptions
      await DurationEstimator.recalibrateModel(tasks);
      
      // No assertions needed - we're just testing that it doesn't throw errors
    });
  });
  
  group('TaskScheduler Tests', () {
    test('Suggest schedule should return valid schedule', () {
      final dueDate = DateTime.now().add(const Duration(days: 5));
      
      // High priority task
      var schedule = TaskScheduler.suggestSchedule(
        priority: 'High',
        duration: const Duration(minutes: 60),
        userAvailabilityHours: 8,
        timePreference: 1, // Afternoon preference
        dueDate: dueDate,
      );
      
      // Verify the returned schedule has the expected fields
      expect(schedule, isA<Map<String, dynamic>>());
      expect(schedule['day'], isA<int>());
      expect(schedule['timeSlot'], isA<int>());
      expect(schedule['timeSlotName'], isIn(['Morning', 'Afternoon', 'Evening']));
      
      // Verify the schedule is within the due date
      expect(schedule['day'], lessThanOrEqualTo(5));
      
      // Medium priority task
      schedule = TaskScheduler.suggestSchedule(
        priority: 'Medium',
        duration: const Duration(minutes: 45),
        userAvailabilityHours: 8,
        timePreference: 0, // Morning preference
        dueDate: dueDate,
      );
      
      expect(schedule['day'], isA<int>());
      expect(schedule['timeSlot'], isA<int>());
      
      // Low priority task
      schedule = TaskScheduler.suggestSchedule(
        priority: 'Low',
        duration: const Duration(minutes: 30),
        userAvailabilityHours: 8,
        timePreference: 2, // Evening preference
        dueDate: dueDate,
      );
      
      expect(schedule['day'], isA<int>());
      expect(schedule['timeSlot'], isA<int>());
    });
    
    test('Get schedule description should format correctly', () {
      // Test today
      var description = TaskScheduler.getScheduleDescription(0, 'Morning');
      expect(description, equals('Today, Morning'));
      
      // Test tomorrow
      description = TaskScheduler.getScheduleDescription(1, 'Afternoon');
      expect(description, equals('Tomorrow, Afternoon'));
      
      // Test specific date
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 3));
      description = TaskScheduler.getScheduleDescription(3, 'Evening');
      expect(description, contains('Evening'));
      
      // Should contain date in format day/month/year
      expect(description, contains('${futureDate.day}/${futureDate.month}/${futureDate.year}'));
    });
  });
}