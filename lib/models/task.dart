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
  }) : id = id ?? const Uuid().v4();

  // Convert Task to a map
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
    };
  }

  // Create Task from a map
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      category: map['category'],
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate']),
      urgencyLevel: map['urgencyLevel'],
      priority: map['priority'],
      isCompleted: map['isCompleted'],
      estimatedDuration: Duration(minutes: map['estimatedDurationMinutes']),
      scheduledDay: map['scheduledDay'],
      scheduledTimeSlot: map['scheduledTimeSlot'],
      scheduledTimeDescription: map['scheduledTimeDescription'],
    );
  }

  // Create a copy of a Task with some modified fields
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
    );
  }
}
