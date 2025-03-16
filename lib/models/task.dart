// class Task {
//   final String id;
//   final String title;
//   final String dueDate;
//   final String priority;
//   final String category;
//   final bool isCompleted;

//   Task({
//     required this.id,
//     required this.title,
//     required this.dueDate,
//     required this.priority,
//     required this.category,
//     this.isCompleted = false,
//   });

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'title': title,
//       'dueDate': dueDate,
//       'priority': priority,
//       'category': category,
//       'isCompleted': isCompleted,
//     };
//   }

//   static Task fromJson(Map<String, dynamic> json) {
//     return Task(
//       id: json['id'],
//       title: json['title'],
//       dueDate: json['dueDate'],
//       priority: json['priority'],
//       category: json['category'],
//       isCompleted: json['isCompleted'] ?? false,
//     );
//   }
// }

// Task model with priority
class Task {
  final String id;
  final String title;
  final String category;
  final DateTime dueDate;
  final int urgencyLevel; // 1-5 scale where 5 is most urgent
  final String priority; // High, Medium, Low
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    required this.category,
    required this.dueDate,
    required this.urgencyLevel,
    required this.priority,
    this.isCompleted = false,
  });
}
