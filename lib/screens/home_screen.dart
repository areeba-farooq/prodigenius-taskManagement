import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskgenius/models/task.dart';
import 'package:taskgenius/screens/add_task_screen.dart';
import 'package:taskgenius/screens/notification_screen.dart';
import 'package:taskgenius/screens/task_detail_screen.dart';
import 'package:taskgenius/screens/task_schedule_screen.dart';
import 'package:taskgenius/services/ai_service.dart';
import 'package:taskgenius/state/notification_provider.dart';
import 'package:taskgenius/state/task_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final int _currentIndex = 0;
  String _sortBy = 'Due Date';

  // Controller for the search field
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Schedule daily digest when the home screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      taskProvider.scheduleDailyDigest();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter tasks based on selected category and search query
  List<Task> _getFilteredTasks(List<Task> allTasks) {
    return allTasks.where((task) {
      // Filter by search query
      final matchesSearch = task.title.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );

      // Filter by category, but show all if "All" is selected
      final matchesCategory =
          _selectedCategory == 'All' || task.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  // Get AI prioritized tasks (top 3 high priority tasks not completed yet)
  List<Task> _getAiSuggestions(List<Task> allTasks) {
    final highPriorityTasks =
        allTasks
            .where((task) => !task.isCompleted && task.priority == 'High')
            .toList();

    // Sort by due date (soonest first)
    highPriorityTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    // Return top 3 or fewer if not enough high priority tasks
    return highPriorityTasks.take(3).toList();
  }

  // Sort tasks based on sort criteria
  List<Task> _sortTasks(List<Task> tasks) {
    switch (_sortBy) {
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
    final filteredTasks = _sortTasks(_getFilteredTasks(allTasks));
    final aiSuggestions = _getAiSuggestions(allTasks);
    final todaysScheduledTasks = taskProvider.todaysScheduledTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Genius'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                // Only show the badge if there are new notifications since the last time the user viewed
                if (Provider.of<NotificationProvider>(
                  context,
                ).hasNewNotifications)
                  Positioned(
                    right: -3,
                    top: -3,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        Provider.of<NotificationProvider>(context).unreadCount >
                                9
                            ? '9+'
                            : Provider.of<NotificationProvider>(
                              context,
                            ).unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              // Update the last viewed timestamp when the user taps the notification icon
              Provider.of<NotificationProvider>(
                context,
                listen: false,
              ).updateLastViewed();

              // Navigate to the notification screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Category tabs
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children:
                  ['All', ...taskProvider.categories].map((category) {
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Center(
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),

          const SizedBox(height: 16),
          // Today's Schedule Section
          if (todaysScheduledTasks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Today\'s Schedule',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScheduleScreen(),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: todaysScheduledTasks.length,
                itemBuilder: (context, index) {
                  final task = todaysScheduledTasks[index];
                  
                  // Get time slot name
                  String timeSlot = 'Morning';
                  if (task.scheduledTimeSlot == 1) {
                    timeSlot = 'Afternoon';
                  } else if (task.scheduledTimeSlot == 2) {
                    timeSlot = 'Evening';
                  }
                  
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                timeSlot,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            task.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 2.0,
                                ),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(task.priority).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  task.priority,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getPriorityColor(task.priority),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                DurationEstimator.formatDuration(task.estimatedDuration),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),


          // AI Suggestions Section
          if (aiSuggestions.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.amber),
                  const SizedBox(width: 8),
                  const Text(
                    'AI Suggestions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // Show all AI suggestions in a dialog
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Row(
                                children: [
                                  Icon(Icons.auto_awesome, color: Colors.amber),
                                  SizedBox(width: 8),
                                  Text('AI Prioritized Tasks'),
                                ],
                              ),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: aiSuggestions.length,
                                  itemBuilder: (context, index) {
                                    final task = aiSuggestions[index];
                                    return ListTile(
                                      leading: Icon(
                                        Icons.circle,
                                        color: _getPriorityColor(task.priority),
                                        size: 12,
                                      ),
                                      title: Text(task.title),
                                      subtitle: Text(
                                        'Due: ${_formatDate(task.dueDate)}',
                                      ),
                                    );
                                  },
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                      );
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),
          
        
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: aiSuggestions.length,
                itemBuilder: (context, index) {
                  final task = aiSuggestions[index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 16.0),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(task.priority).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getPriorityColor(
                          task.priority,
                        ).withOpacity(0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 12,
                                color: _getPriorityColor(task.priority),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  task.category,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            task.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(task.dueDate),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.timer, size: 12),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    DurationEstimator.formatDuration(
                                      task.estimatedDuration,
                                    ),
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
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

          const SizedBox(height: 16),

          // Tasks header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  '$_selectedCategory Tasks',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: _sortBy,
                  underline: Container(),
                  icon: const Icon(Icons.sort),
                  items:
                      <String>[
                        'Due Date',
                        'Priority',
                        'Title',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _sortBy = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Tasks list
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
                                ? 'No tasks in $_selectedCategory category'
                                : 'No tasks matching "$_searchQuery"',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          elevation: 2,
                          child: ListTile(
                            leading: Checkbox(
                              value: task.isCompleted,
                              activeColor: Theme.of(context).primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (bool? value) {
                                if (value != null) {
                                  taskProvider.toggleTaskCompletion(task.id);
                                }
                              },
                            ),
                            title: Text(
                              task.title,
                              style: TextStyle(
                                decoration:
                                    task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                fontWeight:
                                    task.isCompleted
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                        vertical: 2.0,
                                      ),
                                      margin: const EdgeInsets.only(right: 8.0),
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(
                                          task.category,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        task.category,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: _getCategoryColor(
                                            task.category,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatDate(task.dueDate),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.timer, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      DurationEstimator.formatDuration(
                                        task.estimatedDuration,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            trailing: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getPriorityColor(task.priority),
                              ),
                            ),
                            onTap: () {
                              // Navigate to task detail screen
                              _navigateToTaskDetail(context, task);
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TaskInputScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Method to navigate to task detail screen
  void _navigateToTaskDetail(BuildContext context, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
    );
  }

  // Helper method to format the date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Helper method to get priority color
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

  // Helper method to get category color
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
      default:
        return Colors.blueGrey;
    }
  }
}
//************************************************* */
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:taskgenius/models/task.dart';
// import 'package:taskgenius/screens/add_task_screen.dart';
// import 'package:taskgenius/screens/notification_screen.dart';
// import 'package:taskgenius/screens/task_detail_screen.dart';
// import 'package:taskgenius/services/ai_service.dart';
// import 'package:taskgenius/state/notification_provider.dart';
// import 'package:taskgenius/state/task_provider.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   String _selectedCategory = 'All';
//   String _searchQuery = '';
//   final int _currentIndex = 0;
//   String _sortBy = 'Due Date';

//   // Controller for the search field
//   final TextEditingController _searchController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();

//     // Schedule daily digest when the home screen loads
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final taskProvider = Provider.of<TaskProvider>(context, listen: false);
//       taskProvider.scheduleDailyDigest();
//     });
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   // Filter tasks based on selected category and search query
//   List<Task> _getFilteredTasks(List<Task> allTasks) {
//     return allTasks.where((task) {
//       // Filter by search query
//       final matchesSearch = task.title.toLowerCase().contains(
//         _searchQuery.toLowerCase(),
//       );

//       // Filter by category, but show all if "All" is selected
//       final matchesCategory =
//           _selectedCategory == 'All' || task.category == _selectedCategory;

//       return matchesSearch && matchesCategory;
//     }).toList();
//   }

//   // Get AI prioritized tasks (top 3 high priority tasks not completed yet)
//   List<Task> _getAiSuggestions(List<Task> allTasks) {
//     final highPriorityTasks =
//         allTasks
//             .where((task) => !task.isCompleted && task.priority == 'High')
//             .toList();

//     // Sort by due date (soonest first)
//     highPriorityTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

//     // Return top 3 or fewer if not enough high priority tasks
//     return highPriorityTasks.take(3).toList();
//   }

//   // Sort tasks based on sort criteria
//   List<Task> _sortTasks(List<Task> tasks) {
//     switch (_sortBy) {
//       case 'Due Date':
//         return tasks..sort((a, b) => a.dueDate.compareTo(b.dueDate));
//       case 'Priority':
//         return tasks..sort((a, b) {
//           // Sort by priority (High > Medium > Low)
//           final priorityValue = {'High': 3, 'Medium': 2, 'Low': 1};
//           return priorityValue[b.priority]!.compareTo(
//             priorityValue[a.priority]!,
//           );
//         });
//       case 'Title':
//         return tasks..sort((a, b) => a.title.compareTo(b.title));
//       default:
//         return tasks;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final taskProvider = Provider.of<TaskProvider>(context);
//     final allTasks = taskProvider.tasks;
//     final filteredTasks = _sortTasks(_getFilteredTasks(allTasks));
//     final aiSuggestions = _getAiSuggestions(allTasks);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Task Genius'),
//         actions: [
//           IconButton(
//             icon: Stack(
//               children: [
//                 const Icon(Icons.notifications),
//                 // Only show the badge if there are new notifications since the last time the user viewed
//                 if (Provider.of<NotificationProvider>(
//                   context,
//                 ).hasNewNotifications)
//                   Positioned(
//                     right: -3,
//                     top: -3,
//                     child: Container(
//                       padding: const EdgeInsets.all(2),
//                       decoration: BoxDecoration(
//                         color: Colors.red,
//                         borderRadius: BorderRadius.circular(10),
//                         border: Border.all(color: Colors.white, width: 1.5),
//                       ),
//                       constraints: const BoxConstraints(
//                         minWidth: 18,
//                         minHeight: 18,
//                       ),
//                       child: Text(
//                         Provider.of<NotificationProvider>(context).unreadCount >
//                                 9
//                             ? '9+'
//                             : Provider.of<NotificationProvider>(
//                               context,
//                             ).unreadCount.toString(),
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 10,
//                           fontWeight: FontWeight.bold,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//             onPressed: () {
//               // Update the last viewed timestamp when the user taps the notification icon
//               Provider.of<NotificationProvider>(
//                 context,
//                 listen: false,
//               ).updateLastViewed();

//               // Navigate to the notification screen
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => const NotificationScreen(),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Search bar
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: 'Search tasks...',
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(30),
//                 ),
//                 contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   _searchQuery = value;
//                 });
//               },
//             ),
//           ),

//           // Category tabs
//           SizedBox(
//             height: 50,
//             child: ListView(
//               scrollDirection: Axis.horizontal,
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               children:
//                   ['All', ...taskProvider.categories].map((category) {
//                     final isSelected = _selectedCategory == category;
//                     return Padding(
//                       padding: const EdgeInsets.only(right: 12.0),
//                       child: GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             _selectedCategory = category;
//                           });
//                         },
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 20.0),
//                           decoration: BoxDecoration(
//                             color:
//                                 isSelected
//                                     ? Theme.of(context).primaryColor
//                                     : Colors.grey.shade200,
//                             borderRadius: BorderRadius.circular(30),
//                           ),
//                           child: Center(
//                             child: Text(
//                               category,
//                               style: TextStyle(
//                                 color: isSelected ? Colors.white : Colors.black,
//                                 fontWeight:
//                                     isSelected
//                                         ? FontWeight.bold
//                                         : FontWeight.normal,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     );
//                   }).toList(),
//             ),
//           ),

//           const SizedBox(height: 16),

//           // AI Suggestions Section
//           if (aiSuggestions.isNotEmpty) ...[
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               child: Row(
//                 children: [
//                   const Icon(Icons.auto_awesome, color: Colors.amber),
//                   const SizedBox(width: 8),
//                   const Text(
//                     'AI Suggestions',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   const Spacer(),
//                   TextButton(
//                     onPressed: () {
//                       // Show all AI suggestions in a dialog
//                       showDialog(
//                         context: context,
//                         builder:
//                             (context) => AlertDialog(
//                               title: const Row(
//                                 children: [
//                                   Icon(Icons.auto_awesome, color: Colors.amber),
//                                   SizedBox(width: 8),
//                                   Text('AI Prioritized Tasks'),
//                                 ],
//                               ),
//                               content: SizedBox(
//                                 width: double.maxFinite,
//                                 child: ListView.builder(
//                                   shrinkWrap: true,
//                                   itemCount: aiSuggestions.length,
//                                   itemBuilder: (context, index) {
//                                     final task = aiSuggestions[index];
//                                     return ListTile(
//                                       leading: Icon(
//                                         Icons.circle,
//                                         color: _getPriorityColor(task.priority),
//                                         size: 12,
//                                       ),
//                                       title: Text(task.title),
//                                       subtitle: Text(
//                                         'Due: ${_formatDate(task.dueDate)}',
//                                       ),
//                                     );
//                                   },
//                                 ),
//                               ),
//                               actions: [
//                                 TextButton(
//                                   onPressed: () => Navigator.pop(context),
//                                   child: const Text('Close'),
//                                 ),
//                               ],
//                             ),
//                       );
//                     },
//                     child: const Text('See All'),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(
//               height: 120,
//               child: ListView.builder(
//                 scrollDirection: Axis.horizontal,
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 itemCount: aiSuggestions.length,
//                 itemBuilder: (context, index) {
//                   final task = aiSuggestions[index];
//                   return Container(
//                     width: 200,
//                     margin: const EdgeInsets.only(right: 16.0),
//                     decoration: BoxDecoration(
//                       color: _getPriorityColor(task.priority).withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(16),
//                       border: Border.all(
//                         color: _getPriorityColor(
//                           task.priority,
//                         ).withOpacity(0.5),
//                       ),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: [
//                               Icon(
//                                 Icons.circle,
//                                 size: 12,
//                                 color: _getPriorityColor(task.priority),
//                               ),
//                               const SizedBox(width: 8),
//                               Expanded(
//                                 child: Text(
//                                   task.category,
//                                   style: const TextStyle(
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             task.title,
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                             ),
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           const Spacer(),
//                           Row(
//                             children: [
//                               const Icon(Icons.calendar_today, size: 12),
//                               const SizedBox(width: 4),
//                               Text(
//                                 _formatDate(task.dueDate),
//                                 style: const TextStyle(fontSize: 12),
//                               ),
//                             ],
//                           ),
//                           Expanded(
//                             child: Row(
//                               children: [
//                                 const Icon(Icons.timer, size: 12),
//                                 const SizedBox(width: 4),
//                                 Flexible(
//                                   child: Text(
//                                     DurationEstimator.formatDuration(
//                                       task.estimatedDuration,
//                                     ),
//                                     style: const TextStyle(fontSize: 12),
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],

//           const SizedBox(height: 16),

//           // Tasks header
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0),
//             child: Row(
//               children: [
//                 Text(
//                   '$_selectedCategory Tasks',
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const Spacer(),
//                 DropdownButton<String>(
//                   value: _sortBy,
//                   underline: Container(),
//                   icon: const Icon(Icons.sort),
//                   items:
//                       <String>[
//                         'Due Date',
//                         'Priority',
//                         'Title',
//                       ].map<DropdownMenuItem<String>>((String value) {
//                         return DropdownMenuItem<String>(
//                           value: value,
//                           child: Text(value),
//                         );
//                       }).toList(),
//                   onChanged: (String? newValue) {
//                     if (newValue != null) {
//                       setState(() {
//                         _sortBy = newValue;
//                       });
//                     }
//                   },
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 8),

//           // Tasks list
//           Expanded(
//             child:
//                 filteredTasks.isEmpty
//                     ? Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const Icon(
//                             Icons.task_alt,
//                             size: 64,
//                             color: Colors.grey,
//                           ),
//                           const SizedBox(height: 16),
//                           Text(
//                             _searchQuery.isEmpty
//                                 ? 'No tasks in $_selectedCategory category'
//                                 : 'No tasks matching "$_searchQuery"',
//                             style: const TextStyle(
//                               fontSize: 16,
//                               color: Colors.grey,
//                             ),
//                           ),
//                         ],
//                       ),
//                     )
//                     : ListView.builder(
//                       padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                       itemCount: filteredTasks.length,
//                       itemBuilder: (context, index) {
//                         final task = filteredTasks[index];
//                         return Card(
//                           margin: const EdgeInsets.only(bottom: 12.0),
//                           elevation: 2,
//                           child: ListTile(
//                             leading: Checkbox(
//                               value: task.isCompleted,
//                               activeColor: Theme.of(context).primaryColor,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(4),
//                               ),
//                               onChanged: (bool? value) {
//                                 if (value != null) {
//                                   taskProvider.toggleTaskCompletion(task.id);
//                                 }
//                               },
//                             ),
//                             title: Text(
//                               task.title,
//                               style: TextStyle(
//                                 decoration:
//                                     task.isCompleted
//                                         ? TextDecoration.lineThrough
//                                         : null,
//                                 fontWeight:
//                                     task.isCompleted
//                                         ? FontWeight.normal
//                                         : FontWeight.bold,
//                               ),
//                             ),
//                             subtitle: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Row(
//                                   children: [
//                                     Container(
//                                       padding: const EdgeInsets.symmetric(
//                                         horizontal: 8.0,
//                                         vertical: 2.0,
//                                       ),
//                                       margin: const EdgeInsets.only(right: 8.0),
//                                       decoration: BoxDecoration(
//                                         color: _getCategoryColor(
//                                           task.category,
//                                         ).withOpacity(0.1),
//                                         borderRadius: BorderRadius.circular(8),
//                                       ),
//                                       child: Text(
//                                         task.category,
//                                         style: TextStyle(
//                                           fontSize: 10,
//                                           color: _getCategoryColor(
//                                             task.category,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                     Text(
//                                       _formatDate(task.dueDate),
//                                       style: const TextStyle(fontSize: 12),
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Row(
//                                   children: [
//                                     const Icon(Icons.timer, size: 12),
//                                     const SizedBox(width: 4),
//                                     Text(
//                                       DurationEstimator.formatDuration(
//                                         task.estimatedDuration,
//                                       ),
//                                       style: const TextStyle(
//                                         fontSize: 12,
//                                         fontStyle: FontStyle.italic,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),

//                             trailing: Container(
//                               width: 16,
//                               height: 16,
//                               decoration: BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 color: _getPriorityColor(task.priority),
//                               ),
//                             ),
//                             onTap: () {
//                               // Navigate to task detail screen
//                               _navigateToTaskDetail(context, task);
//                             },
//                           ),
//                         );
//                       },
//                     ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => const TaskInputScreen()),
//           );
//         },
//         child: const Icon(Icons.add),
//       ),
//     );
//   }

//   // Method to navigate to task detail screen
//   void _navigateToTaskDetail(BuildContext context, Task task) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
//     );
//   }

//   // Helper method to format the date
//   String _formatDate(DateTime date) {
//     return '${date.day}/${date.month}/${date.year}';
//   }

//   // Helper method to get priority color
//   Color _getPriorityColor(String priority) {
//     switch (priority) {
//       case 'High':
//         return Colors.red;
//       case 'Medium':
//         return Colors.orange;
//       case 'Low':
//         return Colors.green;
//       default:
//         return Colors.blue;
//     }
//   }

//   // Helper method to get category color
//   Color _getCategoryColor(String category) {
//     switch (category) {
//       case 'Work':
//         return Colors.blue;
//       case 'Travel':
//         return Colors.purple;
//       case 'Shopping':
//         return Colors.teal;
//       case 'Personal':
//         return Colors.orange;
//       case 'Health':
//         return Colors.green;
//       default:
//         return Colors.blueGrey;
//     }
//   }
// }
