// import 'package:flutter/material.dart';
// import 'package:taskgenius/models/task.dart';

// class TaskProvider extends ChangeNotifier {
//   final List<Task> _tasks = [];
//   final List<String> _categories = [
//     'Work',
//     'Study',
//     'Personal',
//     'Shopping',
//     'Health',
//   ];

//   List<Task> get tasks => _tasks;
//   List<String> get categories => _categories;

//   // Get tasks sorted by priority
//   List<Task> get prioritizedTasks {
//     // Create a copy to avoid modifying the original list
//     final sortedTasks = List<Task>.from(_tasks);

//     // Sort by priority (High > Medium > Low)
//     sortedTasks.sort((a, b) {
//       // First sort by priority
//       final priorityOrder = {'High': 0, 'Medium': 1, 'Low': 2};
//       final priorityComparison = priorityOrder[a.priority]!.compareTo(
//         priorityOrder[b.priority]!,
//       );

//       // If same priority, sort by due date
//       if (priorityComparison == 0) {
//         return a.dueDate.compareTo(b.dueDate);
//       }

//       return priorityComparison;
//     });

//     return sortedTasks;
//   }

//   void addTask(Task task) {
//     _tasks.add(task);
//     notifyListeners();
//   }

//   void addCategory(String category) {
//     if (!_categories.contains(category)) {
//       _categories.add(category);
//       notifyListeners();
//     }
//   }

//   // Toggle task completion status (needed for checkboxes)
//   void toggleTaskCompletion(String taskId) {
//     final index = _tasks.indexWhere((task) => task.id == taskId);
//     if (index != -1) {
//       _tasks[index] = Task(
//         id: _tasks[index].id,
//         title: _tasks[index].title,
//         category: _tasks[index].category,
//         dueDate: _tasks[index].dueDate,
//         urgencyLevel: _tasks[index].urgencyLevel,
//         priority: _tasks[index].priority,
//         isCompleted: !_tasks[index].isCompleted,
//       );
//       notifyListeners();
//     }
//   }

//   // Update an existing task
//   void updateTask(Task updatedTask) {
//     final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
//     if (index != -1) {
//       _tasks[index] = updatedTask;
//       notifyListeners();
//     }
//   }

//   // Delete a task
//   void deleteTask(String taskId) {
//     _tasks.removeWhere((task) => task.id == taskId);
//     notifyListeners();
//   }

//   // Get tasks by category (needed for category filtering)
//   List<Task> getTasksByCategory(String category) {
//     if (category == 'All') {
//       return _tasks;
//     }
//     return _tasks.where((task) => task.category == category).toList();
//   }

//   // Get tasks with search query (for search functionality)
//   List<Task> searchTasks(String query) {
//     if (query.isEmpty) {
//       return _tasks;
//     }
//     return _tasks.where((task) =>
//       task.title.toLowerCase().contains(query.toLowerCase())
//     ).toList();
//   }

//   // Get AI suggestions (top priority tasks)
//   List<Task> getAiSuggestions() {
//     // Get uncompleted high priority tasks
//     final highPriorityTasks = _tasks
//         .where((task) => !task.isCompleted && task.priority == 'High')
//         .toList();

//     // Sort by due date (soonest first)
//     highPriorityTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

//     // Return top 3 or fewer if not enough high priority tasks
//     return highPriorityTasks.take(3).toList();
//   }
// }

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:taskgenius/models/task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskgenius/services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  static const String _tasksBoxName = 'tasks';
  static const String _categoriesKey = 'task_categories';

  late Box<Task> _tasksBox;
  List<Task> _tasks = [];
  List<String> _categories = [
    'Work',
    'Study',
    'Personal',
    'Shopping',
    'Health',
  ];

  bool _isInitialized = false;

  // Constructor
  TaskProvider() {
    _initHive();
  }

  // Initialize Hive and load data
  Future<void> _initHive() async {
    if (!_isInitialized) {
      _tasksBox = await Hive.openBox<Task>(_tasksBoxName);
      await _loadTasks();
      await _loadCategories();
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Load tasks from Hive
  Future<void> _loadTasks() async {
    _tasks = _tasksBox.values.toList();
  }

  // Load categories from SharedPreferences
  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCategories = prefs.getStringList(_categoriesKey);
    if (savedCategories != null && savedCategories.isNotEmpty) {
      _categories = savedCategories;
    } else {
      // Save default categories if none exist
      await _saveCategories();
    }
  }

  // Save categories to SharedPreferences
  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_categoriesKey, _categories);
  }

  // Check if provider is initialized
  bool get isInitialized => _isInitialized;

  // Getters
  List<Task> get tasks => _tasks;
  List<String> get categories => _categories;

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

  // Add a new task
  Future<void> addTask(Task task) async {
    await _ensureInitialized();
    // Add to Hive
    await _tasksBox.put(task.id, task);
    // Update memory list
    _tasks.add(task);
      // Schedule notifications for the new task
    _scheduleTaskNotifications(task);
    notifyListeners();
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
  // Update toggleTaskCompletion method
  void toggleTaskCompletion(String taskId) {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      final oldTask = _tasks[index];
      
      // Create a new task with the updated completion status
      _tasks[index] = Task(
        id: oldTask.id,
        title: oldTask.title,
        category: oldTask.category,
        dueDate: oldTask.dueDate,
        urgencyLevel: oldTask.urgencyLevel,
        priority: oldTask.priority,
        isCompleted: !oldTask.isCompleted,
      );
      
      // If task is now completed, cancel notifications
      if (_tasks[index].isCompleted) {
        NotificationService.instance.cancelTaskNotifications(taskId);
      } 
      // If task is now uncompleted, schedule notifications
      else {
        _scheduleTaskNotifications(_tasks[index]);
      }
      
      notifyListeners();
    }
  }
  // Future<void> toggleTaskCompletion(String taskId) async {
  //   await _ensureInitialized();
  //   final index = _tasks.indexWhere((task) => task.id == taskId);
  //   if (index != -1) {
  //     final task = _tasks[index];
  //     final updatedTask = task.copyWith(isCompleted: !task.isCompleted);

  //     // Update in Hive
  //     await _tasksBox.put(taskId, updatedTask);

  //     // Update in memory
  //     _tasks[index] = updatedTask;
  //     notifyListeners();
  //   }
  // }

  // Update an existing task
  // Update updateTask method
  void updateTask(Task updatedTask) {
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      // Get the old task before updating
      final oldTask = _tasks[index];
      
      // Update task in the list
      _tasks[index] = updatedTask;
      
      // Cancel existing notifications if the task was completed
      if (!oldTask.isCompleted && updatedTask.isCompleted) {
        NotificationService.instance.cancelTaskNotifications(updatedTask.id);
      } 
      // Reschedule notifications if the task details changed
      else if (!updatedTask.isCompleted && 
              (oldTask.dueDate != updatedTask.dueDate || 
               oldTask.priority != updatedTask.priority)) {
        NotificationService.instance.cancelTaskNotifications(updatedTask.id);
        _scheduleTaskNotifications(updatedTask);
      }
      
      notifyListeners();
    }
  }
  // Future<void> updateTask(Task updatedTask) async {
  //   await _ensureInitialized();
  //   final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
  //   if (index != -1) {
  //     // Update in Hive
  //     await _tasksBox.put(updatedTask.id, updatedTask);

  //     // Update in memory
  //     _tasks[index] = updatedTask;
  //     notifyListeners();
  //   }
  // }

  // Delete a task
   // Update deleteTask method
  void deleteTask(String taskId) {
    // Cancel notifications before deleting
    NotificationService.instance.cancelTaskNotifications(taskId);
    
    _tasks.removeWhere((task) => task.id == taskId);
    notifyListeners();
  }
  // New helper method to schedule task notifications
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
  }
   // New method to schedule daily digest
  void scheduleDailyDigest() {
    // Get today's tasks
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    final todaysTasks = _tasks.where((task) => 
      task.dueDate.isAfter(today) && 
      task.dueDate.isBefore(tomorrow)
    ).toList();
    
    NotificationService.instance.scheduleDailyDigest(todaysTasks);
  }

  // Future<void> deleteTask(String taskId) async {
  //   await _ensureInitialized();
  //   // Delete from Hive
  //   await _tasksBox.delete(taskId);

  //   // Delete from memory
  //   _tasks.removeWhere((task) => task.id == taskId);
  //   notifyListeners();
  // }

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
      await _initHive();
    }
  }

  // Clear all tasks (for testing or reset functionality)
  Future<void> clearAllTasks() async {
    await _ensureInitialized();
    await _tasksBox.clear();
    _tasks = [];
    notifyListeners();
  }
}
