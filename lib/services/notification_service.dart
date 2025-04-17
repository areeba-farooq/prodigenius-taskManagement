import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskgenius/models/notification.dart';
import 'package:taskgenius/state/notification_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:taskgenius/models/task.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static NotificationService? _instance;

  // Singleton pattern
  static NotificationService get instance {
    _instance ??= NotificationService._();
    return _instance!;
  }

  NotificationService._();
  // Add this field to the NotificationService class
  late NotificationProvider _notificationProvider;

  // Add this method to the NotificationService class
  void setNotificationProvider(NotificationProvider provider) {
    _notificationProvider = provider;
      debugPrint("Notification provider set successfully inside service");

  }

  Future<void> initialize() async {
    // Initialize for Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialize for iOS
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Combine platform-specific settings
    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    // Initialize notification plugin
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (
        NotificationResponse notificationResponse,
      ) async {
        // Handle notification taps here
        debugPrint("Notification tapped: ${notificationResponse.payload}");
        // You can navigate to the specific task details when tapping the notification
      },
    );

    // Initialize timezone package and set local timezone
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    debugPrint("Notification service initialized with timezone: $timeZoneName");

    // Request permissions
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Request Android permissions
    if (defaultTargetPlatform == TargetPlatform.android) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }

    // Request iOS permissions
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  // Check if reminders are enabled
  Future<bool> areRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('enable_reminders') ?? true;
  }

  // Check if deadline alerts are enabled
  Future<bool> areDeadlineAlertsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('enable_deadline_alerts') ?? true;
  }

  // Check if daily digest is enabled
  Future<bool> isDailyDigestEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('enable_daily_digest') ?? true;
  }

  // Schedule a notification for a specific time
  Future<void> scheduleTaskNotification(
    Task task, {
    int minutesBefore = 30,
  }) async {
    // Check if reminders are enabled
    if (!(await areRemindersEnabled())) {
      debugPrint("Task reminders are disabled by user preference");
      return;
    }

    if (task.isCompleted) {
      debugPrint(
        "Not scheduling notification for completed task: ${task.title}",
      );
      return;
    }

    final int notificationId = task.id.hashCode;

    // Calculate notification time based on due date
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      task.dueDate.subtract(Duration(minutes: minutesBefore)),
      tz.local,
    );

    // Don't schedule if the time is in the past
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint("Not scheduling notification for past time: ${task.title}");
      return;
    }

    // Notification details for Android
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'task_reminder_channel',
          'Task Reminders',
          channelDescription: 'Notifications for upcoming tasks',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(_getPriorityColor(task.priority)),
          ledColor: Color(_getPriorityColor(task.priority)),
          ledOnMs: 1000,
          ledOffMs: 500,
        );

    // Notification details for iOS
    final DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      badgeNumber: 1,
    );

    // Combined notification details
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    // Generate notification title and body based on task priority
    String title;
    String body;

    if (task.priority == 'High') {
      title = '🔴 High Priority Task Reminder';
      body = '${task.title} is due soon! This task is marked as high priority.';
    } else if (task.priority == 'Medium') {
      title = '🟠 Task Reminder';
      body = '${task.title} is due soon.';
    } else {
      title = '🟢 Task Reminder';
      body = 'Don\'t forget about: ${task.title}';
    }

    // Schedule the notification
    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: task.id, // Pass the task ID as the payload
    );
    // After scheduling
    await _addToNotificationProvider(
      title,
      body,
      NotificationType.task,
      task.id,
    );

    debugPrint(
      "Scheduled notification for task: ${task.title} at ${scheduledDate.toString()}",
    );
  }

  // In notification_service.dart
  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          channelDescription: 'Channel for testing notifications',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
      999, // Test notification ID
      'Test Notification',
      'This is a test notification from Task Genius',
      notificationDetails,
    );

  

    debugPrint("Test notification shown");
  }

 // Update to the testNotificationFlow method
Future<void> testNotificationFlow() async {
  // Show a system notification
  await showTestNotification();
  
  // Then add to the notification provider
  await _addToNotificationProvider(
    'Test Notification',
    'This is a test notification to verify the notification flow works correctly.',
    NotificationType.task,
    null,
  );

  debugPrint("Test notification flow complete. Check notification screen and unread count.");
}
  // Schedule deadline notification (for when the task is due)
  Future<void> scheduleDeadlineNotification(Task task) async {
    // Check if deadline alerts are enabled
    if (!(await areDeadlineAlertsEnabled())) {
      debugPrint("Deadline alerts are disabled by user preference");
      return;
    }
    if (task.isCompleted) {
      return;
    }

    final int notificationId =
        task.id.hashCode + 1000; // Different ID from reminder

    // Notification time is exactly at the due date
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      task.dueDate,
      tz.local,
    );

    // Don't schedule if the time is in the past
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    // Notification details (similar to the reminder, but different channel)
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'task_deadline_channel',
          'Task Deadlines',
          channelDescription: 'Notifications for task deadlines',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    final DarwinNotificationDetails iOSDetails = DarwinNotificationDetails();

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    // Title and body for deadline notification
    String title = '⏰ Task Deadline';
    String body = '${task.title} is due now!';

    // Schedule the notification
    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: task.id,
    );
    // After scheduling
    await _addToNotificationProvider(
      title,
      body,
      NotificationType.deadline,
      task.id,
    );
  }

  // Cancel notifications for a specific task
  Future<void> cancelTaskNotifications(String taskId) async {
    await flutterLocalNotificationsPlugin.cancel(
      taskId.hashCode,
    ); // Cancel reminder
    await flutterLocalNotificationsPlugin.cancel(
      taskId.hashCode + 1000,
    ); // Cancel deadline
    debugPrint("Cancelled notifications for task ID: $taskId");
  }

  // Schedule daily digest notification with summary of today's tasks
  Future<void> scheduleDailyDigest(
    List<Task> todaysTasks, {
    tz.TZDateTime? scheduledTime,
  }) async {
    // Check if daily digest is enabled
    if (!(await isDailyDigestEnabled())) {
      debugPrint("Daily digest is disabled by user preference");
      return;
    }
    if (todaysTasks.isEmpty) {
      return;
    }

    // Default to 8:00 AM if not specified
    scheduledTime ??= tz.TZDateTime(
      tz.local,
      tz.TZDateTime.now(tz.local).year,
      tz.TZDateTime.now(tz.local).month,
      tz.TZDateTime.now(tz.local).day,
      8, // 8:00 AM
      0,
    );

    // If 8:00 AM has already passed, schedule for next day
    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final int highPriorityCount =
        todaysTasks
            .where((task) => task.priority == 'High' && !task.isCompleted)
            .length;

    final int totalTaskCount =
        todaysTasks.where((task) => !task.isCompleted).length;

    // Notification details
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'daily_digest_channel',
          'Daily Task Digest',
          channelDescription: 'Daily summary of your tasks',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(''),
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    // Build notification content
    String title = '📋 Today\'s Tasks';
    String body = 'You have $totalTaskCount tasks today';

    if (highPriorityCount > 0) {
      body +=
          ', including $highPriorityCount high priority ${highPriorityCount == 1 ? 'task' : 'tasks'}.';
    } else {
      body += '.';
    }

    // Schedule the notification
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0, // Daily digest uses ID 0
      title,
      body,
      scheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      matchDateTimeComponents:
          DateTimeComponents.time, // Repeats at the same time every day
    );
    // After scheduling
    // In scheduleDailyDigest
    await _addToNotificationProvider(
      title,
      body,
      NotificationType.digest,
      null,
    );
    debugPrint(
      "Scheduled daily digest notification for ${scheduledTime.toString()}",
    );
  }
  // Update to _addToNotificationProvider method in NotificationService class
Future<void> _addToNotificationProvider(
  String title,
  String body,
  NotificationType type,
  String? taskId,
) async {
  try {
    // Check if _notificationProvider is initialized
    if (_notificationProvider == null) {
      debugPrint("ERROR: NotificationProvider not set! Cannot add notification");
      return;
    }
    
    debugPrint("Creating notification with title: $title");
    final notification = AppNotification(
      id: '$type-${taskId ?? 'general'}-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      timestamp: DateTime.now(),
      taskId: taskId,
      type: type,
    );

    debugPrint("Adding notification to provider...");
    await _notificationProvider.addNotification(notification);
    debugPrint("Notification added successfully!");
  } catch (e) {
    debugPrint("Error adding notification to provider: $e");
  }
}
  // Get color for priority (for notification LED color)
  int _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return 0xFFFF0000; // Red
      case 'Medium':
        return 0xFFFF9800; // Orange
      case 'Low':
        return 0xFF4CAF50; // Green
      default:
        return 0xFF2196F3; // Blue
    }
  }
}
