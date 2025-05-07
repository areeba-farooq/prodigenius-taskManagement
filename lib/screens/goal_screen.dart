import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskgenius/models/goal.dart';
import 'package:taskgenius/state/task_provider.dart';
import 'package:taskgenius/widgets/goal_achievement_dialog.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  int _targetTaskCount = 5;
  GoalPeriod _selectedPeriod = GoalPeriod.daily;
  List<String> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForNewAchievements();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _checkForNewAchievements() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    if (taskProvider.hasNewAchievements()) {
      
      final goals = taskProvider.goals;
      goals.sort(
        (a, b) => (b.lastAchievedAt ?? DateTime(1970)).compareTo(
          a.lastAchievedAt ?? DateTime(1970),
        ),
      );

      if (goals.isNotEmpty && goals[0].lastAchievedAt != null) {
        // Show achievement dialog
        Future.delayed(const Duration(milliseconds: 500), () {
          showDialog(
            context: context,
            builder: (context) => GoalAchievementDialog(goal: goals[0]),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Goals'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Daily Goals'), Tab(text: 'Weekly Goals')],
        ),
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              
              _buildGoalList(taskProvider, GoalPeriod.daily),

              
              _buildGoalList(taskProvider, GoalPeriod.weekly),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGoalList(TaskProvider taskProvider, GoalPeriod period) {
    final goals =
        taskProvider.goals.where((goal) => goal.period == period).toList();

    if (goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No ${period == GoalPeriod.daily ? 'daily' : 'weekly'} goals yet',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showAddGoalDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add a Goal'),
            ),
          ],
        ),
      );
    }

    // Achievement rate
    final achievementRate = taskProvider.getGoalAchievementRate(period);

    return Column(
      children: [
        // Goal achievement stats
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${period == GoalPeriod.daily ? 'Daily' : 'Weekly'} Achievement Rate',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: achievementRate,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getAchievementColor(achievementRate),
                  ),
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Text(
                  '${(achievementRate * 100).toStringAsFixed(0)}% of goals achieved',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),

        // Goal list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];

              // Calculate progress
              int completedCount = 0;

              // Get period start date
              final now = DateTime.now();
              DateTime periodStartDate;

              if (period == GoalPeriod.daily) {
                periodStartDate = DateTime(now.year, now.month, now.day);
              } else {
                // Weekly - go back to Monday
                final daysSinceMonday = now.weekday - 1;
                periodStartDate = DateTime(
                  now.year,
                  now.month,
                  now.day,
                ).subtract(Duration(days: daysSinceMonday));
              }

              // Count completed tasks in the period that match goal criteria
              completedCount =
                  taskProvider.tasks.where((task) {
                    // Must be completed in current period
                    if (!task.isCompleted ||
                        task.completedAt == null ||
                        task.completedAt!.isBefore(periodStartDate)) {
                      return false;
                    }

                    // Check category filter if present
                    if (goal.taskCategories.isNotEmpty &&
                        !goal.taskCategories.contains(task.category)) {
                      return false;
                    }

                    return true;
                  }).length;

              final progress = goal.getProgressPercentage(completedCount);
              final isAchieved = goal.isAchievedForCurrentPeriod();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Goal icon with achievement badge
                          Stack(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.flag,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              if (isAchieved)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(width: 16),

                          // Goal details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  goal.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  '${goal.targetTaskCount} ${goal.targetTaskCount == 1 ? 'task' : 'tasks'} ${goal.taskCategories.isNotEmpty ? 'in ${goal.taskCategories.join(", ")}' : ''}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),

                                if (goal.achievedCount > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.emoji_events,
                                          size: 14,
                                          color: Colors.amber.shade700,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Achieved ${goal.achievedCount} ${goal.achievedCount == 1 ? 'time' : 'times'}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.amber.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Menu options
                          PopupMenuButton<String>(
                            itemBuilder:
                                (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  PopupMenuItem(
                                    value: 'toggle_active',
                                    child: Text(
                                      goal.isActive ? 'Deactivate' : 'Activate',
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  _showEditGoalDialog(context, goal);
                                  break;
                                case 'toggle_active':
                                  taskProvider.updateGoal(
                                    goal.copyWith(isActive: !goal.isActive),
                                  );
                                  break;
                                case 'delete':
                                  _confirmDeleteGoal(context, goal);
                                  break;
                              }
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Progress bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isAchieved
                                    ? 'Completed!'
                                    : '$completedCount/${goal.targetTaskCount} tasks',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isAchieved ? Colors.green : null,
                                  fontWeight:
                                      isAchieved
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                              Text(
                                '${(progress * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isAchieved ? Colors.green : null,
                                  fontWeight:
                                      isAchieved
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isAchieved
                                    ? Colors.green
                                    : Theme.of(context).primaryColor,
                              ),
                              minHeight: 8,
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
    );
  }

  Color _getAchievementColor(double rate) {
    if (rate >= 0.9) return Colors.green;
    if (rate >= 0.7) return Colors.lightGreen;
    if (rate >= 0.5) return Colors.amber;
    return Colors.redAccent;
  }

  void _showAddGoalDialog(BuildContext context) {
    _titleController.clear();
    _targetTaskCount = 5;
    _selectedPeriod = GoalPeriod.daily;
    _selectedCategories = [];

    showDialog(
      context: context,
      builder: (context) {
        final taskProvider = Provider.of<TaskProvider>(context, listen: false);

        return AlertDialog(
          title: const Text('Add New Goal'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Goal title
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Goal Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Target task count
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Target: $_targetTaskCount tasks',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (_targetTaskCount > 1) {
                            setState(() {
                              _targetTaskCount--;
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            _targetTaskCount++;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Goal period
                  const Text(
                    'Goal Period:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),

                  const SizedBox(height: 8),

                  SegmentedButton<GoalPeriod>(
                    segments: const [
                      ButtonSegment(
                        value: GoalPeriod.daily,
                        label: Text('Daily'),
                      ),
                      ButtonSegment(
                        value: GoalPeriod.weekly,
                        label: Text('Weekly'),
                      ),
                    ],
                    selected: {_selectedPeriod},
                    onSelectionChanged: (Set<GoalPeriod> selection) {
                      setState(() {
                        _selectedPeriod = selection.first;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Category filter
                  const Text(
                    'Filter by Categories (Optional):',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),

                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        taskProvider.categories.map((category) {
                          final isSelected = _selectedCategories.contains(
                            category,
                          );

                          return FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedCategories.add(category);
                                } else {
                                  _selectedCategories.remove(category);
                                }
                              });
                            },
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Create the goal
                  final goal = Goal(
                    title: _titleController.text.trim(),
                    targetTaskCount: _targetTaskCount,
                    period: _selectedPeriod,
                    taskCategories: _selectedCategories,
                  );

                  // Add to provider
                  taskProvider.addGoal(goal);

                  
                  Navigator.pop(context);
                }
              },
              child: const Text('Add Goal'),
            ),
          ],
        );
      },
    );
  }

  void _showEditGoalDialog(BuildContext context, Goal goal) {
    _titleController.text = goal.title;
    _targetTaskCount = goal.targetTaskCount;
    _selectedPeriod = goal.period;
    _selectedCategories = List.from(goal.taskCategories);

    showDialog(
      context: context,
      builder: (context) {
        final taskProvider = Provider.of<TaskProvider>(context, listen: false);

        return AlertDialog(
          title: const Text('Edit Goal'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Goal title
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Goal Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Target task count
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Target: $_targetTaskCount tasks',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (_targetTaskCount > 1) {
                            setState(() {
                              _targetTaskCount--;
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            _targetTaskCount++;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Category filter
                  const Text(
                    'Filter by Categories (Optional):',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),

                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        taskProvider.categories.map((category) {
                          final isSelected = _selectedCategories.contains(
                            category,
                          );

                          return FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedCategories.add(category);
                                } else {
                                  _selectedCategories.remove(category);
                                }
                              });
                            },
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Update the goal
                  final updatedGoal = goal.copyWith(
                    title: _titleController.text.trim(),
                    targetTaskCount: _targetTaskCount,
                    taskCategories: _selectedCategories,
                  );

                  // Update provider
                  taskProvider.updateGoal(updatedGoal);

                  
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteGoal(BuildContext context, Goal goal) {
    showDialog(
      context: context,
      builder: (context) {
        final taskProvider = Provider.of<TaskProvider>(context, listen: false);

        return AlertDialog(
          title: const Text('Delete Goal?'),
          content: Text(
            'Are you sure you want to delete the goal "${goal.title}"?'
            '\n\nThis action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                taskProvider.deleteGoal(goal.id);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
