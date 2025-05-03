//******************************************** */
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskgenius/models/task.dart';
import 'package:taskgenius/services/ai_service.dart';
import 'package:taskgenius/services/notification_service.dart';
import 'package:taskgenius/services/productivity_Service.dart';

class TaskProvider extends ChangeNotifier {
  // Add user ID to make keys user-specific
  String? _currentUserId;

  // Update keys to include user ID
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

  // static const String _tasksKey = 'tasks_data';
  // static const String _categoriesKey = 'task_categories';
  // static const String _userPreferencesKey = 'user_preferences';

  List<Task> _tasks = [];
  List<String> _categories = [
    'Work',
    'Study',
    'Personal',
    'Shopping',
    'Health',
    'Travel',
  ];

  // User preferences for scheduling
  Map<String, dynamic> _userPreferences = {
    'availableHours': 8, // Default to 8 hours available per day
    'timePreference':
        1, // Default to Afternoon (0=Morning, 1=Afternoon, 2=Evening)
  };

  bool _isInitialized = false;

  // Constructor
  TaskProvider() {
    // _init();
  }
  Future<void> setUser(String userId) async {
    if (_currentUserId == userId && _isInitialized) {
      return; // Already initialized for this user
    }

    _currentUserId = userId;
    _isInitialized = false;

    // Reset data
    _tasks.clear();
    _categories = ['Work', 'Study', 'Personal', 'Shopping', 'Health', 'Travel'];
    _userPreferences = {'availableHours': 8, 'timePreference': 1};

    await _init();
  }

  // Clear data when user logs out
  void clearUser() {
    _currentUserId = null;
    _isInitialized = false;
    _tasks.clear();
    _categories = ['Work', 'Study', 'Personal', 'Shopping', 'Health', 'Travel'];
    _userPreferences = {'availableHours': 8, 'timePreference': 1};
    notifyListeners();
  }

  // Initialize and load data
  Future<void> _init() async {
    if (!_isInitialized) {
      await _loadTasks();
      await _loadCategories();
      await _loadUserPreferences();
      _isInitialized = true;
      notifyListeners();
      print("TaskProvider initialized with ${_tasks.length} tasks");
    }
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
        // Save default categories if none exist
        await _saveCategories();
      }
    } catch (e) {
      print("Error loading categories: $e");
      // Keep using the default categories
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
        // Save default preferences if none exist
        await _saveUserPreferences();
      }
    } catch (e) {
      print("Error loading user preferences: $e");
      // Keep using the default preferences
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

  // Check if provider is initialized
  bool get isInitialized => _isInitialized;

  // Getters
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
    await _ensureInitialized();

    if (availableHours != null) {
      _userPreferences['availableHours'] = availableHours;
    }

    if (timePreference != null) {
      _userPreferences['timePreference'] = timePreference;
    }

    await _saveUserPreferences();
    notifyListeners();
  }

  // Add a new task
  Future<void> addTask(Task task) async {
    try {
      await _ensureInitialized();

      // Debug: Print the task being added
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

      // Add task to list
      _tasks.add(scheduledTask);

      // Save all tasks to SharedPreferences
      await _saveTasks();

      // Schedule notifications for the new task
      _scheduleTaskNotifications(scheduledTask);

      // Debug: Print current task count
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

  // Add a new category
  Future<void> addCategory(String category) async {
    await _ensureInitialized();
    if (!_categories.contains(category)) {
      _categories.add(category);
      await _saveCategories();
      notifyListeners();
    }
  }

  // Toggle task completion status
  // Future<void> toggleTaskCompletion(String taskId) async {
  //   try {
  //     await _ensureInitialized();

  //     final index = _tasks.indexWhere((task) => task.id == taskId);
  //     if (index != -1) {
  //       final oldTask = _tasks[index];

  //       // Create a new task with the updated completion status
  //       final updatedTask = Task(
  //         id: oldTask.id,
  //         title: oldTask.title,
  //         category: oldTask.category,
  //         dueDate: oldTask.dueDate,
  //         urgencyLevel: oldTask.urgencyLevel,
  //         priority: oldTask.priority,
  //         isCompleted: !oldTask.isCompleted,
  //         estimatedDuration: oldTask.estimatedDuration,
  //         scheduledDay: oldTask.scheduledDay,
  //         scheduledTimeSlot: oldTask.scheduledTimeSlot,
  //         scheduledTimeDescription: oldTask.scheduledTimeDescription,
  //       );

  //       // Update the task in the list
  //       _tasks[index] = updatedTask;

  //       // Save updated tasks
  //       await _saveTasks();

  //       // If task is now completed, cancel notifications
  //       if (updatedTask.isCompleted) {
  //         NotificationService.instance.cancelTaskNotifications(taskId);
  //       }
  //       // If task is now uncompleted, schedule notifications
  //       else {
  //         _scheduleTaskNotifications(updatedTask);
  //       }

  //       notifyListeners();
  //     }
  //   } catch (e) {
  //     print("Error toggling task completion: $e");
  //   }
  // }

  // Modified toggleTaskCompletion method
  Future<void> toggleTaskCompletion(String taskId) async {
    try {
      await _ensureInitialized();

      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        final oldTask = _tasks[index];

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
        );

        // Update the task in the list
        _tasks[index] = updatedTask;

        // Save updated tasks
        await _saveTasks();

        // If task is now completed, record the completion
        if (updatedTask.isCompleted && !oldTask.isCompleted) {
          await ProductivityService.recordTaskCompletion(updatedTask);
          NotificationService.instance.cancelTaskNotifications(taskId);
        }
        // If task is now uncompleted, schedule notifications
        else if (!updatedTask.isCompleted && oldTask.isCompleted) {
          _scheduleTaskNotifications(updatedTask);
        }

        notifyListeners();
      }
    } catch (e) {
      print("Error toggling task completion: $e");
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
      await _ensureInitialized();

      final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
      if (index != -1) {
        // Get the old task before updating
        final oldTask = _tasks[index];

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
          );
        }

        // Update task in the list
        _tasks[index] = taskToUpdate;

        // Save updated tasks
        await _saveTasks();

        // Cancel existing notifications if the task was completed
        if (!oldTask.isCompleted && taskToUpdate.isCompleted) {
          NotificationService.instance.cancelTaskNotifications(taskToUpdate.id);
        }
        // Reschedule notifications if the task details changed
        else if (!taskToUpdate.isCompleted) {
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
      await _ensureInitialized();

      // Cancel notifications before deleting
      NotificationService.instance.cancelTaskNotifications(taskId);

      // Remove task from list
      _tasks.removeWhere((task) => task.id == taskId);

      // Save updated tasks
      await _saveTasks();

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

  // Helper method to schedule task notifications
  void _scheduleTaskNotifications(Task task) {
    // Skip completed tasks
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

  // Clear all tasks (for testing or reset functionality)
  Future<void> clearAllTasks() async {
    try {
      await _ensureInitialized();
      _tasks = [];
      await _saveTasks();
      notifyListeners();
    } catch (e) {
      print("Error clearing tasks: $e");
    }
  }
}
