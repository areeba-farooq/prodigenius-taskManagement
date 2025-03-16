
import 'package:flutter/material.dart';
import 'package:taskgenius/models/task.dart';

class TaskProvider extends ChangeNotifier {
  final List<Task> _tasks = [];
  final List<String> _categories = [
    'Work',
    'Study',
    'Personal',
    'Shopping',
    'Health',
  ];

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

  void addTask(Task task) {
    _tasks.add(task);
    notifyListeners();
  }

  void addCategory(String category) {
    if (!_categories.contains(category)) {
      _categories.add(category);
      notifyListeners();
    }
  }
  
  // Toggle task completion status (needed for checkboxes)
  void toggleTaskCompletion(String taskId) {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      _tasks[index] = Task(
        id: _tasks[index].id,
        title: _tasks[index].title,
        category: _tasks[index].category,
        dueDate: _tasks[index].dueDate,
        urgencyLevel: _tasks[index].urgencyLevel,
        priority: _tasks[index].priority,
        isCompleted: !_tasks[index].isCompleted,
      );
      notifyListeners();
    }
  }
  
  // Update an existing task
  void updateTask(Task updatedTask) {
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      notifyListeners();
    }
  }
  
  // Delete a task
  void deleteTask(String taskId) {
    _tasks.removeWhere((task) => task.id == taskId);
    notifyListeners();
  }
  
  // Get tasks by category (needed for category filtering)
  List<Task> getTasksByCategory(String category) {
    if (category == 'All') {
      return _tasks;
    }
    return _tasks.where((task) => task.category == category).toList();
  }
  
  // Get tasks with search query (for search functionality)
  List<Task> searchTasks(String query) {
    if (query.isEmpty) {
      return _tasks;
    }
    return _tasks.where((task) => 
      task.title.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
  
  // Get AI suggestions (top priority tasks)
  List<Task> getAiSuggestions() {
    // Get uncompleted high priority tasks
    final highPriorityTasks = _tasks
        .where((task) => !task.isCompleted && task.priority == 'High')
        .toList();
    
    // Sort by due date (soonest first)
    highPriorityTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    
    // Return top 3 or fewer if not enough high priority tasks
    return highPriorityTasks.take(3).toList();
  }
}
