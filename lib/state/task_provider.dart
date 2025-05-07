import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskgenius/models/goal.dart';
import 'package:taskgenius/models/task.dart';
import 'package:taskgenius/services/ai_service.dart';
import 'package:taskgenius/services/database_service.dart';
import 'package:taskgenius/services/notification_service.dart';
import 'package:taskgenius/services/productivity_Service.dart';

class TaskProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<List<Task>>? _tasksSubscription;

  String? _currentUserId;

  String get _tasksKey =>
      _currentUserId != null ? 'tasks_data_$_currentUserId' : 'tasks_data';
  String get _categoriesKey =>
      _currentUserId != null
          ? 'task_categories_$_currentUserId'
          : 'task_categories';
  String get _userPreferencesKey =>
      _currentUserId != null
          ? 'user_preferences_$_currentUserId'
          : 'user_preferences';

  List<Task> _tasks = [];
  List<String> _categories = [
    'Work',
    'Study',
    'Personal',
    'Shopping',
    'Health',
    'Travel',
  ];

  Map<String, dynamic> _userPreferences = {
    'availableHours': 8,
    'timePreference': 1,
  };

  bool _isInitialized = false;
  int _completedTasksCount = 0;
  DateTime? _lastPriorityModelRefresh;
List<Goal> _goals = [];
StreamSubscription<List<Goal>>? _goalsSubscription;
  Future<void> setUser(String userId) async {
    if (_currentUserId == userId && _isInitialized) {
      return;
    }

    _currentUserId = userId;
    _isInitialized = false;
    await _tasksSubscription?.cancel();

    _tasks.clear();
    _categories = ['Work', 'Study', 'Personal', 'Shopping', 'Health', 'Travel'];
    _userPreferences = {'availableHours': 8, 'timePreference': 1};

    await _init();
  }

  // Clear data when user logs out
  void clearUser() {
      _goals.clear();
  _goalsSubscription?.cancel();
    _currentUserId = null;
    _isInitialized = false;
    _tasks.clear();
    _categories = ['Work', 'Study', 'Personal', 'Shopping', 'Health', 'Travel'];
    _userPreferences = {'availableHours': 8, 'timePreference': 1};
    _tasksSubscription?.cancel();

    notifyListeners();
  }

  // Initialize and load data
  Future<void> _init() async {
    if (!_isInitialized && _currentUserId != null) {
      // Load categories and preferences
      _categories = await _firestoreService.getCategories(_currentUserId!);
      _userPreferences = await _firestoreService.getUserPreferences(
        _currentUserId!,
      );
      _lastPriorityModelRefresh = _tryParseLastModelRefresh();
      _completedTasksCount =
          _userPreferences['completedTasksCount'] as int? ?? 0;
      // Subscribe to tasks
      _tasksSubscription = _firestoreService.getTasks(_currentUserId!).listen((
        tasks,
      ) {
        _tasks = tasks;
        notifyListeners();
      });
// Subscribe to goals
    _goalsSubscription = _firestoreService.getGoals(_currentUserId!).listen((goals) {
      _goals = goals;
      
      // Check goal achievement whenever goals are loaded or updated
      _checkGoalAchievement();
      
      notifyListeners();
    });
      // Remove old completed tasks
      await removeOldCompletedTasks();

      _isInitialized = true;
      notifyListeners();
      print("TaskProvider initialized with ${_tasks.length} tasks");
    }
  }
// Goal management methods
List<Goal> get goals => _goals;

List<Goal> get activeGoals => _goals.where((goal) => goal.isActive).toList();

// Get current period goals
List<Goal> getCurrentGoals(GoalPeriod period) {
  return _goals.where((goal) => 
    goal.isActive && goal.period == period && !goal.isAchievedForCurrentPeriod()
  ).toList();
}

// Add a new goal
Future<void> addGoal(Goal goal) async {
  if (_currentUserId == null) return;
  
  _goals.add(goal);
  await _firestoreService.saveGoal(_currentUserId!, goal);
  
  notifyListeners();
}

// Update a goal
Future<void> updateGoal(Goal updatedGoal) async {
  if (_currentUserId == null) return;
  
  final index = _goals.indexWhere((goal) => goal.id == updatedGoal.id);
  if (index != -1) {
    _goals[index] = updatedGoal;
    await _firestoreService.saveGoal(_currentUserId!, updatedGoal);
    
    notifyListeners();
  }
}

// Delete a goal
Future<void> deleteGoal(String goalId) async {
  if (_currentUserId == null) return;
  
  await _firestoreService.deleteGoal(_currentUserId!, goalId);
  
  notifyListeners();
}

// Check goal achievement
void _checkGoalAchievement() {
  final now = DateTime.now();
  
  // Process each active goal
  for (final goal in activeGoals) {
    // Skip goals already achieved in current period
    if (goal.isAchievedForCurrentPeriod()) continue;
    
    // Determine period start date
    DateTime periodStartDate;
    if (goal.period == GoalPeriod.daily) {
      periodStartDate = DateTime(now.year, now.month, now.day);
    } else {
      // Weekly - go back to Monday
      final daysSinceMonday = now.weekday - 1;
      periodStartDate = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: daysSinceMonday));
    }
    
    // Count completed tasks in the period that match goal criteria
    int completedTaskCount = _tasks.where((task) {
      // Must be completed in current period
      if (!task.isCompleted || task.completedAt == null || 
          task.completedAt!.isBefore(periodStartDate)) {
        return false;
      }
      
      // Check category filter if present
      if (goal.taskCategories.isNotEmpty && 
          !goal.taskCategories.contains(task.category)) {
        return false;
      }
      
      return true;
    }).length;
    
    // Update goal progress
    if (completedTaskCount >= goal.targetTaskCount && !goal.isAchievedForCurrentPeriod()) {
      // Goal achieved!
      final updatedGoal = goal.copyWith(
        achievedCount: goal.achievedCount + 1,
        lastAchievedAt: now,
      );
      
      updateGoal(updatedGoal);
      
      // Show achievement notification
      NotificationService.instance.showGoalAchievedNotification(updatedGoal);
    }
  }
}

// Method to check if any goals were just achieved
bool hasNewAchievements() {
  // Check if any goals were achieved in the last minute
  final oneMinuteAgo = DateTime.now().subtract(const Duration(minutes: 1));
  
  return _goals.any((goal) => 
    goal.lastAchievedAt != null && 
    goal.lastAchievedAt!.isAfter(oneMinuteAgo)
  );
}

// Get goal achievement rate
double getGoalAchievementRate(GoalPeriod period, {int lookbackPeriods = 4}) {
  final goals = _goals.where((goal) => goal.period == period).toList();
  if (goals.isEmpty) return 0.0;
  
  int totalOpportunities = 0;
  int totalAchievements = 0;
  
  for (final goal in goals) {
    // Count achievements within lookback periods
    totalAchievements += goal.achievedCount;
    
    // Calculate total opportunities based on creation date
    final now = DateTime.now();
    DateTime startDate = goal.createdAt;
    
    if (period == GoalPeriod.daily) {
      // Count days since creation, capped at lookback
      final daysSinceCreation = now.difference(startDate).inDays;
      totalOpportunities += daysSinceCreation < lookbackPeriods ? 
                          daysSinceCreation : lookbackPeriods;
    } else {
      // Weekly periods
      final weeksSinceCreation = now.difference(startDate).inDays ~/ 7;
      totalOpportunities += weeksSinceCreation < lookbackPeriods ? 
                          weeksSinceCreation : lookbackPeriods;
    }
  }
  
  if (totalOpportunities == 0) return 0.0;
  return totalAchievements / totalOpportunities;
}
  DateTime? _tryParseLastModelRefresh() {
    final lastRefreshString =
        _userPreferences['lastPriorityModelRefresh'] as String?;
    if (lastRefreshString == null) return null;

    try {
      return DateTime.parse(lastRefreshString);
    } catch (e) {
      print("Error parsing last model refresh date: $e");
      return null;
    }
  }

  // Add this method to check if model refresh is needed
  bool _isPriorityModelRefreshNeeded() {
    if (_lastPriorityModelRefresh == null) return true;

    final now = DateTime.now();
    final difference = now.difference(_lastPriorityModelRefresh!);

    // Weekly refresh requirement
    return difference.inDays >= 7;
  }

  // Add this method to update your user preferences with model info
  Future<void> _updateModelTrackingInfo() async {
    if (_currentUserId == null) return;

    _userPreferences['lastPriorityModelRefresh'] =
        DateTime.now().toIso8601String();
    _userPreferences['completedTasksCount'] = _completedTasksCount;

    await _firestoreService.saveUserPreferences(
      _currentUserId!,
      _userPreferences,
    );
  }

  // Load tasks from SharedPreferences
  Future<void> _loadTasks() async {
    if (_currentUserId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getStringList(_tasksKey) ?? [];

      _tasks =
          tasksJson.map((taskJson) {
            final taskMap = json.decode(taskJson) as Map<String, dynamic>;
            return Task.fromMap(taskMap);
          }).toList();

      print("Loaded ${_tasks.length} tasks from SharedPreferences");
    } catch (e) {
      print("Error loading tasks: $e");
      _tasks = [];
    }
  }

  // Save tasks to SharedPreferences
  Future<void> _saveTasks() async {
    if (_currentUserId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      final tasksJson =
          _tasks.map((task) {
            return json.encode(task.toMap());
          }).toList();

      await prefs.setStringList(_tasksKey, tasksJson);
      print("Saved ${_tasks.length} tasks to SharedPreferences");
    } catch (e) {
      print("Error saving tasks: $e");
    }
  }

  // Load categories from SharedPreferences
  Future<void> _loadCategories() async {
    if (_currentUserId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCategories = prefs.getStringList(_categoriesKey);
      if (savedCategories != null && savedCategories.isNotEmpty) {
        _categories = savedCategories;
      } else {
        await _saveCategories();
      }
    } catch (e) {
      print("Error loading categories: $e");
    }
  }

  // Save categories to SharedPreferences
  Future<void> _saveCategories() async {
    if (_currentUserId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_categoriesKey, _categories);
    } catch (e) {
      print("Error saving categories: $e");
    }
  }

  // Load user preferences from SharedPreferences
  Future<void> _loadUserPreferences() async {
    if (_currentUserId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = prefs.getString(_userPreferencesKey);
      if (preferencesJson != null) {
        _userPreferences = json.decode(preferencesJson) as Map<String, dynamic>;
      } else {
        await _saveUserPreferences();
      }
    } catch (e) {
      print("Error loading user preferences: $e");
    }
  }

  // Save user preferences to SharedPreferences
  Future<void> _saveUserPreferences() async {
    if (_currentUserId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userPreferencesKey, json.encode(_userPreferences));
    } catch (e) {
      print("Error saving user preferences: $e");
    }
  }

  // Get completed tasks
  List<Task> get completedTasks {
    return _tasks.where((task) => task.isCompleted).toList();
  }

  // Get completed tasks sorted by completion time
  List<Task> get completedTasksByDate {
    final completed = completedTasks;
    return completed;
  }

  // Get completed tasks by category
  List<Task> getCompletedTasksByCategory(String category) {
    if (category == 'All') {
      return completedTasks;
    }
    return completedTasks.where((task) => task.category == category).toList();
  }

  // Search completed tasks
  List<Task> searchCompletedTasks(String query) {
    if (query.isEmpty) {
      return completedTasks;
    }
    return completedTasks
        .where((task) => task.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  bool get isInitialized => _isInitialized;

  List<Task> get tasks => _tasks;
  List<String> get categories => _categories;
  Map<String, dynamic> get userPreferences => _userPreferences;

  // Get tasks sorted by priority
  List<Task> get prioritizedTasks {
    // Create a copy to avoid modifying the original list
    final sortedTasks = List<Task>.from(_tasks);

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

  // Get tasks sorted by scheduled day and time
  List<Task> get scheduledTasks {
    // Create a copy of only tasks with scheduling info
    final scheduledTasks =
        _tasks
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
  List<Task> get todaysScheduledTasks {
    return _tasks
        .where((task) => task.scheduledDay == 0 && !task.isCompleted)
        .toList()
      ..sort((a, b) => a.scheduledTimeSlot!.compareTo(b.scheduledTimeSlot!));
  }

  // Update user preferences
  Future<void> updateUserPreferences({
    int? availableHours,
    int? timePreference,
  }) async {
    if (_currentUserId == null) return;

    if (availableHours != null) {
      _userPreferences['availableHours'] = availableHours;
    }

    if (timePreference != null) {
      _userPreferences['timePreference'] = timePreference;
    }

    await _firestoreService.saveUserPreferences(
      _currentUserId!,
      _userPreferences,
    );

    notifyListeners();
  }

  Future<void> updateLastCleanupDate() async {
    if (_currentUserId == null) return;

    _userPreferences['lastTaskCleanup'] = DateTime.now().toIso8601String();

    await _firestoreService.saveUserPreferences(
      _currentUserId!,
      _userPreferences,
    );
  }

  // method to check if cleanup is needed
  Future<bool> isCleanupNeeded() async {
    if (_currentUserId == null) return false;

    final lastCleanupString = _userPreferences['lastTaskCleanup'] as String?;
    if (lastCleanupString == null) return true;

    try {
      final lastCleanup = DateTime.parse(lastCleanupString);
      final now = DateTime.now();

      // Check if last cleanup was more than 1 day ago
      return now.difference(lastCleanup).inDays >= 1;
    } catch (e) {
      print("Error parsing last cleanup date: $e");
      return true;
    }
  }

  Future<void> addTask(Task task) async {
    try {
      if (_currentUserId == null) return;

      print("Adding task: ${task.title} with ID: ${task.id}");

      // Schedule the task using AI
      final schedule = _scheduleTask(task);

      // Create a new task with scheduling info
      final scheduledTask = Task(
        id: task.id,
        title: task.title,
        category: task.category,
        dueDate: task.dueDate,
        urgencyLevel: task.urgencyLevel,
        priority: task.priority,
        isCompleted: task.isCompleted,
        estimatedDuration: task.estimatedDuration,
        scheduledDay: schedule['day'],
        scheduledTimeSlot: schedule['timeSlot'],
        scheduledTimeDescription: TaskScheduler.getScheduleDescription(
          schedule['day'],
          schedule['timeSlotName'],
        ),
      );

      _tasks.add(scheduledTask);

      await _firestoreService.saveTask(_currentUserId!, scheduledTask);

      _scheduleTaskNotifications(scheduledTask);

      print("Task count after adding: ${_tasks.length}");

      notifyListeners();
    } catch (e) {
      print("Error adding task: $e");
    }
  }

  // Schedule a task using AI recommendations
  Map<String, dynamic> _scheduleTask(Task task) {
    // Get user's available hours and time preference
    final availableHours = _userPreferences['availableHours'] as int;
    final timePreference = _userPreferences['timePreference'] as int;

    // Get AI schedule suggestion
    return TaskScheduler.suggestSchedule(
      priority: task.priority,
      duration: task.estimatedDuration,
      userAvailabilityHours: availableHours,
      timePreference: timePreference,
      dueDate: task.dueDate,
    );
  }

  Future<void> addCategory(String category) async {
    if (_currentUserId == null) return;

    if (!_categories.contains(category)) {
      _categories.add(category);

      await _firestoreService.saveCategories(_currentUserId!, _categories);

      notifyListeners();
    }
  }

  // method to your TaskProvider class
  Future<void> removeOldCompletedTasks() async {
    try {
      if (_currentUserId == null) return;

      final now = DateTime.now();
      final cutoffDate = now.subtract(const Duration(days: 90));

      // Find tasks completed more than 90 days ago
      final tasksToRemove =
          _tasks.where((task) {
            return task.isCompleted &&
                task.completedAt != null &&
                task.completedAt!.isBefore(cutoffDate);
          }).toList();

      // If no old tasks, return early
      if (tasksToRemove.isEmpty) return;

      print(
        "Removing ${tasksToRemove.length} completed tasks older than 90 days",
      );

      // Delete each task from Firestore
      for (final task in tasksToRemove) {
        await _firestoreService.deleteTask(_currentUserId!, task.id);

        NotificationService.instance.cancelTaskNotifications(task.id);
      }

    } catch (e) {
      print("Error removing old completed tasks: $e");
    }
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    try {
      await _ensureInitialized();

      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        final oldTask = _tasks[index];
        final isNowCompleted = !oldTask.isCompleted;

        // Create a new task with the updated completion status
        final updatedTask = Task(
          id: oldTask.id,
          title: oldTask.title,
          category: oldTask.category,
          dueDate: oldTask.dueDate,
          urgencyLevel: oldTask.urgencyLevel,
          priority: oldTask.priority,
          isCompleted: !oldTask.isCompleted,
          estimatedDuration: oldTask.estimatedDuration,
          scheduledDay: oldTask.scheduledDay,
          scheduledTimeSlot: oldTask.scheduledTimeSlot,
          scheduledTimeDescription: oldTask.scheduledTimeDescription,
          completedAt: isNowCompleted ? DateTime.now() : null,
        );

        _tasks[index] = updatedTask;

        if (_currentUserId != null) {
          await _firestoreService.saveTask(_currentUserId!, updatedTask);
        }

        // If task is now completed, record the completion
        if (isNowCompleted) {
          await ProductivityService.recordTaskCompletion(updatedTask);
          NotificationService.instance.cancelTaskNotifications(taskId);

          // Increment completed task count
          _completedTasksCount++;

          // Check if duration model recalibration is needed (every 10 completions)
          if (_completedTasksCount % 10 == 0) {
            await _recalibrateDurationModel();
          }

          // Check if priority model refresh is needed (weekly)
          if (_isPriorityModelRefreshNeeded()) {
            await _refreshPriorityModel();
          }

          // Update tracking info
          await _updateModelTrackingInfo();
              _checkGoalAchievement();

        }
        // If task is now uncompleted, schedule notifications
        else {
          _scheduleTaskNotifications(updatedTask);
        }

        notifyListeners();
      }
    } catch (e) {
      print("Error toggling task completion: $e");
    }
  }

  Future<void> _recalibrateDurationModel() async {
    try {
      print(
        "Recalibrating duration estimation model after 10 task completions",
      );

      // Get completed tasks with completion times
      final completedTasks =
          _tasks
              .where((task) => task.isCompleted && task.completedAt != null)
              .toList();

      if (completedTasks.isEmpty) return;

      await DurationEstimator.recalibrateModel(completedTasks);

      print("Duration estimation model recalibrated successfully");
    } catch (e) {
      print("Error recalibrating duration model: $e");
    }
  }

  Future<void> _refreshPriorityModel() async {
    try {
      print("Refreshing priority model with user data (weekly update)");

      await PriorityPredictor.refreshModel(_tasks);

      // Update last refresh timestamp
      _lastPriorityModelRefresh = DateTime.now();

      print("Priority model refreshed successfully");
    } catch (e) {
      print("Error refreshing priority model: $e");
    }
  }

  // Get productivity insights
  Future<List<String>> getProductivityInsights() async {
    return await ProductivityService.generateProductivityInsights(_tasks);
  }

  // Get completion statistics
  Future<Map<String, dynamic>> getProductivityStats() async {
    final completionRate = await ProductivityService.getWeeklyCompletionRate(
      _tasks,
    );
    final mostProductiveDay = await ProductivityService.getMostProductiveDay();
    final mostProductiveTime =
        await ProductivityService.getMostProductiveTimeOfDay();
    final categoryStats = await ProductivityService.getProductivityByCategory();
    final streak = await ProductivityService.getCompletionStreak();

    return {
      'completionRate': completionRate,
      'mostProductiveDay': mostProductiveDay,
      'mostProductiveTime': mostProductiveTime,
      'categoryStats': categoryStats,
      'streak': streak,
    };
  }

  // Update an existing task
  Future<void> updateTask(Task updatedTask) async {
    try {
      if (_currentUserId == null) return;

      final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
      if (index != -1) {
        final oldTask = _tasks[index];
        // Handle completion status changes
        DateTime? completedAt = updatedTask.completedAt;
        if (!oldTask.isCompleted && updatedTask.isCompleted) {
          // Task is being marked as completed now
          completedAt = DateTime.now();
        } else if (oldTask.isCompleted && !updatedTask.isCompleted) {
          // Task is being unmarked as completed
          completedAt = null;
        }
        // If priority, duration, due date changed, recalculate schedule
        Task taskToUpdate = updatedTask;

        if (oldTask.priority != updatedTask.priority ||
            oldTask.estimatedDuration != updatedTask.estimatedDuration ||
            oldTask.dueDate != updatedTask.dueDate) {
          // Reschedule the task
          final schedule = _scheduleTask(updatedTask);

          // Create updated task with new schedule
          taskToUpdate = Task(
            id: updatedTask.id,
            title: updatedTask.title,
            category: updatedTask.category,
            dueDate: updatedTask.dueDate,
            urgencyLevel: updatedTask.urgencyLevel,
            priority: updatedTask.priority,
            isCompleted: updatedTask.isCompleted,
            estimatedDuration: updatedTask.estimatedDuration,
            scheduledDay: schedule['day'],
            scheduledTimeSlot: schedule['timeSlot'],
            scheduledTimeDescription: TaskScheduler.getScheduleDescription(
              schedule['day'],
              schedule['timeSlotName'],
            ),
            completedAt: completedAt,
          );
        } else {
          if (completedAt != updatedTask.completedAt) {
            taskToUpdate = Task(
              id: updatedTask.id,
              title: updatedTask.title,
              category: updatedTask.category,
              dueDate: updatedTask.dueDate,
              urgencyLevel: updatedTask.urgencyLevel,
              priority: updatedTask.priority,
              isCompleted: updatedTask.isCompleted,
              estimatedDuration: updatedTask.estimatedDuration,
              scheduledDay: updatedTask.scheduledDay,
              scheduledTimeSlot: updatedTask.scheduledTimeSlot,
              scheduledTimeDescription: updatedTask.scheduledTimeDescription,
              completedAt: completedAt,
            );
          }
        }

        _tasks[index] = taskToUpdate;

        // Update in Firestore
        await _firestoreService.saveTask(_currentUserId!, taskToUpdate);

        // Handle notifications based on completion status
        if (!oldTask.isCompleted && taskToUpdate.isCompleted) {
          // Task was just completed
          await ProductivityService.recordTaskCompletion(taskToUpdate);
          NotificationService.instance.cancelTaskNotifications(taskToUpdate.id);
        } else if (oldTask.isCompleted && !taskToUpdate.isCompleted) {
          // Task was uncompleted
          NotificationService.instance.cancelTaskNotifications(taskToUpdate.id);
          _scheduleTaskNotifications(taskToUpdate);
        } else if (!taskToUpdate.isCompleted) {
          // Task details changed but still not completed - reschedule notifications
          NotificationService.instance.cancelTaskNotifications(taskToUpdate.id);
          _scheduleTaskNotifications(taskToUpdate);
        }

        notifyListeners();
      }
    } catch (e) {
      print("Error updating task: $e");
    }
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      if (_currentUserId == null) return;

      // Cancel notifications before deleting
      NotificationService.instance.cancelTaskNotifications(taskId);
      await _firestoreService.deleteTask(_currentUserId!, taskId);

      notifyListeners();
    } catch (e) {
      print("Error deleting task: $e");
    }
  }

  // Reschedule all tasks
  Future<void> rescheduleAllTasks() async {
    try {
      await _ensureInitialized();

      for (int i = 0; i < _tasks.length; i++) {
        final task = _tasks[i];

        // Skip completed tasks
        if (task.isCompleted) continue;

        // Get new schedule
        final schedule = _scheduleTask(task);

        // Update task with new schedule
        _tasks[i] = Task(
          id: task.id,
          title: task.title,
          category: task.category,
          dueDate: task.dueDate,
          urgencyLevel: task.urgencyLevel,
          priority: task.priority,
          isCompleted: task.isCompleted,
          estimatedDuration: task.estimatedDuration,
          scheduledDay: schedule['day'],
          scheduledTimeSlot: schedule['timeSlot'],
          scheduledTimeDescription: TaskScheduler.getScheduleDescription(
            schedule['day'],
            schedule['timeSlotName'],
          ),
        );

        // Re-schedule notifications
        NotificationService.instance.cancelTaskNotifications(task.id);
        _scheduleTaskNotifications(_tasks[i]);
      }

      // Save all updated tasks
      await _saveTasks();

      notifyListeners();
    } catch (e) {
      print("Error rescheduling tasks: $e");
    }
  }

  // Method to schedule task notifications
  void _scheduleTaskNotifications(Task task) {
    if (task.isCompleted) return;

    // Schedule reminder notification (30 minutes before deadline for high priority)
    int minutesBefore = task.priority == 'High' ? 30 : 15;
    NotificationService.instance.scheduleTaskNotification(
      task,
      minutesBefore: minutesBefore,
    );

    // Schedule deadline notification
    NotificationService.instance.scheduleDeadlineNotification(task);

    // If the task has schedule information, add a scheduled notification
    if (task.scheduledDay != null && task.scheduledTimeSlot != null) {
      NotificationService.instance.scheduleTaskAtTime(task);
    }
  }

  // Schedule daily digest
  void scheduleDailyDigest() {
    // Get today's tasks
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final todaysTasks =
        _tasks
            .where(
              (task) =>
                  task.dueDate.isAfter(today) &&
                  task.dueDate.isBefore(tomorrow),
            )
            .toList();

    NotificationService.instance.scheduleDailyDigest(todaysTasks);
  }

  // Get tasks by category
  List<Task> getTasksByCategory(String category) {
    if (category == 'All') {
      return _tasks;
    }
    return _tasks.where((task) => task.category == category).toList();
  }

  // Search tasks
  List<Task> searchTasks(String query) {
    if (query.isEmpty) {
      return _tasks;
    }
    return _tasks
        .where((task) => task.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Get AI suggestions (top priority tasks)
  List<Task> getAiSuggestions() {
    // Get uncompleted high priority tasks
    final highPriorityTasks =
        _tasks
            .where((task) => !task.isCompleted && task.priority == 'High')
            .toList();

    // Sort by due date (soonest first)
    highPriorityTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    // Return top 3 or fewer if not enough high priority tasks
    return highPriorityTasks.take(3).toList();
  }

  // Ensure provider is initialized before operations
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _init();
    }
  }

  // Remember to dispose of the subscription
  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }
}
