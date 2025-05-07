import 'package:uuid/uuid.dart';

enum GoalPeriod {
  daily,
  weekly
}

class Goal {
  final String id;
  final String title;
  final int targetTaskCount;
  final GoalPeriod period;
  final List<String> taskCategories; 
  final DateTime createdAt;
  final bool isActive;
  
  
  int achievedCount;
  DateTime? lastAchievedAt;
  
  Goal({
    String? id,
    required this.title,
    required this.targetTaskCount,
    required this.period,
    this.taskCategories = const [],
    DateTime? createdAt,
    this.isActive = true,
    this.achievedCount = 0,
    this.lastAchievedAt,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now();
  
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'targetTaskCount': targetTaskCount,
      'period': period.index,
      'taskCategories': taskCategories,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isActive': isActive,
      'achievedCount': achievedCount,
      'lastAchievedAt': lastAchievedAt?.millisecondsSinceEpoch,
    };
  }
  
  
  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'],
      title: map['title'],
      targetTaskCount: map['targetTaskCount'],
      period: GoalPeriod.values[map['period']],
      taskCategories: List<String>.from(map['taskCategories'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      isActive: map['isActive'] ?? true,
      achievedCount: map['achievedCount'] ?? 0,
      lastAchievedAt: map['lastAchievedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastAchievedAt']) 
          : null,
    );
  }
  
  // Check if goal is achieved for current period
  bool isAchievedForCurrentPeriod() {
    if (lastAchievedAt == null) return false;
    
    final now = DateTime.now();
    if (period == GoalPeriod.daily) {
      return lastAchievedAt!.day == now.day && 
             lastAchievedAt!.month == now.month && 
             lastAchievedAt!.year == now.year;
    } else {
      // Weekly period - check if in the same week
      // For simplicity, we consider week as starting Monday
      final daysSinceMonday = now.weekday - 1;
      final startOfWeek = now.subtract(Duration(days: daysSinceMonday));
      
      return lastAchievedAt!.isAfter(startOfWeek);
    }
  }
  
  // Get progress percentage
  double getProgressPercentage(int completedTaskCount) {
    if (targetTaskCount <= 0) return 0.0;
    final progress = completedTaskCount / targetTaskCount;
    return progress > 1.0 ? 1.0 : progress;
  }
  
  // Create a copy with updated fields
  Goal copyWith({
    String? title,
    int? targetTaskCount,
    GoalPeriod? period,
    List<String>? taskCategories,
    bool? isActive,
    int? achievedCount,
    DateTime? lastAchievedAt,
  }) {
    return Goal(
      id: id,
      title: title ?? this.title,
      targetTaskCount: targetTaskCount ?? this.targetTaskCount,
      period: period ?? this.period,
      taskCategories: taskCategories ?? this.taskCategories,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
      achievedCount: achievedCount ?? this.achievedCount,
      lastAchievedAt: lastAchievedAt ?? this.lastAchievedAt,
    );
  }
}