import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskgenius/models/task.dart';
import 'package:taskgenius/screens/dashboard_screen.dart';
import 'package:taskgenius/screens/goal_screen.dart';
import 'package:taskgenius/screens/notification_screen.dart';
import 'package:taskgenius/screens/task_detail_screen.dart';
import 'package:taskgenius/services/ai_service.dart';
import 'package:taskgenius/state/notification_provider.dart';
import 'package:taskgenius/state/task_provider.dart';

class CompletedTasksScreen extends StatefulWidget {
  const CompletedTasksScreen({super.key});

  @override
  State<CompletedTasksScreen> createState() => _CompletedTasksScreenState();
}

class _CompletedTasksScreenState extends State<CompletedTasksScreen> {
  String _searchQuery = '';
  String _sortBy = 'Completion Date';
  String _selectedCategory = 'All';

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter completed tasks based on selected category and search query
  List<Task> _getFilteredTasks(List<Task> completedTasks) {
    return completedTasks.where((task) {
      // Filter by search query
      final matchesSearch = task.title.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );

      // Filter by category
      final matchesCategory =
          _selectedCategory == 'All' || task.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  // Sort tasks based on sort criteria
  List<Task> _sortTasks(List<Task> tasks) {
    switch (_sortBy) {
      case 'Completion Date':
        return tasks;
      case 'Due Date':
        return tasks..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      case 'Priority':
        return tasks..sort((a, b) {
          // Sort by priority (High > Medium > Low)
          final priorityValue = {'High': 3, 'Medium': 2, 'Low': 1};
          return priorityValue[b.priority]!.compareTo(
            priorityValue[a.priority]!,
          );
        });
      case 'Title':
        return tasks..sort((a, b) => a.title.compareTo(b.title));
      default:
        return tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final allTasks = taskProvider.tasks;
    final completedTasks = allTasks.where((task) => task.isCompleted).toList();
    final filteredTasks = _sortTasks(_getFilteredTasks(completedTasks));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Tasks'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GoalScreen()),
              );
            },
            icon: Icon(Icons.golf_course_sharp),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DashboardScreen()),
              );
            },
            icon: Icon(Icons.analytics_outlined),
          ),
          // Notification icon with badge
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      notificationProvider.updateLastViewed();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                  ),
                  if (notificationProvider.hasNewNotifications)
                    Positioned(
                      right: 8,
                      top: 2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Color(0xfff2ee0d),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          Provider.of<NotificationProvider>(
                                    context,
                                  ).unreadCount >
                                  9
                              ? '9+'
                              : Provider.of<NotificationProvider>(
                                context,
                              ).unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search completed tasks...',
                prefixIcon: const Icon(Icons.search, size: 22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2.0,
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Category tabs
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children:
                  ['All', ...taskProvider.categories].map((category) {
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected:
                            (_) => setState(() => _selectedCategory = category),
                        selectedColor: Theme.of(context).primaryColor,
                        labelStyle: TextStyle(
                          color:
                              isSelected
                                  ? Colors.white
                                  : Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        checkmarkColor:
                            isSelected
                                ? Colors.white
                                : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    );
                  }).toList(),
            ),
          ),

          // Sort options
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Text(
                  'Completed Tasks',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: _sortBy,
                  underline: Container(),
                  icon: const Icon(Icons.sort),
                  items:
                      ['Completion Date', 'Due Date', 'Priority', 'Title'].map((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _sortBy = newValue);
                    }
                  },
                ),
              ],
            ),
          ),

          // Task list
          Expanded(
            child:
                filteredTasks.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.task_alt,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? _selectedCategory == 'All'
                                    ? 'No completed tasks yet'
                                    : 'No completed tasks in $_selectedCategory category'
                                : 'No completed tasks matching "$_searchQuery"',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            onTap: () => _navigateToTaskDetail(context, task),
                            leading: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                size: 16,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            title: Text(
                              task.title,
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(
                                          task.category,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        task.category,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _getCategoryColor(
                                            task.category,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Due: ${_formatDate(task.dueDate)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(
                                      task.priority,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    task.priority,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getPriorityColor(task.priority),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DurationEstimator.formatDuration(
                                    task.estimatedDuration,
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  void _navigateToTaskDetail(BuildContext context, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Work':
        return Colors.blue;
      case 'Travel':
        return Colors.purple;
      case 'Shopping':
        return Colors.teal;
      case 'Personal':
        return Colors.orange;
      case 'Health':
        return Colors.green;
      case 'Study':
        return Colors.indigo;
      default:
        return Colors.blueGrey;
    }
  }
}
