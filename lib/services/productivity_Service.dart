import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskgenius/models/task.dart';
import 'dart:convert';

class ProductivityService {
  static const String _completionHistoryKey = 'task_completion_history';
  static const String _productivityInsightsKey = 'productivity_insights';

  // Save task completion event
  static Future<void> recordTaskCompletion(Task task) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getCompletionHistory();
      
      // Create completion record
      final completionRecord = {
        'taskId': task.id,
        'category': task.category,
        'priority': task.priority,
        'completedAt': DateTime.now().toIso8601String(),
        'dayOfWeek': DateTime.now().weekday,
        'hourOfDay': DateTime.now().hour,
        'duration': task.estimatedDuration.inMinutes,
      };
      
      history.add(completionRecord);
      
      // Keep only last 100 completions to avoid storage issues
      if (history.length > 100) {
        history.removeAt(0);
      }
      
      await prefs.setString(_completionHistoryKey, jsonEncode(history));
    } catch (e) {
      debugPrint('Error recording task completion: $e');
    }
  }

  // Get completion history
  static Future<List<Map<String, dynamic>>> getCompletionHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_completionHistoryKey);
      
      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        return decoded.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      debugPrint('Error getting completion history: $e');
      return [];
    }
  }

  // Calculate completion rate for the last 7 days
  static Future<double> getWeeklyCompletionRate(List<Task> allTasks) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(Duration(days: 7));
    
    final tasksInPeriod = allTasks.where((task) => 
      task.dueDate.isAfter(weekAgo) && task.dueDate.isBefore(now)
    ).toList();
    
    if (tasksInPeriod.isEmpty) return 0.0;
    
    final completedTasks = tasksInPeriod.where((task) => task.isCompleted).length;
    return completedTasks / tasksInPeriod.length;
  }

  // Get productivity by day of week
  static Future<Map<String, int>> getProductivityByDayOfWeek() async {
    final history = await getCompletionHistory();
    final Map<String, int> productivityByDay = {
      'Monday': 0,
      'Tuesday': 0,
      'Wednesday': 0,
      'Thursday': 0,
      'Friday': 0,
      'Saturday': 0,
      'Sunday': 0,
    };
    
    for (var record in history) {
      final dayOfWeek = record['dayOfWeek'] as int;
      final dayName = _getDayName(dayOfWeek);
      productivityByDay[dayName] = (productivityByDay[dayName] ?? 0) + 1;
    }
    
    return productivityByDay;
  }

  // Get most productive day
  static Future<String> getMostProductiveDay() async {
    final productivityByDay = await getProductivityByDayOfWeek();
    
    String mostProductiveDay = 'Monday';
    int maxTasks = 0;
    
    productivityByDay.forEach((day, count) {
      if (count > maxTasks) {
        maxTasks = count;
        mostProductiveDay = day;
      }
    });
    
    return mostProductiveDay;
  }

  // Get productivity by hour
  static Future<Map<int, int>> getProductivityByHour() async {
    final history = await getCompletionHistory();
    final Map<int, int> productivityByHour = {};
    
    for (var record in history) {
      final hour = record['hourOfDay'] as int;
      productivityByHour[hour] = (productivityByHour[hour] ?? 0) + 1;
    }
    
    return productivityByHour;
  }

  // Get most productive hours
  static Future<String> getMostProductiveTimeOfDay() async {
    final productivityByHour = await getProductivityByHour();
    
    int morningTasks = 0;  // 5 AM - 12 PM
    int afternoonTasks = 0; // 12 PM - 5 PM
    int eveningTasks = 0;  // 5 PM - 9 PM
    int nightTasks = 0;    // 9 PM - 5 AM
    
    productivityByHour.forEach((hour, count) {
      if (hour >= 5 && hour < 12) morningTasks += count;
      else if (hour >= 12 && hour < 17) afternoonTasks += count;
      else if (hour >= 17 && hour < 21) eveningTasks += count;
      else nightTasks += count;
    });
    
    int maxTasks = morningTasks;
    String mostProductiveTime = 'Morning';
    
    if (afternoonTasks > maxTasks) {
      maxTasks = afternoonTasks;
      mostProductiveTime = 'Afternoon';
    }
    if (eveningTasks > maxTasks) {
      maxTasks = eveningTasks;
      mostProductiveTime = 'Evening';
    }
    if (nightTasks > maxTasks) {
      mostProductiveTime = 'Night';
    }
    
    return mostProductiveTime;
  }

  // Get productivity by category
  static Future<Map<String, int>> getProductivityByCategory() async {
    final history = await getCompletionHistory();
    final Map<String, int> productivityByCategory = {};
    
    for (var record in history) {
      final category = record['category'] as String;
      productivityByCategory[category] = (productivityByCategory[category] ?? 0) + 1;
    }
    
    return productivityByCategory;
  }

  // Generate productivity insights
  static Future<List<String>> generateProductivityInsights(List<Task> allTasks) async {
    final insights = <String>[];
    
    try {
      // Get most productive day
      final mostProductiveDay = await getMostProductiveDay();
      insights.add('You are most productive on ${mostProductiveDay}s');
      
      // Get most productive time
      final mostProductiveTime = await getMostProductiveTimeOfDay();
      insights.add('You complete most tasks in the $mostProductiveTime');
      
      // Get completion rate
      final completionRate = await getWeeklyCompletionRate(allTasks);
      final percentage = (completionRate * 100).toStringAsFixed(1);
      insights.add('Your task completion rate this week: $percentage%');
      
      // Get category insights
      final categoryProductivity = await getProductivityByCategory();
      if (categoryProductivity.isNotEmpty) {
        final mostProductiveCategory = categoryProductivity.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
        insights.add('You complete the most $mostProductiveCategory tasks');
      }
      
      // Get streak information
      final streak = await getCompletionStreak();
      if (streak > 1) {
        insights.add('You\'re on a $streak day completion streak!');
      }
      
      // Save insights
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_productivityInsightsKey, insights);
      
    } catch (e) {
      debugPrint('Error generating insights: $e');
      insights.add('Keep completing tasks to see your productivity insights!');
    }
    
    return insights;
  }

  // Get completion streak
  static Future<int> getCompletionStreak() async {
    final history = await getCompletionHistory();
    if (history.isEmpty) return 0;
    
    // Sort by completion date
    history.sort((a, b) => 
      DateTime.parse(b['completedAt']).compareTo(DateTime.parse(a['completedAt']))
    );
    
    int streak = 0;
    DateTime? lastDate;
    
    for (var record in history) {
      final completedAt = DateTime.parse(record['completedAt']);
      final completedDate = DateTime(completedAt.year, completedAt.month, completedAt.day);
      
      if (lastDate == null) {
        // First task, start streak
        streak = 1;
        lastDate = completedDate;
      } else {
        // Check if this task was completed on the same day or the day before
        final dayDifference = lastDate.difference(completedDate).inDays;
        
        if (dayDifference == 0) {
          // Same day, continue
          continue;
        } else if (dayDifference == 1) {
          // Consecutive day, increment streak
          streak++;
          lastDate = completedDate;
        } else {
          // Streak broken
          break;
        }
      }
    }
    
    return streak;
  }

  // Helper method to convert day number to name
  static String _getDayName(int dayNumber) {
    switch (dayNumber) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Unknown';
    }
  }
}