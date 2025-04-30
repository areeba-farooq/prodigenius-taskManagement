import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskgenius/models/task.dart';
import 'package:taskgenius/screens/task_detail_screen.dart';
import 'package:taskgenius/services/ai_service.dart';
import 'package:taskgenius/state/task_provider.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedDayIndex = 0; // 0 = Today, 1 = Tomorrow, etc.

  // Time slot filters
  bool _showMorning = true;
  bool _showAfternoon = true;
  bool _showEvening = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this); // 7 days + All

    _tabController.addListener(() {
      setState(() {
        _selectedDayIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper method to get day name
  String _getDayName(int dayIndex) {
    if (dayIndex == 0) return 'Today';
    if (dayIndex == 1) return 'Tomorrow';

    final now = DateTime.now();
    final targetDate = now.add(Duration(days: dayIndex));
    return _getDayOfWeek(targetDate.weekday);
  }

  // Helper method to get day of week name
  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  // Get formatted date
  String _getFormattedDate(int dayIndex) {
    final now = DateTime.now();
    final targetDate = now.add(Duration(days: dayIndex));
    return '${targetDate.day}/${targetDate.month}/${targetDate.year}';
  }

  // Filter tasks for selected day and time slots
  List<Task> _getFilteredTasks(List<Task> allTasks, int dayIndex) {
    // For the "All" tab, show tasks scheduled for any day
    if (dayIndex == 7) {
      return allTasks
          .where(
            (task) =>
                task.scheduledDay != null &&
                !task.isCompleted &&
                _isTimeSlotVisible(task.scheduledTimeSlot ?? 0),
          )
          .toList()
        ..sort((a, b) {
          // Sort by day first
          final dayComparison = a.scheduledDay!.compareTo(b.scheduledDay!);
          if (dayComparison != 0) return dayComparison;

          // Then by time slot
          return a.scheduledTimeSlot!.compareTo(b.scheduledTimeSlot!);
        });
    }

    // For specific day tabs
    return allTasks
        .where(
          (task) =>
              task.scheduledDay == dayIndex &&
              !task.isCompleted &&
              _isTimeSlotVisible(task.scheduledTimeSlot ?? 0),
        )
        .toList()
      ..sort((a, b) => a.scheduledTimeSlot!.compareTo(b.scheduledTimeSlot!));
  }

  // Check if time slot should be visible based on filters
  bool _isTimeSlotVisible(int timeSlot) {
    if (timeSlot == 0) return _showMorning;
    if (timeSlot == 1) return _showAfternoon;
    if (timeSlot == 2) return _showEvening;
    return true;
  }

  // Get time slot name
  String _getTimeSlotName(int timeSlot) {
    if (timeSlot == 0) return 'Morning';
    if (timeSlot == 1) return 'Afternoon';
    return 'Evening';
  }

  // Get time slot icon
  IconData _getTimeSlotIcon(int timeSlot) {
    if (timeSlot == 0) return Icons.wb_sunny; // Morning
    if (timeSlot == 1) return Icons.wb_cloudy; // Afternoon
    return Icons.nightlight_round; // Evening
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final scheduledTasks = taskProvider.scheduledTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            _buildDayTab(0),
            _buildDayTab(1),
            _buildDayTab(2),
            _buildDayTab(3),
            _buildDayTab(4),
            _buildDayTab(5),
            _buildDayTab(6),
            const Tab(text: 'All'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reschedule all tasks',
            onPressed: () async {
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder:
                    (context) =>
                        const Center(child: CircularProgressIndicator()),
              );

              // Reschedule tasks
              await taskProvider.rescheduleAllTasks();

              // Hide loading indicator
              Navigator.pop(context);

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All tasks have been rescheduled!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter time slots',
            onSelected: (value) {
              setState(() {
                if (value == 'morning') {
                  _showMorning = !_showMorning;
                } else if (value == 'afternoon') {
                  _showAfternoon = !_showAfternoon;
                } else if (value == 'evening') {
                  _showEvening = !_showEvening;
                } else if (value == 'all') {
                  _showMorning = true;
                  _showAfternoon = true;
                  _showEvening = true;
                }
              });
            },
            itemBuilder:
                (context) => [
                  CheckedPopupMenuItem(
                    value: 'morning',
                    checked: _showMorning,
                    child: const Text('Morning'),
                  ),
                  CheckedPopupMenuItem(
                    value: 'afternoon',
                    checked: _showAfternoon,
                    child: const Text('Afternoon'),
                  ),
                  CheckedPopupMenuItem(
                    value: 'evening',
                    checked: _showEvening,
                    child: const Text('Evening'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'all', child: Text('Show All')),
                ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDaySchedule(scheduledTasks, 0),
          _buildDaySchedule(scheduledTasks, 1),
          _buildDaySchedule(scheduledTasks, 2),
          _buildDaySchedule(scheduledTasks, 3),
          _buildDaySchedule(scheduledTasks, 4),
          _buildDaySchedule(scheduledTasks, 5),
          _buildDaySchedule(scheduledTasks, 6),
          _buildDaySchedule(scheduledTasks, 7), // All
        ],
      ),
    );
  }

  // Build a tab for a day
  Widget _buildDayTab(int dayIndex) {
    return Tab(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_getDayName(dayIndex)),
          Text(
            _getFormattedDate(dayIndex),
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  // Build schedule for a specific day
  Widget _buildDaySchedule(List<Task> allTasks, int dayIndex) {
    final filteredTasks = _getFilteredTasks(allTasks, dayIndex);

    if (filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              dayIndex == 7
                  ? 'No scheduled tasks'
                  : 'No tasks scheduled for ${_getDayName(dayIndex)}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];

        // Show day header for the "All" tab
        final showDayHeader =
            dayIndex == 7 &&
            (index == 0 ||
                task.scheduledDay != filteredTasks[index - 1].scheduledDay);

        // Show time slot header if it's the first task of this time slot
        final showTimeSlotHeader =
            index == 0 ||
            task.scheduledTimeSlot !=
                filteredTasks[index - 1].scheduledTimeSlot ||
            (dayIndex == 7 &&
                task.scheduledDay != filteredTasks[index - 1].scheduledDay);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day header for "All" tab
            if (showDayHeader) ...[
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        task.scheduledDay == 0
                            ? 'Today'
                            : task.scheduledDay == 1
                            ? 'Tomorrow'
                            : _getDayName(task.scheduledDay!),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getFormattedDate(task.scheduledDay!),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Time slot header
            if (showTimeSlotHeader) ...[
              Padding(
                padding: EdgeInsets.only(
                  top: showDayHeader ? 8 : 16,
                  bottom: 8,
                  left: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      _getTimeSlotIcon(task.scheduledTimeSlot!),
                      color: Colors.blue.shade500,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getTimeSlotName(task.scheduledTimeSlot!),
                      style: TextStyle(
                        color: Colors.blue.shade500,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Task card
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  task.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                            color: _getPriorityColor(
                              task.priority,
                            ).withOpacity(0.1),
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
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            task.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
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
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.calendar_today, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'Due: ${_formatDate(task.dueDate)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailScreen(task: task),
                      ),
                    );
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskDetailScreen(task: task),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
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
}
