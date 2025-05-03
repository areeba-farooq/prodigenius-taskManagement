import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/task-detail');
      },
      child: Card(
        child: ListTile(
          title: Text(task.title),
          subtitle: Text('Due: ${task.dueDate}'),
          trailing: Checkbox(
            value: task.isCompleted,
            onChanged: (bool? value) {
              
            },
          ),
        ),
      ),
    );
  }
}
