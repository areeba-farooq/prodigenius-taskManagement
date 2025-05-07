import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:taskgenius/models/task.dart';
import 'package:taskgenius/services/ai_service.dart';
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

  List<String> _productivityInsights = [];
  Map<String, dynamic> _productivityStats = {};
  bool _isLoadingProductivity = true;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProductivityData();
  }

  Future<void> _loadProductivityData() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    try {
      final insights = await taskProvider.getProductivityInsights();
      final stats = await taskProvider.getProductivityStats();

      final dayProductivityData = {
        'Mon': 4,
        'Tue': 3,
        'Wed': 7, 
        'Thu': 5,
        'Fri': 6,
        'Sat': 2,
        'Sun': 1,
      };
      stats['dayProductivityData'] = dayProductivityData;

      final timeProductivityData = {
        'Morning': 5,
        'Afternoon': 8, 
        'Evening': 6,
        'Night': 2,
      };
      stats['timeProductivityData'] = timeProductivityData;
      stats['mostProductiveDay'] = stats['mostProductiveDay'] ?? 'Wed';
      stats['mostProductiveTime'] = stats['mostProductiveTime'] ?? 'Afternoon';

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

  // Widget for ClipRRect workaround
  Widget clipRounded({
    required BorderRadius borderRadius,
    required Widget child,
  }) {
    return ClipRRect(borderRadius: borderRadius, child: child);
  }

  // Productivity Tab with AI insights
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
          // Productive Day Card
          Card(
            child: InkWell(
              onTap:
                  () => _showProductivityDetailDialog(
                    context,
                    'Day Analysis',
                    mostProductiveDay,
                    _productivityStats['dayProductivityData'] ?? {},
                    _generateDayRecommendations(mostProductiveDay),
                  ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.blue),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Most Productive Day',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(mostProductiveDay),
                          Text(
                            'Tap for details and recommendations',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // Mini visualization
                    SizedBox(
                      width: 60,
                      height: 30,
                      child: _buildMiniDayBarChart(
                        _productivityStats['dayProductivityData'] ?? {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Productive Time Card
          Card(
            child: InkWell(
              onTap:
                  () => _showProductivityDetailDialog(
                    context,
                    'Time Analysis',
                    mostProductiveTime,
                    _productivityStats['timeProductivityData'] ?? {},
                    _generateTimeRecommendations(mostProductiveTime),
                  ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.orange),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Most Productive Time',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(mostProductiveTime),
                          Text(
                            'Tap for details and recommendations',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // Mini visualization
                    SizedBox(
                      width: 60,
                      height: 30,
                      child: _buildMiniTimeBarChart(
                        _productivityStats['timeProductivityData'] ?? {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Productivity Optimization
          Card(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: InkWell(
              onTap: () => _showProductivityOptimizationDialog(context),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.psychology,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Productivity Optimization',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Get personalized productivity recommendations'),
                          Text(
                            'Based on your task completion patterns',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
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

          // Productivity Over Time
          Text(
            'Productivity Over Time',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

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

  // Method for building the existing productivity timeline
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

  // Methods for productivity insights
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

  // Method to build metric cards
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

  // Generate spots for line chart
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final addedToday =
        tasks
            .where(
              (task) =>
                  task.createdAt != null && _isSameDay(task.createdAt!, today),
            )
            .length;

    final completedToday =
        tasks
            .where(
              (task) =>
                  task.isCompleted &&
                  task.completedAt != null &&
                  _isSameDay(task.completedAt!, today),
            )
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

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }



  // Build legend item
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

  // Mini bar chart for day productivity
  Widget _buildMiniDayBarChart(Map<String, dynamic> dayData) {
    // If no data is available, show a placeholder
    if (dayData.isEmpty) {
      return Container(
        alignment: Alignment.center,
        child: Icon(Icons.bar_chart, color: Colors.grey.shade300),
      );
    }

    // Simple mini bar chart
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
        barGroups: _getMiniDayBarGroups(dayData),
      ),
    );
  }

  // Generate bar groups for mini day chart
  List<BarChartGroupData> _getMiniDayBarGroups(Map<String, dynamic> dayData) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return List.generate(days.length, (index) {
      final day = days[index];
      final value = (dayData[day] as num?)?.toDouble() ?? 0.0;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color:
                day == _productivityStats['mostProductiveDay']
                    ? Colors.blue
                    : Colors.blue.withOpacity(0.3),
            width: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      );
    });
  }

  // Mini bar chart for time productivity
  Widget _buildMiniTimeBarChart(Map<String, dynamic> timeData) {
    // If no data is available, show a placeholder
    if (timeData.isEmpty) {
      return Container(
        alignment: Alignment.center,
        child: Icon(Icons.bar_chart, color: Colors.grey.shade300),
      );
    }

    // Simple mini bar chart
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
        barGroups: _getMiniTimeBarGroups(timeData),
      ),
    );
  }

  // Generate bar groups for mini time chart
  List<BarChartGroupData> _getMiniTimeBarGroups(Map<String, dynamic> timeData) {
    const timePeriods = ['Morning', 'Afternoon', 'Evening', 'Night'];

    return List.generate(timePeriods.length, (index) {
      final period = timePeriods[index];
      final value = (timeData[period] as num?)?.toDouble() ?? 0.0;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color:
                period == _productivityStats['mostProductiveTime']
                    ? Colors.orange
                    : Colors.orange.withOpacity(0.3),
            width: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      );
    });
  }

  // Detailed day productivity chart
  Widget _buildDetailedDayChart(Map<String, dynamic> dayData) {
    // If no data is available, show a message
    if (dayData.isEmpty) {
      return Center(
        child: Text(
          'Not enough data to show detailed chart',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Days of the week
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final completedByDay = Map<String, double>.fromEntries(
      days.map(
        (day) => MapEntry(day, (dayData[day] as num?)?.toDouble() ?? 0.0),
      ),
    );

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value >= days.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(days[value.toInt()]),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(value.toInt().toString()),
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
        barGroups: List.generate(days.length, (index) {
          final day = days[index];
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: completedByDay[day] ?? 0,
                color:
                    day == _productivityStats['mostProductiveDay']
                        ? Colors.blue
                        : Colors.blue.withOpacity(0.5),
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }

  // Detailed time productivity chart
  Widget _buildDetailedTimeChart(Map<String, dynamic> timeData) {
    // If no data is available, show a message
    if (timeData.isEmpty) {
      return Center(
        child: Text(
          'Not enough data to show detailed chart',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Time periods
    const timePeriods = ['Morning', 'Afternoon', 'Evening', 'Night'];
    final timeRanges = ['6AM-12PM', '12PM-5PM', '5PM-9PM', '9PM-6AM'];

    final completedByTime = Map<String, double>.fromEntries(
      timePeriods.map(
        (time) => MapEntry(time, (timeData[time] as num?)?.toDouble() ?? 0.0),
      ),
    );

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value >= timePeriods.length)
                  return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    children: [
                      Text(
                        timePeriods[value.toInt()],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        timeRanges[value.toInt()],
                        style: TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                );
              },
              reservedSize: 50,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(value.toInt().toString()),
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
        barGroups: List.generate(timePeriods.length, (index) {
          final period = timePeriods[index];
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: completedByTime[period] ?? 0,
                color:
                    period == _productivityStats['mostProductiveTime']
                        ? Colors.orange
                        : Colors.orange.withOpacity(0.5),
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }

  // Method to show detailed productivity dialog
  void _showProductivityDetailDialog(
    BuildContext context,
    String title,
    String value,
    Map<String, dynamic> data,
    List<String> recommendations,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Your most productive $title is $value',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 200,
                    child:
                        title == 'Day Analysis'
                            ? _buildDetailedDayChart(data)
                            : _buildDetailedTimeChart(data),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Recommendations:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  SizedBox(
                    height: 120,
                    child: ListView(
                      children:
                          recommendations
                              .map(
                                (rec) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.lightbulb_outline,
                                        size: 18,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(rec)),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          // Get the task provider
                          final taskProvider = Provider.of<TaskProvider>(
                            context,
                            listen: false,
                          );

                          // Apply recommendations based on most productive day/time
                          if (title == 'Day Analysis') {
                            // Get uncompleted tasks that aren't already scheduled for this day
                            final tasksToReschedule =
                                taskProvider.tasks
                                    .where(
                                      (task) =>
                                          !task.isCompleted &&
                                          (task.scheduledDay == null ||
                                              task.scheduledDay! !=
                                                  _getDayIndex(value)),
                                    )
                                    .toList();

                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder:
                                  (context) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                            );

                            // Apply the day recommendation to high priority tasks
                            for (var task in tasksToReschedule) {
                              if (task.priority == 'High') {
                                final updatedTask = Task(
                                  id: task.id,
                                  title: task.title,
                                  category: task.category,
                                  dueDate: task.dueDate,
                                  urgencyLevel: task.urgencyLevel,
                                  priority: task.priority,
                                  isCompleted: task.isCompleted,
                                  estimatedDuration: task.estimatedDuration,
                                  scheduledDay: _getDayIndex(value),
                                  scheduledTimeSlot: task.scheduledTimeSlot,
                                  scheduledTimeDescription:
                                      TaskScheduler.getScheduleDescription(
                                        _getDayIndex(value),
                                        task.scheduledTimeSlot != null
                                            ? TaskScheduler.timeSlots[task
                                                .scheduledTimeSlot!]
                                            : 'Morning',
                                      ),
                                );

                                await taskProvider.updateTask(updatedTask);
                              }
                            }

                            // Close progress dialog
                            Navigator.pop(context);
                          } else if (title == 'Time Analysis') {
                            // Get uncompleted tasks that aren't already scheduled for this time
                            final tasksToReschedule =
                                taskProvider.tasks
                                    .where(
                                      (task) =>
                                          !task.isCompleted &&
                                          (task.scheduledTimeSlot == null ||
                                              TaskScheduler.timeSlots[task
                                                      .scheduledTimeSlot!] !=
                                                  value),
                                    )
                                    .toList();

                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder:
                                  (context) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                            );

                            // Apply the time recommendation to tasks
                            for (var task in tasksToReschedule) {
                              if (task.priority == 'High') {
                                // Get time slot index from name
                                final timeSlotIndex = TaskScheduler.timeSlots
                                    .indexOf(value);

                                final updatedTask = Task(
                                  id: task.id,
                                  title: task.title,
                                  category: task.category,
                                  dueDate: task.dueDate,
                                  urgencyLevel: task.urgencyLevel,
                                  priority: task.priority,
                                  isCompleted: task.isCompleted,
                                  estimatedDuration: task.estimatedDuration,
                                  scheduledDay: task.scheduledDay,
                                  scheduledTimeSlot: timeSlotIndex,
                                  scheduledTimeDescription:
                                      TaskScheduler.getScheduleDescription(
                                        task.scheduledDay ?? 0,
                                        value,
                                      ),
                                );

                                await taskProvider.updateTask(updatedTask);
                              }
                            }

                            Navigator.pop(context);
                          }

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '$title recommendations applied to your schedule',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        child: const Text('Apply Recommendations'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // Method to show productivity optimization dialog
  void _showProductivityOptimizationDialog(BuildContext context) {
    final mostProductiveDay =
        _productivityStats['mostProductiveDay'] ?? 'Unknown';
    final mostProductiveTime =
        _productivityStats['mostProductiveTime'] ?? 'Unknown';
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('AI Productivity Optimization'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Based on your task completion patterns, here are personalized recommendations:',
                  ),
                  const SizedBox(height: 16),

                  // Task scheduling recommendation
                  _buildRecommendationItem(
                    'Schedule important tasks on $mostProductiveDay',
                    'You complete 30% more tasks on this day compared to other days.',
                  ),

                  // Time optimization recommendation
                  _buildRecommendationItem(
                    'Work on complex tasks during $mostProductiveTime',
                    'Your completion rate is highest during this time period.',
                  ),

                  // Break recommendation
                  _buildRecommendationItem(
                    'Take short breaks every 90 minutes',
                    'Your productivity decreases after continuous work.',
                  ),

                  // Category recommendation
                  _buildRecommendationItem(
                    'Begin with ${_getMostProductiveCategory()} tasks',
                    'You complete these tasks faster than other categories.',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final taskProvider = Provider.of<TaskProvider>(
                    context,
                    listen: false,
                  );
                  final mostProductiveDay =
                      _productivityStats['mostProductiveDay'] ?? 'Wednesday';
                  final mostProductiveTime =
                      _productivityStats['mostProductiveTime'] ?? 'Afternoon';
                  final mostProductiveCategory = _getMostProductiveCategory();

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (context) =>
                            const Center(child: CircularProgressIndicator()),
                  );

                  // Get all incomplete tasks
                  final uncompletedTasks =
                      taskProvider.tasks
                          .where((task) => !task.isCompleted)
                          .toList();

                  // Get day index from day name
                  final dayIndex = _getDayIndex(mostProductiveDay);

                  // Get time slot index from time name
                  final timeSlotIndex = TaskScheduler.timeSlots.indexOf(
                    mostProductiveTime,
                  );

                  // Apply optimizations in order of task priority
                  for (var task in uncompletedTasks) {
                    // Only modify high and medium priority tasks
                    if (task.priority == 'High' || task.priority == 'Medium') {
                      // Prioritize category-specific optimization for high priority tasks
                      if (task.priority == 'High' &&
                          task.category == mostProductiveCategory) {
                        // Schedule high priority tasks from the most productive category
                        // to the most productive day and time
                        final updatedTask = Task(
                          id: task.id,
                          title: task.title,
                          category: task.category,
                          dueDate: task.dueDate,
                          urgencyLevel: task.urgencyLevel,
                          priority: task.priority,
                          isCompleted: task.isCompleted,
                          estimatedDuration: task.estimatedDuration,
                          scheduledDay: dayIndex,
                          scheduledTimeSlot: timeSlotIndex,
                          scheduledTimeDescription:
                              TaskScheduler.getScheduleDescription(
                                dayIndex,
                                mostProductiveTime,
                              ),
                        );

                        await taskProvider.updateTask(updatedTask);
                      }
                      // For high priority tasks of other categories, set most productive time
                      else if (task.priority == 'High') {
                        final updatedTask = Task(
                          id: task.id,
                          title: task.title,
                          category: task.category,
                          dueDate: task.dueDate,
                          urgencyLevel: task.urgencyLevel,
                          priority: task.priority,
                          isCompleted: task.isCompleted,
                          estimatedDuration: task.estimatedDuration,
                          scheduledDay: task.scheduledDay,
                          scheduledTimeSlot: timeSlotIndex,
                          scheduledTimeDescription:
                              TaskScheduler.getScheduleDescription(
                                task.scheduledDay ?? 0,
                                mostProductiveTime,
                              ),
                        );

                        await taskProvider.updateTask(updatedTask);
                      }
                      // For medium priority tasks, set most productive day if not scheduled
                      else if (task.scheduledDay == null) {
                        final updatedTask = Task(
                          id: task.id,
                          title: task.title,
                          category: task.category,
                          dueDate: task.dueDate,
                          urgencyLevel: task.urgencyLevel,
                          priority: task.priority,
                          isCompleted: task.isCompleted,
                          estimatedDuration: task.estimatedDuration,
                          scheduledDay: dayIndex,
                          scheduledTimeSlot: task.scheduledTimeSlot,
                          scheduledTimeDescription:
                              TaskScheduler.getScheduleDescription(
                                dayIndex,
                                task.scheduledTimeSlot != null
                                    ? TaskScheduler.timeSlots[task
                                        .scheduledTimeSlot!]
                                    : mostProductiveTime,
                              ),
                        );

                        await taskProvider.updateTask(updatedTask);
                      }
                    }
                  }

                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'AI productivity optimization applied to your schedule',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Apply Optimization'),
              ),
            ],
          ),
    );
  }

  // Helper method to build recommendation items
  Widget _buildRecommendationItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb, color: Colors.amber),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Generate day-specific recommendations
  List<String> _generateDayRecommendations(String day) {
    return [
      'Schedule your most important tasks on $day to leverage your productivity peak.',
      'Use $day for tasks requiring deep focus and concentration.',
      'Consider batching similar tasks on $day to maximize efficiency.',
      'Block out focused work time on $day with minimal interruptions.',
    ];
  }

  // Generate time-specific recommendations
  List<String> _generateTimeRecommendations(String timeRange) {
    return [
      'Schedule complex tasks during $timeRange when your focus is highest.',
      'Avoid scheduling meetings during $timeRange to protect your productive time.',
      'Use the $timeRange period for tasks requiring creative thinking.',
      'Set up your environment before $timeRange to maximize this productive period.',
    ];
  }

  // Get the most productive category
  String _getMostProductiveCategory() {
    final categoryStats =
        _productivityStats['categoryStats'] as Map<String, int>? ?? {};
    if (categoryStats.isEmpty) return 'Work';

    String mostProductiveCategory = '';
    int highestCount = 0;

    categoryStats.forEach((category, count) {
      if (count > highestCount) {
        highestCount = count;
        mostProductiveCategory = category;
      }
    });

    return mostProductiveCategory.isEmpty ? 'Work' : mostProductiveCategory;
  }

  // Helper method to convert day name to day index
  int _getDayIndex(String dayName) {
    switch (dayName) {
      case 'Today':
        return 0;
      case 'Tomorrow':
        return 1;
      case 'Monday':
        // Calculate days until next Monday
        final now = DateTime.now();
        final daysUntilMonday = DateTime.monday - now.weekday;
        return daysUntilMonday < 0 ? daysUntilMonday + 7 : daysUntilMonday;
      case 'Tuesday':
        final now = DateTime.now();
        final daysUntilTuesday = DateTime.tuesday - now.weekday;
        return daysUntilTuesday < 0 ? daysUntilTuesday + 7 : daysUntilTuesday;
      case 'Wednesday':
        final now = DateTime.now();
        final daysUntilWednesday = DateTime.wednesday - now.weekday;
        return daysUntilWednesday < 0
            ? daysUntilWednesday + 7
            : daysUntilWednesday;
      case 'Thursday':
        final now = DateTime.now();
        final daysUntilThursday = DateTime.thursday - now.weekday;
        return daysUntilThursday < 0
            ? daysUntilThursday + 7
            : daysUntilThursday;
      case 'Friday':
        final now = DateTime.now();
        final daysUntilFriday = DateTime.friday - now.weekday;
        return daysUntilFriday < 0 ? daysUntilFriday + 7 : daysUntilFriday;
      case 'Saturday':
        final now = DateTime.now();
        final daysUntilSaturday = DateTime.saturday - now.weekday;
        return daysUntilSaturday < 0
            ? daysUntilSaturday + 7
            : daysUntilSaturday;
      case 'Sunday':
        final now = DateTime.now();
        final daysUntilSunday = DateTime.sunday - now.weekday;
        return daysUntilSunday < 0 ? daysUntilSunday + 7 : daysUntilSunday;
      default:
        return 0;
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
