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
  // Add these fields for productivity data
  List<String> _productivityInsights = [];
  Map<String, dynamic> _productivityStats = {};
  bool _isLoadingProductivity = true;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProductivityData();
  }

  // Add this method to load productivity data
  Future<void> _loadProductivityData() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    try {
      final insights = await taskProvider.getProductivityInsights();
      final stats = await taskProvider.getProductivityStats();

      if (mounted) {
        setState(() {
          _productivityInsights = insights;
          _productivityStats = stats;
          _isLoadingProductivity = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading productivity data: $e');
      if (mounted) {
        setState(() {
          _isLoadingProductivity = false;
        });
      }
    }
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
                      clipRounded(
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
  Widget clipRounded({
    required BorderRadius borderRadius,
    required Widget child,
  }) {
    return ClipRRect(borderRadius: borderRadius, child: child);
  }

  // Productivity Tab
  // Widget _buildProductivityTab(List<Task> tasks) {
  //   // Get dates for time range
  //   final DateTime now = DateTime.now();
  //   DateTime startDate;

  //   switch (_timeRange) {
  //     case 'Week':
  //       startDate = now.subtract(const Duration(days: 7));
  //       break;
  //     case 'Month':
  //       startDate = DateTime(now.year, now.month - 1, now.day);
  //       break;
  //     case 'Year':
  //       startDate = DateTime(now.year - 1, now.month, now.day);
  //       break;
  //     default:
  //       startDate = now.subtract(const Duration(days: 7));
  //   }

  //   // Filter tasks within date range
  //   final filteredTasks =
  //       tasks
  //           .where(
  //             (task) =>
  //                 task.dueDate.isAfter(startDate) ||
  //                 task.dueDate.isAtSameMomentAs(startDate),
  //           )
  //           .toList();

  //   // Group tasks by date
  //   final Map<String, int> completedByDate = {};
  //   final Map<String, int> addedByDate = {};

  //   // Format pattern based on time range
  //   String dateFormat;
  //   if (_timeRange == 'Week') {
  //     dateFormat = 'E'; // Abbreviated day name
  //   } else if (_timeRange == 'Month') {
  //     dateFormat = 'dd'; // Day of month
  //   } else {
  //     dateFormat = 'MMM'; // Abbreviated month name
  //   }

  //   // Initialize dates in range
  //   for (int i = 0; i <= now.difference(startDate).inDays; i++) {
  //     final date = startDate.add(Duration(days: i));
  //     final dateKey = DateFormat(dateFormat).format(date);

  //     completedByDate[dateKey] = 0;
  //     addedByDate[dateKey] = 0;
  //   }

  //   // Count tasks
  //   for (final task in filteredTasks) {
  //     final dateKey = DateFormat(dateFormat).format(task.dueDate);

  //     // Count as added
  //     if (addedByDate.containsKey(dateKey)) {
  //       addedByDate[dateKey] = (addedByDate[dateKey] ?? 0) + 1;
  //     }

  //     // Count as completed if completed
  //     if (task.isCompleted && completedByDate.containsKey(dateKey)) {
  //       completedByDate[dateKey] = (completedByDate[dateKey] ?? 0) + 1;
  //     }
  //   }

  //   // Calculate productivity metrics
  //   int totalCompleted = 0;
  //   for (var task in filteredTasks) {
  //     if (task.isCompleted) totalCompleted++;
  //   }

  //   final productivityRate =
  //       filteredTasks.isNotEmpty
  //           ? (totalCompleted / filteredTasks.length * 100).toStringAsFixed(1)
  //           : '0.0';

  //   return SingleChildScrollView(
  //     padding: const EdgeInsets.all(16.0),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Card(
  //           child: Padding(
  //             padding: const EdgeInsets.all(16.0),
  //             child: Row(
  //               children: [
  //                 Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text(
  //                       'Productivity Score',
  //                       style: Theme.of(context).textTheme.titleMedium,
  //                     ),
  //                     const SizedBox(height: 8),
  //                     Text(
  //                       '$productivityRate%',
  //                       style: Theme.of(
  //                         context,
  //                       ).textTheme.headlineMedium?.copyWith(
  //                         fontWeight: FontWeight.bold,
  //                         color: _getProductivityColor(
  //                           double.parse(productivityRate),
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //                 const Spacer(),
  //                 Container(
  //                   padding: const EdgeInsets.all(12),
  //                   decoration: BoxDecoration(
  //                     color: _getProductivityColor(
  //                       double.parse(productivityRate),
  //                     ).withOpacity(0.2),
  //                     shape: BoxShape.circle,
  //                   ),
  //                   child: Icon(
  //                     _getProductivityIcon(double.parse(productivityRate)),
  //                     color: _getProductivityColor(
  //                       double.parse(productivityRate),
  //                     ),
  //                     size: 32,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),

  //         const SizedBox(height: 24),
  //         Text(
  //           'Productivity Over Time',
  //           style: Theme.of(context).textTheme.titleLarge,
  //         ),
  //         const SizedBox(height: 16),
  //         SizedBox(
  //           height: 250,
  //           child: _buildProductivityLineChart(completedByDate, addedByDate),
  //         ),

  //         const SizedBox(height: 24),
  //         Text('Task Activity', style: Theme.of(context).textTheme.titleLarge),
  //         const SizedBox(height: 16),
  //         _buildActivitySummary(filteredTasks),
  //       ],
  //     ),
  //   );
  // }
  // Modified Productivity Tab with AI insights
  Widget _buildProductivityTab(List<Task> tasks) {
    if (_isLoadingProductivity) {
      return const Center(child: CircularProgressIndicator());
    }

    // Get productivity data from loaded stats
    final completionRate = (_productivityStats['completionRate'] ?? 0.0) * 100;
    final mostProductiveDay =
        _productivityStats['mostProductiveDay'] ?? 'Unknown';
    final mostProductiveTime =
        _productivityStats['mostProductiveTime'] ?? 'Unknown';
    final streak = _productivityStats['streak'] ?? 0;
    final categoryStats =
        _productivityStats['categoryStats'] as Map<String, int>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Productivity Score Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weekly Productivity Score',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${completionRate.toStringAsFixed(1)}%',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _getProductivityColor(completionRate),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getProductivityColor(
                            completionRate,
                          ).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getProductivityIcon(completionRate),
                          color: _getProductivityColor(completionRate),
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                  if (streak > 0) ...[
                    const Divider(height: 32),
                    Row(
                      children: [
                        Icon(Icons.local_fire_department, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          '$streak Day Streak!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // AI Insights
          Text(
            'AI Productivity Insights',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Display insights as cards
          ..._productivityInsights.map(
            (insight) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  _getInsightIcon(insight),
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(insight),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Productivity Patterns
          Text(
            'Your Productivity Patterns',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Most Productive Day
          Card(
            child: ListTile(
              leading: Icon(Icons.calendar_today, color: Colors.blue),
              title: Text('Most Productive Day'),
              subtitle: Text(mostProductiveDay),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ),

          const SizedBox(height: 8),

          // Most Productive Time
          Card(
            child: ListTile(
              leading: Icon(Icons.access_time, color: Colors.orange),
              title: Text('Most Productive Time'),
              subtitle: Text(mostProductiveTime),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ),

          const SizedBox(height: 24),

          // Category Productivity
          if (categoryStats.isNotEmpty) ...[
            Text(
              'Tasks Completed by Category',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: _buildCategoryPieChart(categoryStats)),
          ],

          const SizedBox(height: 24),

          // Productivity Over Time (your existing chart)
          Text(
            'Productivity Over Time',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // [The rest of your existing productivity chart code goes here]
          _buildProductivityTimelineSection(tasks),
        ],
      ),
    );
  }

  Widget _buildCategoryPieChart(Map<String, int> categoryStats) {
    final total = categoryStats.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );
    if (total == 0) return const Center(child: Text('No data available'));

    return PieChart(
      PieChartData(
        sections:
            categoryStats.entries.map((entry) {
              final percentage = (entry.value / total * 100);
              return PieChartSectionData(
                value: entry.value.toDouble(),
                title: '${percentage.toStringAsFixed(1)}%',
                color: _getCategoryColor(entry.key),
                radius: 80,
                titleStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  // Helper method for building the existing productivity timeline
  Widget _buildProductivityTimelineSection(List<Task> tasks) {
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

    final filteredTasks =
        tasks
            .where(
              (task) =>
                  task.dueDate.isAfter(startDate) ||
                  task.dueDate.isAtSameMomentAs(startDate),
            )
            .toList();

    final Map<String, int> completedByDate = {};
    final Map<String, int> addedByDate = {};

    String dateFormat;
    if (_timeRange == 'Week') {
      dateFormat = 'E';
    } else if (_timeRange == 'Month') {
      dateFormat = 'dd';
    } else {
      dateFormat = 'MMM';
    }

    for (int i = 0; i <= now.difference(startDate).inDays; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey = DateFormat(dateFormat).format(date);
      completedByDate[dateKey] = 0;
      addedByDate[dateKey] = 0;
    }

    for (final task in filteredTasks) {
      final dateKey = DateFormat(dateFormat).format(task.dueDate);
      if (addedByDate.containsKey(dateKey)) {
        addedByDate[dateKey] = (addedByDate[dateKey] ?? 0) + 1;
      }
      if (task.isCompleted && completedByDate.containsKey(dateKey)) {
        completedByDate[dateKey] = (completedByDate[dateKey] ?? 0) + 1;
      }
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: _buildProductivityLineChart(completedByDate, addedByDate),
        ),
        const SizedBox(height: 24),
        Text('Task Activity', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildActivitySummary(filteredTasks),
      ],
    );
  }

  // New helper methods for productivity insights
  IconData _getInsightIcon(String insight) {
    if (insight.contains('productive on')) {
      return Icons.calendar_today;
    } else if (insight.contains('tasks in the')) {
      return Icons.access_time;
    } else if (insight.contains('completion rate')) {
      return Icons.show_chart;
    } else if (insight.contains('streak')) {
      return Icons.local_fire_department;
    } else if (insight.contains('complete the most')) {
      return Icons.category;
    }
    return Icons.lightbulb_outline;
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
