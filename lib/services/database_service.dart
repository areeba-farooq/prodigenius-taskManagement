import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taskgenius/models/task.dart';
import 'package:taskgenius/models/notification.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tasks collection reference for a specific user
  CollectionReference _userTasksRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('tasks');
  }

  // Notifications collection reference for a specific user
  CollectionReference _userNotificationsRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications');
  }

  // User preferences reference
  DocumentReference _userPreferencesRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('preferences');
  }

  // Categories reference
  DocumentReference _userCategoriesRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('categories');
  }

  // Add or update a task
  Future<void> saveTask(String userId, Task task) async {
    try {
      final taskData = task.toMap();
      // For Firestore, convert DateTime objects to Timestamp objects
      taskData['dueDate'] = Timestamp.fromDate(task.dueDate);
      // Handle the completedAt field - convert to Timestamp when not null
      if (task.completedAt != null) {
        taskData['completedAt'] = Timestamp.fromDate(task.completedAt!);
      } else {
        taskData['completedAt'] = null;
      }
      // For Firestore, convert DateTime to Timestamp
      await _userTasksRef(userId).doc(task.id).set(task.toMap());
      if (task.isCompleted && task.completedAt != null) {
        print('Task completed at: ${task.completedAt}');
      }
    } catch (e) {
      print('Error saving task: $e');
      rethrow;
    }
  }

  // Get all tasks for a user

  Stream<List<Task>> getTasks(String userId) {
    return _userTasksRef(userId).orderBy('dueDate').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          // Create a data map from the document
          final data = doc.data() as Map<String, dynamic>;

          // Ensure the document has an ID
          if (!data.containsKey('id') || data['id'] == null) {
            data['id'] = doc.id;
          }

          // Create a task from the map
          return Task.fromMap(data);
        } catch (e) {
          print('Error parsing task ${doc.id}: $e');
          print('Task data that caused error: ${doc.data()}');

          return Task(
            id: doc.id,
            title: 'Error Loading Task',
            category: 'Other',
            dueDate: DateTime.now(),
            urgencyLevel: 3,
            priority: 'Medium',
            isCompleted: false,
            estimatedDuration: const Duration(minutes: 30),
          );
        }
      }).toList();
    });
  }

  // Delete a task
  Future<void> deleteTask(String userId, String taskId) async {
    try {
      await _userTasksRef(userId).doc(taskId).delete();
    } catch (e) {
      print('Error deleting task: $e');
      rethrow;
    }
  }

  // Save notification
  Future<void> saveNotification(
    String userId,
    AppNotification notification,
  ) async {
    try {
      await _userNotificationsRef(
        userId,
      ).doc(notification.id).set(notification.toMap());
    } catch (e) {
      print('Error saving notification: $e');
      rethrow;
    }
  }

  // Get notifications stream
  Stream<List<AppNotification>> getNotifications(String userId) {
    return _userNotificationsRef(userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => AppNotification.fromMap(
                      doc.data() as Map<String, dynamic>,
                    ),
                  )
                  .toList(),
        );
  }

  // Delete notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _userNotificationsRef(userId).doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  // Save user preferences
  Future<void> saveUserPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      await _userPreferencesRef(userId).set(preferences);
    } catch (e) {
      print('Error saving preferences: $e');
      rethrow;
    }
  }

  // Get user preferences
  Future<Map<String, dynamic>> getUserPreferences(String userId) async {
    try {
      final doc = await _userPreferencesRef(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return {'availableHours': 8, 'timePreference': 1};
    } catch (e) {
      print('Error getting preferences: $e');
      return {'availableHours': 8, 'timePreference': 1};
    }
  }

  // Save categories
  Future<void> saveCategories(String userId, List<String> categories) async {
    try {
      await _userCategoriesRef(userId).set({'categories': categories});
    } catch (e) {
      print('Error saving categories: $e');
      rethrow;
    }
  }

  // Get categories
  Future<List<String>> getCategories(String userId) async {
    try {
      final doc = await _userCategoriesRef(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return List<String>.from(data['categories'] ?? []);
      }
      return ['Work', 'Study', 'Personal', 'Shopping', 'Health', 'Travel'];
    } catch (e) {
      print('Error getting categories: $e');
      return ['Work', 'Study', 'Personal', 'Shopping', 'Health', 'Travel'];
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(
    String userId,
    String notificationId,
  ) async {
    try {
      await _userNotificationsRef(
        userId,
      ).doc(notificationId).update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications(String userId) async {
    try {
      final snapshot = await _userNotificationsRef(userId).get();
      final batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error clearing notifications: $e');
      rethrow;
    }
  }
}
