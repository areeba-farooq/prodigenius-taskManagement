// lib/state/notification_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskgenius/models/notification.dart';
import 'package:taskgenius/models/task.dart';

class NotificationProvider extends ChangeNotifier {
  static const String _notificationsKey = 'app_notifications';

  List<AppNotification> _notifications = [];
  bool _isInitialized = false;
  int _unreadCount = 0;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get hasUnread => _unreadCount > 0;
  DateTime _lastViewedTimestamp = DateTime(2000); // Default to old date
  static const String _lastViewedKey = 'last_viewed_notifications';

  // Add these getters
  bool get hasNewNotifications {
    // Check if there are notifications newer than the last viewed timestamp
    return _notifications.any((n) => n.timestamp.isAfter(_lastViewedTimestamp));
  }
// Get count of notifications by type
  int countNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).length;
  }

  // Get unread count by type
  int getUnreadCountByType(NotificationType type) {
    return _notifications.where((n) => n.type == type && !n.isRead).length;
  }

  NotificationProvider() {
    _init();
  }
  // Add this method to update the last viewed timestamp
  Future<void> updateLastViewed() async {
    _lastViewedTimestamp = DateTime.now();

    // Save to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _lastViewedKey,
        _lastViewedTimestamp.toIso8601String(),
      );
      debugPrint("Updated last viewed timestamp: $_lastViewedTimestamp");

      // Notify listeners to update the UI
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving last viewed timestamp: $e');
    }
  }

  Future<void> _init() async {
    if (!_isInitialized) {
      debugPrint("Initializing NotificationProvider...");

      // Get SharedPreferences instance once
      final prefs = await SharedPreferences.getInstance();

      // Load last viewed timestamp
      final lastViewedString = prefs.getString(_lastViewedKey);
      if (lastViewedString != null) {
        try {
          _lastViewedTimestamp = DateTime.parse(lastViewedString);
          debugPrint("Loaded last viewed timestamp: $_lastViewedTimestamp");
        } catch (e) {
          debugPrint("Error parsing last viewed timestamp: $e");
        }
      }

      // Load notifications
      await _loadNotifications();

      _isInitialized = true;
      debugPrint(
        "NotificationProvider initialized with ${_notifications.length} notifications",
      );
      debugPrint("Unread count: $_unreadCount");
      notifyListeners();
    }
  }


  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_notificationsKey);

      if (notificationsJson != null) {
        _notifications =
            notificationsJson
                .map((json) => AppNotification.fromMap(jsonDecode(json)))
                .toList();

        // Sort by timestamp (newest first)
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        // Count unread notifications
        _unreadCount = _notifications.where((n) => !n.isRead).length;
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  // Add to your NotificationProvider class
  Future<void> removeNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    _recalculateUnreadCount();
    await _saveNotifications();
    notifyListeners();
  }

  // Add this helper method
  void _recalculateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson =
          _notifications.map((n) => jsonEncode(n.toMap())).toList();

      await prefs.setStringList(_notificationsKey, notificationsJson);
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }

  // Add a new notification
  // Modification to the addNotification method for better debugging
  Future<void> addNotification(AppNotification notification) async {
    debugPrint("Adding notification to provider: ${notification.title}");
    _notifications.insert(0, notification); // Add to beginning of list
    _unreadCount++;
    debugPrint("New unread count: $_unreadCount");

    // Limit to most recent 50 notifications
    if (_notifications.length > 50) {
      _notifications.removeLast();
    }

    await _saveNotifications();
    debugPrint("Notification saved to storage, notifying listeners");
    notifyListeners();
  }

  // Create and add a task reminder notification
  Future<void> addTaskReminderNotification(Task task) async {
    String title;
    if (task.priority == 'High') {
      title = '🔴 High Priority Task Reminder';
    } else if (task.priority == 'Medium') {
      title = '🟠 Task Reminder';
    } else {
      title = '🟢 Task Reminder';
    }

    final notification = AppNotification(
      id: 'reminder-${task.id}-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: '${task.title} is due soon!',
      timestamp: DateTime.now(),
      taskId: task.id,
      type: NotificationType.task,
    );

    await addNotification(notification);
  }

  // Create and add a deadline notification
  Future<void> addDeadlineNotification(Task task) async {
    final notification = AppNotification(
      id: 'deadline-${task.id}-${DateTime.now().millisecondsSinceEpoch}',
      title: '⏰ Task Deadline',
      body: '${task.title} is due now!',
      timestamp: DateTime.now(),
      taskId: task.id,
      type: NotificationType.deadline,
    );

    await addNotification(notification);
  }

  // Create and add a daily digest notification
  Future<void> addDigestNotification(
    int totalTasks,
    int highPriorityTasks,
  ) async {
    String body = 'You have $totalTasks tasks today';

    if (highPriorityTasks > 0) {
      body +=
          ', including $highPriorityTasks high priority ${highPriorityTasks == 1 ? 'task' : 'tasks'}.';
    } else {
      body += '.';
    }

    final notification = AppNotification(
      id: 'digest-${DateTime.now().millisecondsSinceEpoch}',
      title: '📋 Today\'s Tasks',
      body: body,
      timestamp: DateTime.now(),
      type: NotificationType.digest,
    );

    await addNotification(notification);
  }

  // Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      _unreadCount--;
      await _saveNotifications();
      notifyListeners();
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    bool hasChanges = false;

    for (var notification in _notifications) {
      if (!notification.isRead) {
        notification.isRead = true;
        hasChanges = true;
      }
    }

    if (hasChanges) {
      _unreadCount = 0;
      await _saveNotifications();
      notifyListeners();
    }
  }

  // Clear all notifications
  Future<void> clearAll() async {
    _notifications.clear();
    _unreadCount = 0;
    await _saveNotifications();
    notifyListeners();
  }
}
