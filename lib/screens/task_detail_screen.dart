import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskgenius/models/task.dart';
import 'package:taskgenius/services/ai_service.dart';
import 'package:taskgenius/state/task_provider.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late String _selectedCategory;
  late DateTime _selectedDate;
  late int _urgencyLevel;
  late String _predictedPriority;
  late bool _isCompleted;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with task data
    _titleController = TextEditingController(text: widget.task.title);
    _selectedCategory = widget.task.category;
    _selectedDate = widget.task.dueDate;
    _urgencyLevel = widget.task.urgencyLevel;
    _predictedPriority = widget.task.priority;
    _isCompleted = widget.task.isCompleted;
    
    // Initialize ML model
    _initML();
  }

  Future<void> _initML() async {
    try {
      await PriorityPredictor.initModel();
      _updatePredictedPriority();
    } catch (e) {
      print("Error initializing ML: $e");
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
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // Show confirmation dialog before deleting
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Task'),
                  content: const Text('Are you sure you want to delete this task?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        // Delete task and navigate back
                        taskProvider.deleteTask(widget.task.id);
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Go back to previous screen
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Completion status toggle
                Row(
                  children: [
                    Checkbox(
                      value: _isCompleted,
                      activeColor: Theme.of(context).primaryColor,
                      onChanged: (bool? value) {
                        if (value != null) {
                          setState(() {
                            _isCompleted = value;
                          });
                        }
                      },
                    ),
                    const Text(
                      'Mark as completed',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Title field
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
                
                // Category dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedCategory,
                  items: taskProvider.categories.map((String category) {
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
                
                // Due date selector
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
                      child: const Text('Change Date'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Urgency level slider
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
                
                const SizedBox(height: 24),
                
                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Create updated task
                        final updatedTask = Task(
                          id: widget.task.id,
                          title: _titleController.text,
                          category: _selectedCategory,
                          dueDate: _selectedDate,
                          urgencyLevel: _urgencyLevel,
                          priority: _predictedPriority,
                          isCompleted: _isCompleted,
                        );

                        // Update task using provider
                        taskProvider.updateTask(updatedTask);

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Task updated successfully!'),
                          ),
                        );
                        
                        // Navigate back
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Save Changes'),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Cancel button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
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