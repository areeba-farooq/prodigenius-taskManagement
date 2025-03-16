import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:taskgenius/models/task.dart';
import 'package:taskgenius/state/task_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _timeRange = 'Week';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          DropdownButton<String>(
            value: _timeRange,
            underline: Container(),
            icon: const Icon(Icons.arrow_drop_down),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            items:
                <String>['Week', 'Month', 'Year'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _timeRange = newValue;
                });
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Categories'),
            Tab(text: 'Productivity'),
          ],
        ),
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          final tasks = taskProvider.tasks;

          return TabBarView(
            controller: _tabController,
            children: [
              // Overview Tab
              _buildOverviewTab(tasks),

              // Categories Tab
              _buildCategoriesTab(tasks, taskProvider.categories),

              // Productivity Tab
              _buildProductivityTab(tasks),
            ],
          );
        },
      ),
    );
  }

  // Overview Tab
  Widget _buildOverviewTab(List<Task> tasks) {
    // Calculate task metrics
    final totalTasks = tasks.length;
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    final pendingTasks = totalTasks - completedTasks;

    // Calculate completion rate
    final completionRate =
        totalTasks > 0
            ? (completedTasks / totalTasks * 100).toStringAsFixed(1)
            : '0.0';

    // Get high priority tasks
    final highPriorityTasks =
        tasks
            .where((task) => task.priority == 'High' && !task.isCompleted)
            .length;

    // Calculate overdue tasks
    final overdueTasks =
        tasks
            .where(
              (task) =>
                  !task.isCompleted && task.dueDate.isBefore(DateTime.now()),
            )
            .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task Summary Cards
          Row(
            children: [
              _buildMetricCard(
                'Total Tasks',
                totalTasks.toString(),
                Icons.task_alt,
                Colors.blue,
              ),
              _buildMetricCard(
                'Completed',
                completedTasks.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetricCard(
                'Pending',
                pendingTasks.toString(),
                Icons.pending_actions,
                Colors.orange,
              ),
              _buildMetricCard(
                'Overdue',
                overdueTasks.toString(),
                Icons.warning_amber,
                Colors.red,
              ),
            ],
          ),

          // Completion Rate Chart
          if (totalTasks > 0) ...[
            const SizedBox(height: 24),
            Text(
              'Task Completion Rate',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: pieChartSectionData(completedTasks),

                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$completionRate%',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Completed',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // High Priority Tasks Alert
          if (highPriorityTasks > 0) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.priority_high, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'High Priority Tasks',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        Text(
                          'You have $highPriorityTasks high priority tasks that need attention',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<PieChartSectionData> pieChartSectionData(int completedTasks) {
    return List.generate(
      2,
      (index) => PieChartSectionData(
        value:
            index == 0
                ? completedTasks.toDouble()
                : (100 - completedTasks).toDouble(),
        title: '',
        color: index == 0 ? Colors.green : Colors.grey.shade300,
        radius: 60,
      ),
    );
  }

  // Categories Tab
  Widget _buildCategoriesTab(List<Task> tasks, List<String> categories) {
    // Calculate tasks per category
    final Map<String, int> categoryCount = {};
    final Map<String, int> completedCount = {};

    // Count tasks in each category
    for (final category in categories) {
      categoryCount[category] =
          tasks.where((task) => task.category == category).length;
      completedCount[category] =
          tasks
              .where((task) => task.category == category && task.isCompleted)
              .length;
    }

    return Column(
      children: [
        // Bar Chart
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tasks by Category',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildCategoryBarChart(categoryCount, completedCount),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem('Completed', Colors.green),
                    const SizedBox(width: 24),
                    _buildLegendItem('Pending', Colors.grey.shade400),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Category List
        Expanded(
          flex: 2,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final totalInCategory = categoryCount[category] ?? 0;
              final completedInCategory = completedCount[category] ?? 0;
              final completionPercent =
                  totalInCategory > 0
                      ? (completedInCategory / totalInCategory * 100).round()
                      : 0;

              // Generate a color based on category
              final categoryColor = _getCategoryColor(category);

              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: categoryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$completedInCategory/$totalInCategory',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRounded(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: completionPercent / 100,
                          backgroundColor: Colors.grey.shade200,
                          color: categoryColor,
                          minHeight: 8,
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
    );
  }

  // Helper widget for ClipRRect workaround
  Widget ClipRounded({
    required BorderRadius borderRadius,
    required Widget child,
  }) {
    return ClipRRect(borderRadius: borderRadius, child: child);
  }

  // Productivity Tab
  Widget _buildProductivityTab(List<Task> tasks) {
    // Get dates for time range
    final DateTime now = DateTime.now();
    DateTime startDate;

    switch (_timeRange) {
      case 'Week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'Month':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case 'Year':
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
    }

    // Filter tasks within date range
    final filteredTasks =
        tasks
            .where(
              (task) =>
                  task.dueDate.isAfter(startDate) ||
                  task.dueDate.isAtSameMomentAs(startDate),
            )
            .toList();

    // Group tasks by date
    final Map<String, int> completedByDate = {};
    final Map<String, int> addedByDate = {};

    // Format pattern based on time range
    String dateFormat;
    if (_timeRange == 'Week') {
      dateFormat = 'E'; // Abbreviated day name
    } else if (_timeRange == 'Month') {
      dateFormat = 'dd'; // Day of month
    } else {
      dateFormat = 'MMM'; // Abbreviated month name
    }

    // Initialize dates in range
    for (int i = 0; i <= now.difference(startDate).inDays; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey = DateFormat(dateFormat).format(date);

      completedByDate[dateKey] = 0;
      addedByDate[dateKey] = 0;
    }

    // Count tasks
    for (final task in filteredTasks) {
      final dateKey = DateFormat(dateFormat).format(task.dueDate);

      // Count as added
      if (addedByDate.containsKey(dateKey)) {
        addedByDate[dateKey] = (addedByDate[dateKey] ?? 0) + 1;
      }

      // Count as completed if completed
      if (task.isCompleted && completedByDate.containsKey(dateKey)) {
        completedByDate[dateKey] = (completedByDate[dateKey] ?? 0) + 1;
      }
    }

    // Calculate productivity metrics
    int totalCompleted = 0;
    for (var task in filteredTasks) {
      if (task.isCompleted) totalCompleted++;
    }

    final productivityRate =
        filteredTasks.isNotEmpty
            ? (totalCompleted / filteredTasks.length * 100).toStringAsFixed(1)
            : '0.0';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Productivity Score',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$productivityRate%',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getProductivityColor(
                            double.parse(productivityRate),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getProductivityColor(
                        double.parse(productivityRate),
                      ).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getProductivityIcon(double.parse(productivityRate)),
                      color: _getProductivityColor(
                        double.parse(productivityRate),
                      ),
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          Text(
            'Productivity Over Time',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: _buildProductivityLineChart(completedByDate, addedByDate),
          ),

          const SizedBox(height: 24),
          Text('Task Activity', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildActivitySummary(filteredTasks),
        ],
      ),
    );
  }

  // Helper method to build metric cards
  Widget _buildMetricCard(
    String title,
    String value,
    IconData iconData,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(iconData, color: color),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build the category bar chart
  Widget _buildCategoryBarChart(
    Map<String, int> categoryCount,
    Map<String, int> completedCount,
  ) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // Check if there are categories
                if (categoryCount.isEmpty ||
                    value.toInt() >= categoryCount.length) {
                  return const SizedBox();
                }

                // Get category name for this position
                final category = categoryCount.keys.elementAt(value.toInt());
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    category.length > 6
                        ? '${category.substring(0, 6)}...'
                        : category,
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value == 0) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 1,
          getDrawingHorizontalLine:
              (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        groupsSpace: 12,
        barGroups: List.generate(categoryCount.length, (index) {
          final category = categoryCount.keys.elementAt(index);
          final total = categoryCount[category] ?? 0;
          final completed = completedCount[category] ?? 0;
          final pending = total - completed;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: total.toDouble(),
                width: 18,
                rodStackItems: [
                  BarChartRodStackItem(0, completed.toDouble(), Colors.green),
                  BarChartRodStackItem(
                    completed.toDouble(),
                    total.toDouble(),
                    Colors.grey.shade400,
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // Build productivity line chart
  Widget _buildProductivityLineChart(
    Map<String, int> completedByDate,
    Map<String, int> addedByDate,
  ) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine:
              (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= completedByDate.length ||
                    value.toInt() < 0) {
                  return const SizedBox();
                }
                final dateLabel = completedByDate.keys.elementAt(value.toInt());
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(dateLabel, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Line for completed tasks
          LineChartBarData(
            spots: _getSpots(completedByDate),
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.2),
            ),
          ),
          // Line for added tasks
          LineChartBarData(
            spots: _getSpots(addedByDate),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to generate spots for line chart
  List<FlSpot> _getSpots(Map<String, int> dataMap) {
    final List<FlSpot> spots = [];

    int index = 0;
    dataMap.forEach((date, count) {
      spots.add(FlSpot(index.toDouble(), count.toDouble()));
      index++;
    });

    return spots;
  }

  // Build Activity Summary Widget
  Widget _buildActivitySummary(List<Task> tasks) {
    // Calculate activity metrics
    final addedToday = tasks.where((task) => _isDateToday(task.dueDate)).length;

    final completedToday =
        tasks
            .where((task) => task.isCompleted && _isDateToday(task.dueDate))
            .length;

    return Row(
      children: [
        Expanded(
          child: Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.add_task, color: Colors.blue.shade700),
                  const SizedBox(height: 8),
                  Text(
                    addedToday.toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  Text(
                    'Added Today',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(height: 8),
                  Text(
                    completedToday.toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  Text(
                    'Completed Today',
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper to check if date is today
  bool _isDateToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Helper to build legend item
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  // Get color for category
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Work':
        return Colors.blue;
      case 'Study':
        return Colors.purple;
      case 'Personal':
        return Colors.orange;
      case 'Shopping':
        return Colors.teal;
      case 'Health':
        return Colors.green;
      default:
        // Generate a color based on category name
        return Color((category.hashCode & 0xFFFFFF) | 0xFF000000);
    }
  }

  // Get color based on productivity score
  Color _getProductivityColor(double score) {
    if (score >= 75) {
      return Colors.green;
    } else if (score >= 50) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // Get icon based on productivity score
  IconData _getProductivityIcon(double score) {
    if (score >= 75) {
      return Icons.sentiment_very_satisfied;
    } else if (score >= 50) {
      return Icons.sentiment_satisfied;
    } else {
      return Icons.sentiment_dissatisfied;
    }
  }
}

//***********************SIMPLE********************************** */
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import 'package:taskgenius/models/task.dart';
// import 'package:taskgenius/state/task_provider.dart';

// class DashboardScreen extends StatefulWidget {
//   const DashboardScreen({super.key});

//   @override
//   State<DashboardScreen> createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   String _timeRange = 'Week';

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Dashboard'),
//         actions: [
//           DropdownButton<String>(
//             value: _timeRange,
//             underline: Container(),
//             icon: const Icon(Icons.arrow_drop_down),
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             items:
//                 <String>['Week', 'Month', 'Year'].map((String value) {
//                   return DropdownMenuItem<String>(
//                     value: value,
//                     child: Text(value),
//                   );
//                 }).toList(),
//             onChanged: (String? newValue) {
//               if (newValue != null) {
//                 setState(() {
//                   _timeRange = newValue;
//                 });
//               }
//             },
//           ),
//         ],
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: const [
//             Tab(text: 'Overview'),
//             Tab(text: 'Categories'),
//             Tab(text: 'Productivity'),
//           ],
//         ),
//       ),
//       body: Consumer<TaskProvider>(
//         builder: (context, taskProvider, child) {
//           final tasks = taskProvider.tasks;

//           return TabBarView(
//             controller: _tabController,
//             children: [
//               // Overview Tab
//               _buildOverviewTab(tasks),

//               // Categories Tab
//               _buildCategoriesTab(tasks, taskProvider.categories),

//               // Productivity Tab
//               _buildProductivityTab(tasks),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   // Overview Tab
//   Widget _buildOverviewTab(List<Task> tasks) {
//     // Calculate task metrics
//     final totalTasks = tasks.length;
//     final completedTasks = tasks.where((task) => task.isCompleted).length;
//     final pendingTasks = totalTasks - completedTasks;

//     // Calculate completion rate
//     final completionRate =
//         totalTasks > 0
//             ? (completedTasks / totalTasks * 100).toStringAsFixed(1)
//             : '0.0';

//     // Get high priority tasks
//     final highPriorityTasks =
//         tasks
//             .where((task) => task.priority == 'High' && !task.isCompleted)
//             .length;

//     // Calculate overdue tasks
//     final overdueTasks =
//         tasks
//             .where(
//               (task) =>
//                   !task.isCompleted && task.dueDate.isBefore(DateTime.now()),
//             )
//             .length;

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Task Summary Cards
//           Row(
//             children: [
//               _buildMetricCard(
//                 'Total Tasks',
//                 totalTasks.toString(),
//                 Icons.task_alt,
//                 Colors.blue,
//               ),
//               _buildMetricCard(
//                 'Completed',
//                 completedTasks.toString(),
//                 Icons.check_circle,
//                 Colors.green,
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               _buildMetricCard(
//                 'Pending',
//                 pendingTasks.toString(),
//                 Icons.pending_actions,
//                 Colors.orange,
//               ),
//               _buildMetricCard(
//                 'Overdue',
//                 overdueTasks.toString(),
//                 Icons.warning_amber,
//                 Colors.red,
//               ),
//             ],
//           ),

//           // Completion Rate Circle
//           if (totalTasks > 0) ...[
//             const SizedBox(height: 24),
//             Text(
//               'Task Completion Rate',
//               style: Theme.of(context).textTheme.titleLarge,
//             ),
//             const SizedBox(height: 16),
//             Center(
//               child: SizedBox(
//                 height: 200,
//                 width: 200,
//                 child: Stack(
//                   alignment: Alignment.center,
//                   children: [
//                     CircularProgressIndicator(
//                       value: completedTasks / totalTasks,
//                       backgroundColor: Colors.grey.shade300,
//                       strokeWidth: 15,
//                       valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
//                     ),
//                     Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(
//                           '$completionRate%',
//                           style: Theme.of(context).textTheme.headlineMedium
//                               ?.copyWith(fontWeight: FontWeight.bold),
//                         ),
//                         Text(
//                           'Completed',
//                           style: Theme.of(context).textTheme.bodySmall,
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],

//           // High Priority Tasks Alert
//           if (highPriorityTasks > 0) ...[
//             const SizedBox(height: 24),
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.red.shade50,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Colors.red.shade200),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.priority_high, color: Colors.red.shade700),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'High Priority Tasks',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.red.shade700,
//                           ),
//                         ),
//                         Text(
//                           'You have $highPriorityTasks high priority tasks that need attention',
//                           style: TextStyle(color: Colors.red.shade700),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   // Categories Tab
//   Widget _buildCategoriesTab(List<Task> tasks, List<String> categories) {
//     // Calculate tasks per category
//     final Map<String, int> categoryCount = {};
//     final Map<String, int> completedCount = {};

//     // Count tasks in each category
//     for (final category in categories) {
//       categoryCount[category] =
//           tasks.where((task) => task.category == category).length;
//       completedCount[category] =
//           tasks
//               .where((task) => task.category == category && task.isCompleted)
//               .length;
//     }

//     return ListView.builder(
//       padding: const EdgeInsets.all(16.0),
//       itemCount: categories.length,
//       itemBuilder: (context, index) {
//         final category = categories[index];
//         final totalInCategory = categoryCount[category] ?? 0;
//         final completedInCategory = completedCount[category] ?? 0;
//         final completionPercent =
//             totalInCategory > 0
//                 ? (completedInCategory / totalInCategory * 100).round()
//                 : 0;

//         // Generate a color based on category
//         final categoryColor = _getCategoryColor(category);

//         return Card(
//           margin: const EdgeInsets.only(bottom: 16.0),
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Container(
//                       width: 16,
//                       height: 16,
//                       decoration: BoxDecoration(
//                         color: categoryColor,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       category,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 18,
//                       ),
//                     ),
//                     const Spacer(),
//                     Text(
//                       '$completedInCategory/$totalInCategory',
//                       style: TextStyle(
//                         color: Colors.grey.shade700,
//                         fontWeight: FontWeight.w500,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(4),
//                   child: LinearProgressIndicator(
//                     value: completionPercent / 100,
//                     backgroundColor: Colors.grey.shade200,
//                     color: categoryColor,
//                     minHeight: 8,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 // Add bar representation
//                 SizedBox(
//                   height: 100,
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       if (completedInCategory > 0)
//                         Expanded(
//                           flex: completedInCategory,
//                           child: Container(
//                             margin: const EdgeInsets.only(right: 4),
//                             decoration: BoxDecoration(
//                               color: categoryColor,
//                               borderRadius: const BorderRadius.vertical(
//                                 top: Radius.circular(4),
//                               ),
//                             ),
//                             height: 100,
//                             child: Center(
//                               child:
//                                   completedInCategory > 0
//                                       ? Text(
//                                         '$completedInCategory',
//                                         style: const TextStyle(
//                                           color: Colors.white,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       )
//                                       : null,
//                             ),
//                           ),
//                         ),
//                       if (totalInCategory - completedInCategory > 0)
//                         Expanded(
//                           flex: totalInCategory - completedInCategory,
//                           child: Container(
//                             decoration: BoxDecoration(
//                               color: Colors.grey.shade300,
//                               borderRadius: const BorderRadius.vertical(
//                                 top: Radius.circular(4),
//                               ),
//                             ),
//                             height: 100,
//                             child: Center(
//                               child:
//                                   (totalInCategory - completedInCategory) > 0
//                                       ? Text(
//                                         '${totalInCategory - completedInCategory}',
//                                         style: TextStyle(
//                                           color: Colors.grey.shade700,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       )
//                                       : null,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     _buildLegendItem('Completed', categoryColor),
//                     const SizedBox(width: 24),
//                     _buildLegendItem('Pending', Colors.grey.shade300),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // Productivity Tab
//   Widget _buildProductivityTab(List<Task> tasks) {
//     // Get dates for time range
//     final DateTime now = DateTime.now();
//     DateTime startDate;

//     switch (_timeRange) {
//       case 'Week':
//         startDate = now.subtract(const Duration(days: 7));
//         break;
//       case 'Month':
//         startDate = DateTime(now.year, now.month - 1, now.day);
//         break;
//       case 'Year':
//         startDate = DateTime(now.year - 1, now.month, now.day);
//         break;
//       default:
//         startDate = now.subtract(const Duration(days: 7));
//     }

//     // Filter tasks within date range
//     final filteredTasks =
//         tasks
//             .where(
//               (task) =>
//                   task.dueDate.isAfter(startDate) ||
//                   task.dueDate.isAtSameMomentAs(startDate),
//             )
//             .toList();

//     // Calculate productivity metrics
//     int totalCompleted = 0;
//     for (var task in filteredTasks) {
//       if (task.isCompleted) totalCompleted++;
//     }

//     final productivityRate =
//         filteredTasks.isNotEmpty
//             ? (totalCompleted / filteredTasks.length * 100).toStringAsFixed(1)
//             : '0.0';

//     // Get task activity by day
//     final Map<String, int> activityByDay = {};

//     // Initialize days
//     for (int i = 0; i <= 6; i++) {
//       final date = now.subtract(Duration(days: i));
//       final dateKey = DateFormat('E').format(date); // Day name abbreviation
//       activityByDay[dateKey] = 0;
//     }

//     // Count completed tasks by day
//     for (final task in filteredTasks.where((t) => t.isCompleted)) {
//       final dateKey = DateFormat('E').format(task.dueDate);
//       if (activityByDay.containsKey(dateKey)) {
//         activityByDay[dateKey] = (activityByDay[dateKey] ?? 0) + 1;
//       }
//     }

//     // Sort days in correct order (starting from today)
//     final sortedDays =
//         activityByDay.keys.toList()..sort((a, b) {
//           final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
//           final today = DateFormat('E').format(now);
//           final todayIndex = daysOfWeek.indexOf(today);

//           // Calculate relative positions
//           int aIndex = daysOfWeek.indexOf(a);
//           int bIndex = daysOfWeek.indexOf(b);

//           // Adjust indices relative to today
//           aIndex = (aIndex - todayIndex + 7) % 7;
//           bIndex = (bIndex - todayIndex + 7) % 7;

//           return aIndex.compareTo(bIndex);
//         });

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Card(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Row(
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Productivity Score',
//                         style: Theme.of(context).textTheme.titleMedium,
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         '$productivityRate%',
//                         style: Theme.of(
//                           context,
//                         ).textTheme.headlineMedium?.copyWith(
//                           fontWeight: FontWeight.bold,
//                           color: _getProductivityColor(
//                             double.parse(productivityRate),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const Spacer(),
//                   Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: _getProductivityColor(
//                         double.parse(productivityRate),
//                       ).withOpacity(0.2),
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(
//                       _getProductivityIcon(double.parse(productivityRate)),
//                       color: _getProductivityColor(
//                         double.parse(productivityRate),
//                       ),
//                       size: 32,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           const SizedBox(height: 24),
//           Text(
//             'Weekly Activity',
//             style: Theme.of(context).textTheme.titleLarge,
//           ),
//           const SizedBox(height: 16),

//           // Weekly activity chart
//           SizedBox(
//             height: 200,
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children:
//                   sortedDays.map((day) {
//                     final count = activityByDay[day] ?? 0;
//                     final maxCount = activityByDay.values.reduce(
//                       (a, b) => a > b ? a : b,
//                     );
//                     final percentage = maxCount > 0 ? count / maxCount : 0.0;

//                     return Expanded(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.end,
//                         children: [
//                           Text(
//                             count.toString(),
//                             style: TextStyle(
//                               color: count > 0 ? Colors.blue : Colors.grey,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Container(
//                             height: 120 * percentage,
//                             width: 24,
//                             decoration: BoxDecoration(
//                               color:
//                                   count > 0
//                                       ? Colors.blue
//                                       : Colors.grey.shade300,
//                               borderRadius: const BorderRadius.vertical(
//                                 top: Radius.circular(4),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(day),
//                         ],
//                       ),
//                     );
//                   }).toList(),
//             ),
//           ),

//           const SizedBox(height: 24),
//           Text('Task Activity', style: Theme.of(context).textTheme.titleLarge),
//           const SizedBox(height: 16),
//           _buildActivitySummary(filteredTasks),

//           // Task distribution by priority
//           const SizedBox(height: 24),
//           Text(
//             'Tasks by Priority',
//             style: Theme.of(context).textTheme.titleLarge,
//           ),
//           const SizedBox(height: 16),
//           _buildPriorityDistribution(filteredTasks),
//         ],
//       ),
//     );
//   }

//   // Helper method to build metric cards
//   Widget _buildMetricCard(
//     String title,
//     String value,
//     IconData iconData,
//     Color color,
//   ) {
//     return Expanded(
//       child: Card(
//         elevation: 2,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Icon(iconData, color: color),
//               const SizedBox(height: 12),
//               Text(
//                 value,
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: color,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 title,
//                 style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // Build Activity Summary Widget
//   Widget _buildActivitySummary(List<Task> tasks) {
//     // Calculate activity metrics
//     final addedToday = tasks.where((task) => _isDateToday(task.dueDate)).length;

//     final completedToday =
//         tasks
//             .where((task) => task.isCompleted && _isDateToday(task.dueDate))
//             .length;

//     return Row(
//       children: [
//         Expanded(
//           child: Card(
//             color: Colors.blue.shade50,
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 children: [
//                   Icon(Icons.add_task, color: Colors.blue.shade700),
//                   const SizedBox(height: 8),
//                   Text(
//                     addedToday.toString(),
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue.shade700,
//                     ),
//                   ),
//                   Text(
//                     'Added Today',
//                     style: TextStyle(color: Colors.blue.shade700),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//         Expanded(
//           child: Card(
//             color: Colors.green.shade50,
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 children: [
//                   Icon(Icons.check_circle, color: Colors.green.shade700),
//                   const SizedBox(height: 8),
//                   Text(
//                     completedToday.toString(),
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.green.shade700,
//                     ),
//                   ),
//                   Text(
//                     'Completed Today',
//                     style: TextStyle(color: Colors.green.shade700),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // Build priority distribution
//   Widget _buildPriorityDistribution(List<Task> tasks) {
//     // Count tasks by priority
//     final highTasks = tasks.where((task) => task.priority == 'High').length;
//     final mediumTasks = tasks.where((task) => task.priority == 'Medium').length;
//     final lowTasks = tasks.where((task) => task.priority == 'Low').length;

//     final total = highTasks + mediumTasks + lowTasks;

//     if (total == 0) {
//       return const Center(
//         child: Padding(
//           padding: EdgeInsets.all(16.0),
//           child: Text('No tasks available to analyze'),
//         ),
//       );
//     }

//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             // High priority
//             _buildPriorityBar('High', highTasks, total, Colors.red),
//             const SizedBox(height: 16),

//             // Medium priority
//             _buildPriorityBar('Medium', mediumTasks, total, Colors.orange),
//             const SizedBox(height: 16),

//             // Low priority
//             _buildPriorityBar('Low', lowTasks, total, Colors.green),
//           ],
//         ),
//       ),
//     );
//   }

//   // Build priority bar
//   Widget _buildPriorityBar(String priority, int count, int total, Color color) {
//     final percentage = total > 0 ? count / total * 100 : 0.0;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Container(
//               width: 12,
//               height: 12,
//               decoration: BoxDecoration(color: color, shape: BoxShape.circle),
//             ),
//             const SizedBox(width: 8),
//             Text(priority, style: const TextStyle(fontWeight: FontWeight.bold)),
//             const Spacer(),
//             Text('$count tasks (${percentage.toStringAsFixed(1)}%)'),
//           ],
//         ),
//         const SizedBox(height: 8),
//         ClipRRect(
//           borderRadius: BorderRadius.circular(4),
//           child: LinearProgressIndicator(
//             value: count / total,
//             backgroundColor: Colors.grey.shade200,
//             color: color,
//             minHeight: 8,
//           ),
//         ),
//       ],
//     );
//   }

//   // Helper to check if date is today
//   bool _isDateToday(DateTime date) {
//     final now = DateTime.now();
//     return date.year == now.year &&
//         date.month == now.month &&
//         date.day == now.day;
//   }

//   // Helper to build legend item
//   Widget _buildLegendItem(String label, Color color) {
//     return Row(
//       children: [
//         Container(width: 16, height: 16, color: color),
//         const SizedBox(width: 8),
//         Text(label),
//       ],
//     );
//   }

//   // Get color for category
//   Color _getCategoryColor(String category) {
//     switch (category) {
//       case 'Work':
//         return Colors.blue;
//       case 'Study':
//         return Colors.purple;
//       case 'Personal':
//         return Colors.orange;
//       case 'Shopping':
//         return Colors.teal;
//       case 'Health':
//         return Colors.green;
//       default:
//         // Generate a color based on category name
//         return Color((category.hashCode & 0xFFFFFF) | 0xFF000000);
//     }
//   }

//   // Get color based on productivity score
//   Color _getProductivityColor(double score) {
//     if (score >= 75) {
//       return Colors.green;
//     } else if (score >= 50) {
//       return Colors.orange;
//     } else {
//       return Colors.red;
//     }
//   }

//   // Get icon based on productivity score
//   IconData _getProductivityIcon(double score) {
//     if (score >= 75) {
//       return Icons.sentiment_very_satisfied;
//     } else if (score >= 50) {
//       return Icons.sentiment_satisfied;
//     } else {
//       return Icons.sentiment_dissatisfied;
//     }
//   }
// }
