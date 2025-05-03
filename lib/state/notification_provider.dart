
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskgenius/models/notification.dart';
import 'package:taskgenius/models/task.dart';
import 'package:taskgenius/services/database_service.dart';

class NotificationProvider extends ChangeNotifier {
  static const String _notificationsKey = 'app_notifications';
  final FirestoreService _firestoreService = FirestoreService();
  String? _currentUserId;
  StreamSubscription<List<AppNotification>>? _notificationsSubscription;

  List<AppNotification> _notifications = [];
  bool _isInitialized = false;
  int _unreadCount = 0;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get hasUnread => _unreadCount > 0;
  DateTime _lastViewedTimestamp = DateTime(2000); 
  static const String _lastViewedKey = 'last_viewed_notifications';

  
  Future<void> setUser(String userId) async {
    if (_currentUserId == userId) return;

    _currentUserId = userId;
    await _notificationsSubscription?.cancel();

    // Subscribe to notifications
    _notificationsSubscription = _firestoreService
        .getNotifications(userId)
        .listen((notifications) {
          _notifications = notifications;
          _recalculateUnreadCount();
          notifyListeners();
        });
  }

  
  void clearUser() {
    _currentUserId = null;
    _notifications.clear();
    _unreadCount = 0;
    _notificationsSubscription?.cancel();
    notifyListeners();
  }

  
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


  void _recalculateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }


  //Add notification using Firestore
  Future<void> addNotification(AppNotification notification) async {
    if (_currentUserId == null) return;

    try {
      await _firestoreService.saveNotification(_currentUserId!, notification);
      
    } catch (e) {
      print('Error adding notification: $e');
    }
  }

  // Remove notification using Firestore
  Future<void> removeNotification(String notificationId) async {
    if (_currentUserId == null) return;

    try {
      await _firestoreService.deleteNotification(
        _currentUserId!,
        notificationId,
      );
      
    } catch (e) {
      print('Error removing notification: $e');
    }
  }

  // Mark as read using Firestore
  Future<void> markAsRead(String notificationId) async {
    if (_currentUserId == null) return;

    try {
      await _firestoreService.markNotificationAsRead(
        _currentUserId!,
        notificationId,
      );
      
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  // Mark all as read using Firestore
  Future<void> markAllAsRead() async {
    if (_currentUserId == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      for (var notification in _notifications) {
        if (!notification.isRead) {
          final docRef = FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUserId!)
              .collection('notifications')
              .doc(notification.id);
          batch.update(docRef, {'isRead': true});
        }
      }

      await batch.commit();
      
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  // Clear all using Firestore
  Future<void> clearAll() async {
    if (_currentUserId == null) return;

    try {
      await _firestoreService.clearAllNotifications(_currentUserId!);
      
    } catch (e) {
      print('Error clearing all notifications: $e');
    }
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
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

 
}
