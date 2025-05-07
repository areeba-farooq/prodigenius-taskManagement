import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Task {
  final String id;
  final String title;
  final String category;
  final DateTime dueDate;
  final int urgencyLevel;
  final String priority;
  final bool isCompleted;
  final Duration estimatedDuration;
  final int? scheduledDay;
  final int? scheduledTimeSlot;
  final String? scheduledTimeDescription;
  final DateTime? completedAt; 
    final DateTime? createdAt; 

  Task({
    String? id,
    required this.title,
    required this.category,
    required this.dueDate,
    required this.urgencyLevel,
    required this.priority,
    this.isCompleted = false,
    required this.estimatedDuration,
    this.scheduledDay,
    this.scheduledTimeSlot,
    this.scheduledTimeDescription,
    this.completedAt, 
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
  createdAt = createdAt ?? DateTime.now();


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'urgencyLevel': urgencyLevel,
      'priority': priority,
      'isCompleted': isCompleted,
      'estimatedDurationMinutes': estimatedDuration.inMinutes,
      'scheduledDay': scheduledDay,
      'scheduledTimeSlot': scheduledTimeSlot,
      'scheduledTimeDescription': scheduledTimeDescription,
      'completedAt': completedAt?.millisecondsSinceEpoch,
       'createdAt': createdAt?.millisecondsSinceEpoch,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    // Handle different date formats
    DateTime parseDueDate() {
      final dueDateField = map['dueDate'];

      if (dueDateField is DateTime) {
        return dueDateField;
      } else if (dueDateField is Timestamp) {
        return dueDateField.toDate();
      } else if (dueDateField is int) {
        return DateTime.fromMillisecondsSinceEpoch(dueDateField);
      } else {
        print('Unknown date format for dueDate: $dueDateField');
        return DateTime.now();
      }
    }

    // Parse completedAt field which could be null
    DateTime? parseCompletedAt() {
      final completedAtField = map['completedAt'];

      if (completedAtField == null) {
        return null;
      } else if (completedAtField is DateTime) {
        return completedAtField;
      } else if (completedAtField is Timestamp) {
        return completedAtField.toDate();
      } else if (completedAtField is int) {
        return DateTime.fromMillisecondsSinceEpoch(completedAtField);
      } else {
        print('Unknown date format for completedAt: $completedAtField');
        return null;
      }
    }
    DateTime parseCreatedAt() {
      final createdAtField = map['createdAt'];

      if (createdAtField == null) {
        return DateTime.now();
      } else if (createdAtField is DateTime) {
        return createdAtField;
      } else if (createdAtField is Timestamp) {
        return createdAtField.toDate();
      } else if (createdAtField is int) {
        return DateTime.fromMillisecondsSinceEpoch(createdAtField);
      } else {
        print('Unknown date format for createdAt: $createdAtField');
        return DateTime.now();
      }
    }
    // Handle different number formats
    int parseIntField(dynamic value, int defaultValue) {
      if (value is int) {
        return value;
      } else if (value is double) {
        return value.toInt();
      } else if (value is String && int.tryParse(value) != null) {
        return int.parse(value);
      } else {
        print('Unknown integer format: $value, using default: $defaultValue');
        return defaultValue;
      }
    }

    return Task(
      id: map['id'] ?? const Uuid().v4(),
      title: map['title'] ?? 'Untitled Task',
      category: map['category'] ?? 'Other',
      dueDate: parseDueDate(),
      urgencyLevel: parseIntField(map['urgencyLevel'], 3),
      priority: map['priority'] ?? 'Medium',
      isCompleted: map['isCompleted'] ?? false,
      estimatedDuration: Duration(
        minutes: parseIntField(map['estimatedDurationMinutes'], 30),
      ),
      scheduledDay:
          map['scheduledDay'] != null
              ? parseIntField(map['scheduledDay'], 0)
              : null,
      scheduledTimeSlot:
          map['scheduledTimeSlot'] != null
              ? parseIntField(map['scheduledTimeSlot'], 0)
              : null,
      scheduledTimeDescription: map['scheduledTimeDescription'],
      completedAt: parseCompletedAt(),
       createdAt: parseCreatedAt(),
    );
  }

  Task copyWith({
    String? title,
    String? category,
    DateTime? dueDate,
    int? urgencyLevel,
    String? priority,
    bool? isCompleted,
    Duration? estimatedDuration,
    int? scheduledDay,
    int? scheduledTimeSlot,
    String? scheduledTimeDescription,
    DateTime? completedAt,
     DateTime? createdAt,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      scheduledDay: scheduledDay ?? this.scheduledDay,
      scheduledTimeSlot: scheduledTimeSlot ?? this.scheduledTimeSlot,
      scheduledTimeDescription:
          scheduledTimeDescription ?? this.scheduledTimeDescription,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt, 
    );
  }
}
