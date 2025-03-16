import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskgenius/main.dart';
import 'package:taskgenius/models/task.dart';
import 'package:taskgenius/services/ai_service.dart';
import 'package:taskgenius/state/task_provider.dart';

// Task input screen
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

  @override
  void initState() {
    super.initState();
    // Initialize Firebase and ML model
    _initFirebaseAndML();
  }

  Future<void> _initFirebaseAndML() async {
    try {
      await initializeFirebase();
      await PriorityPredictor.initModel();
      _updatePredictedPriority();
    } catch (e) {
      print("Error initializing Firebase and ML: $e");
    }
  }

  void _updatePredictedPriority() {
    setState(() {
      _predictedPriority = PriorityPredictor.predictPriority(
        _selectedDate,
        _urgencyLevel,
      );
    });
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
        // Update priority prediction when date changes
        _updatePredictedPriority();
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
                  const Text('Urgency Level:', style: TextStyle(fontSize: 16)),
                  Slider(
                    value: _urgencyLevel.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _urgencyLevel.toString(),
                    onChanged: (double value) {
                      setState(() {
                        _urgencyLevel = value.round();
                        // Update priority prediction when urgency changes
                        _updatePredictedPriority();
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Create a new task with AI-suggested priority
                      final newTask = Task(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: _titleController.text,
                        category: _selectedCategory,
                        dueDate: _selectedDate,
                        urgencyLevel: _urgencyLevel,
                        priority: _predictedPriority,
                      );

                      // Add task using provider
                      taskProvider.addTask(newTask);

                      // Clear the form
                      _titleController.clear();
                      setState(() {
                        _urgencyLevel = 3;
                        _selectedDate = DateTime.now();
                        _updatePredictedPriority();
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

