import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'task.g.dart';//flutter pub run build_runner build


@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final DateTime dueDate;

  @HiveField(4)
  final int urgencyLevel; // 1-5 scale where 5 is most urgent

  @HiveField(5)
  final String priority; // High, Medium, Low

  @HiveField(6)
  bool isCompleted;
  
  @HiveField(7)
  final int complexityLevel; // 1-5 scale where 5 is most complex
  
  @HiveField(8)
  final Duration estimatedDuration; // Estimated time to complete the task

  Task({
    String? id,
    required this.title,
    required this.category,
    required this.dueDate,
    required this.urgencyLevel,
    required this.priority,
    this.isCompleted = false,
    this.complexityLevel = 3, // Default to medium complexity
    this.estimatedDuration = const Duration(minutes: 30), // Default to 30 minutes
  }) : id = id ?? const Uuid().v4(); // Auto-generate ID if not provided

  // Create a copy of this task with updated fields
  Task copyWith({
    String? title,
    String? category,
    DateTime? dueDate,
    int? urgencyLevel,
    String? priority,
    bool? isCompleted,
    int? complexityLevel,
    Duration? estimatedDuration,
  }) {
    return Task(
      id: id, // Keep the same ID
      title: title ?? this.title,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      complexityLevel: complexityLevel ?? this.complexityLevel,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
    );
  }

  // Factory constructor to create Task from Map (useful for JSON)
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      category: map['category'],
      dueDate:
          map['dueDate'] is DateTime
              ? map['dueDate']
              : DateTime.parse(map['dueDate']),
      urgencyLevel: map['urgencyLevel'],
      priority: map['priority'],
      isCompleted: map['isCompleted'] ?? false,
      complexityLevel: map['complexityLevel'] ?? 3,
      estimatedDuration: map['estimatedDuration'] != null 
          ? Duration(minutes: map['estimatedDuration']) 
          : const Duration(minutes: 30),
    );
  }

  // Convert Task to Map (useful for JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'dueDate': dueDate.toIso8601String(),
      'urgencyLevel': urgencyLevel,
      'priority': priority,
      'isCompleted': isCompleted,
      'complexityLevel': complexityLevel,
      'estimatedDuration': estimatedDuration.inMinutes,
    };
  }
}