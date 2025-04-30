//***************************************** */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskgenius/models/task.dart';
import 'package:taskgenius/services/ai_service.dart';
import 'package:taskgenius/state/task_provider.dart';

class TaskInputScreen extends StatefulWidget {
  const TaskInputScreen({super.key});

  @override
  _TaskInputScreenState createState() => _TaskInputScreenState();
}

class _TaskInputScreenState extends State<TaskInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  String _selectedCategory = 'Work';
  DateTime _selectedDate = DateTime.now();
  int _urgencyLevel = 3; // Default mid-level urgency
  String _predictedPriority = "Medium";
  Duration _estimatedDuration = const Duration(minutes: 30);
  // Scheduling fields
  Map<String, dynamic>? _scheduleSuggestion;
  @override
  void initState() {
    super.initState();
    // Initialize ML models
    _initModels();
  }

  Future<void> _initModels() async {
    try {
      await PriorityPredictor.initModel();
      await DurationEstimator.initModel();
      await TaskScheduler.initModels();

      _updatePredictions();
    } catch (e) {
      print("Error initializing ML models: $e");
    }
  }

  void _updatePredictions() {
    setState(() {
      // Update priority prediction
      _predictedPriority = PriorityPredictor.predictPriority(
        _selectedDate,
        _urgencyLevel,
      );

      // Update duration estimation using category, urgency level, and due date
      _estimatedDuration = DurationEstimator.estimateTaskDuration(
        _selectedCategory,
        _urgencyLevel,
        _selectedDate,
      );
      // Update schedule suggestion
      _updateScheduleSuggestion();
    });
  }

  void _updateScheduleSuggestion() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final userPreferences = taskProvider.userPreferences;

    // Get user preferences for scheduling
    final availableHours = userPreferences['availableHours'] as int;
    final timePreference = userPreferences['timePreference'] as int;

    // Get schedule suggestion
    _scheduleSuggestion = TaskScheduler.suggestSchedule(
      priority: _predictedPriority,
      duration: _estimatedDuration,
      userAvailabilityHours: availableHours,
      timePreference: timePreference,
      dueDate: _selectedDate,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Update predictions when date changes
        _updatePredictions();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Task')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a task title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedCategory,
                  items:
                      taskProvider.categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCategory = newValue;
                        // Update duration estimation when category changes
                        _updatePredictions();
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Due Date: ${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _selectDate(context),
                      child: const Text('Select Date'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Urgency Level:',
                      style: TextStyle(fontSize: 16),
                    ),
                    Slider(
                      value: _urgencyLevel.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: _urgencyLevel.toString(),
                      onChanged: (double value) {
                        setState(() {
                          _urgencyLevel = value.round();
                          // Update both priority and duration predictions when urgency changes
                          _updatePredictions();
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [Text('Low'), Text('High')],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // AI-suggested priority card
                Card(
                  elevation: 3,
                  color: _getPriorityColor(_predictedPriority).withOpacity(0.2),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: _getPriorityColor(_predictedPriority),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AI-Suggested Priority:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _predictedPriority,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: _getPriorityColor(_predictedPriority),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Estimated duration card
                Card(
                  elevation: 3,
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AI-Estimated Duration:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                DurationEstimator.formatDuration(
                                  _estimatedDuration,
                                ),
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                // Suggested Schedule Card
                if (_scheduleSuggestion != null)
                  Card(
                    elevation: 3,
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.schedule, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'AI-Suggested Schedule:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  TaskScheduler.getScheduleDescription(
                                    _scheduleSuggestion!['day'],
                                    _scheduleSuggestion!['timeSlotName'],
                                  ),
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
                // User Preferences Section
                ExpansionTile(
                  title: const Text('Scheduling Preferences'),
                  leading: const Icon(Icons.settings),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Available Hours Per Day:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Slider(
                            value:
                                taskProvider.userPreferences['availableHours']
                                    .toDouble(),
                            min: 1,
                            max: 12,
                            divisions: 11,
                            label:
                                taskProvider.userPreferences['availableHours']
                                    .toString(),
                            onChanged: (double value) {
                              taskProvider.updateUserPreferences(
                                availableHours: value.round(),
                              );
                              _updateScheduleSuggestion();
                            },
                          ),
                          Text(
                            '${taskProvider.userPreferences['availableHours']} hours',
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),

                          const SizedBox(height: 16),

                          const Text(
                            'Preferred Time of Day:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              _buildTimePreferenceButton(
                                context,
                                'Morning',
                                Icons.wb_sunny,
                                0,
                                taskProvider,
                              ),
                              _buildTimePreferenceButton(
                                context,
                                'Afternoon',
                                Icons.wb_cloudy,
                                1,
                                taskProvider,
                              ),
                              _buildTimePreferenceButton(
                                context,
                                'Evening',
                                Icons.nightlight_round,
                                2,
                                taskProvider,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Create a new task with AI-suggested priority and duration
                        // Create a new task with AI-suggested priority and duration
                        final newTask = Task(
                          title: _titleController.text,
                          category: _selectedCategory,
                          dueDate: _selectedDate,
                          urgencyLevel: _urgencyLevel,
                          priority: _predictedPriority,
                          estimatedDuration: _estimatedDuration,
                          scheduledDay: _scheduleSuggestion?['day'],
                          scheduledTimeSlot: _scheduleSuggestion?['timeSlot'],
                          scheduledTimeDescription:
                              _scheduleSuggestion != null
                                  ? TaskScheduler.getScheduleDescription(
                                    _scheduleSuggestion!['day'],
                                    _scheduleSuggestion!['timeSlotName'],
                                  )
                                  : null,
                        );

                        // Add task using provider
                        taskProvider.addTask(newTask);

                        // Clear the form
                        _titleController.clear();
                        setState(() {
                          _urgencyLevel = 3;
                          _selectedDate = DateTime.now();
                          _updatePredictions();
                        });

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Task added successfully!'),
                          ),
                        );
                      }
                    },
                    child: const Text('Add Task'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build a time preference button
  Widget _buildTimePreferenceButton(
    BuildContext context,
    String label,
    IconData icon,
    int value,
    TaskProvider taskProvider,
  ) {
    final isSelected = taskProvider.userPreferences['timePreference'] == value;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () {
            taskProvider.updateUserPreferences(timePreference: value);
            _updateScheduleSuggestion();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade200,
            foregroundColor: isSelected ? Colors.white : Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
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
}
