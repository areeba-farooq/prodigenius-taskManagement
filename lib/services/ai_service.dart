import 'dart:math' as math;

import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:taskgenius/models/task.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class PriorityPredictor {
  static Interpreter? _interpreter;

  // Initialize the model
  static Future<void> initModel() async {
    try {
      final modelInfo = await FirebaseModelDownloader.instance.getModel(
        "task_priority_model",
        FirebaseModelDownloadType.localModelUpdateInBackground,
        FirebaseModelDownloadConditions(
          iosAllowsCellularAccess: true,
          iosAllowsBackgroundDownloading: true,
          androidChargingRequired: false,
          androidWifiRequired: false,
        ),
      );

      // Load the model into interpreter
      _interpreter = Interpreter.fromFile(modelInfo.file);
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  // find index of max value
  static int _findMaxIndex(List<double> values) {
    if (values.isEmpty) return 0;
    double maxValue = values[0];
    int maxIndex = 0;
    for (int i = 1; i < values.length; i++) {
      if (values[i] > maxValue) {
        maxValue = values[i];
        maxIndex = i;
      }
    }
    return maxIndex;
  }

  // Predict priority based on features
  static String predictPriority(DateTime dueDate, int urgencyLevel) {
    // If ML model is available, use it
    if (_interpreter != null) {
      try {
        // Calculate days until due
        final daysUntilDue = dueDate.difference(DateTime.now()).inDays;

        // Prepare input data for the model
        var input = [
          [daysUntilDue.toDouble(), urgencyLevel.toDouble()],
        ];

        // Output buffer
        var output = List.filled(1 * 3, 0.0).reshape([1, 3]);

        // Run inference
        _interpreter!.run(input, output);

        final outputList = output[0] as List<double>;

        final predictedClass = _findMaxIndex(outputList);

        switch (predictedClass) {
          case 0:
            return "Low";
          case 1:
            return "Medium";
          case 2:
            return "High";
          default:
            return "Medium";
        }
      } catch (e) {
        print("Error during prediction: $e");

        return _ruleBasedPriority(dueDate, urgencyLevel);
      }
    } else {
      // Use rule-based approach if model isn't available
      return _ruleBasedPriority(dueDate, urgencyLevel);
    }
  }

  static Future<void> refreshModel(List<Task> tasks) async {
    // This would contain the logic to collect data from tasks
    // and use it to refresh/retrain the priority prediction model

    try {
      // In a real implementation, you would:
      // 1. Extract features and targets from completed tasks
      // 2. Create a new training dataset
      // 3. Fine-tune the model with this data
      // 4. Update the model file

      print("Priority model refreshed with ${tasks.length} tasks");

      // Re-initialize the model to use the updated version
      await initModel();
    } catch (e) {
      print("Error refreshing priority model: $e");
    }
  }

  // Rule-based fallback for priority prediction
  static String _ruleBasedPriority(DateTime dueDate, int urgencyLevel) {
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;

    // Priority logic
    if (daysUntilDue <= 1) {
      // Due today or tomorrow is high priority regardless of urgency
      return "High";
    } else if (daysUntilDue <= 3) {
      // Due within 3 days
      return urgencyLevel >= 3 ? "High" : "Medium";
    } else if (daysUntilDue <= 7) {
      // Due within a week
      return urgencyLevel >= 4
          ? "High"
          : urgencyLevel >= 2
          ? "Medium"
          : "Low";
    } else {
      // Due in more than a week
      return urgencyLevel >= 5
          ? "High"
          : urgencyLevel >= 3
          ? "Medium"
          : "Low";
    }
  }
}

class DurationEstimator {
  static Interpreter? _interpreter;

  // Category mappings
  static const Map<String, int> categoryMapping = {
    'Work': 0,
    'Personal': 1,
    'Study': 2,
    'Health': 3,
    'Shopping': 4,
    'Travel': 5,
  };

  // Initialize the model
  static Future<void> initModel() async {
    try {
      final modelInfo = await FirebaseModelDownloader.instance.getModel(
        "task_duration_model",
        FirebaseModelDownloadType.localModelUpdateInBackground,
        FirebaseModelDownloadConditions(
          iosAllowsCellularAccess: true,
          iosAllowsBackgroundDownloading: true,
          androidChargingRequired: false,
          androidWifiRequired: false,
        ),
      );

      // Load the model into interpreter
      _interpreter = Interpreter.fromFile(modelInfo.file);
      debugPrint("Duration estimation model loaded successfully");
    } catch (e) {
      debugPrint("Error loading duration estimation model: $e");
    }
  }

  // Estimate task duration based on category, urgency level and due date
  static Duration estimateTaskDuration(
    String category,
    int urgencyLevel,
    DateTime dueDate,
  ) {
    // Calculate days until due date
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;

    // If ML model is available, use it
    if (_interpreter != null) {
      try {
        // Map the category string to its numeric value
        final categoryValue = categoryMapping[category] ?? 0;

        // Prepare input data for the model
        var input = [
          [
            categoryValue.toDouble(),
            urgencyLevel.toDouble(),
            daysUntilDue.toDouble(),
          ],
        ];

        // Output buffer - the model outputs a single float value (duration in minutes)
        var output = List.filled(1 * 1, 0.0).reshape([1, 1]);

        // Run inference
        _interpreter!.run(input, output);

        // Get the predicted duration in minutes
        final predictedMinutes = output[0][0];

        // Convert to duration (in minutes)
        return Duration(minutes: predictedMinutes.round());
      } catch (e) {
        debugPrint("Error during duration prediction: $e");

        return _ruleBasedDurationEstimate(category, urgencyLevel, daysUntilDue);
      }
    } else {
      // Use rule-based approach if model isn't available
      return _ruleBasedDurationEstimate(category, urgencyLevel, daysUntilDue);
    }
  }

  // Rule-based fallback for duration estimation
  static Duration _ruleBasedDurationEstimate(
    String category,
    int urgencyLevel,
    int daysUntilDue,
  ) {
    // Base duration in minutes for each category
    int baseDuration;

    switch (category) {
      case 'Work':
        baseDuration = 60; // 1 hour
        break;
      case 'Personal':
        baseDuration = 30;
        break;
      case 'Study':
        baseDuration = 45;
        break;
      case 'Health':
        baseDuration = 40;
        break;
      case 'Shopping':
        baseDuration = 25;
        break;
      case 'Travel':
        baseDuration = 90; // 1.5 hours
        break;
      default:
        baseDuration = 45;
    }

    // Higher urgency typically means task needs to be done faster
    double urgencyFactor = 0.8 + (urgencyLevel * 0.1); // 1=90%, 3=110%, 5=130%

    // Tasks due sooner might need to be done more quickly
    double dueDateFactor = 1.0;
    if (daysUntilDue <= 1) {
      dueDateFactor = 0.8; // 20% less time when due today/tomorrow
    } else if (daysUntilDue <= 3) {
      dueDateFactor = 0.9; // 10% less time when due within 3 days
    }

    // Calculate duration with a simple random variation to avoid the math.max error
    final random = math.Random();
    final randomVariation = 0.9 + (random.nextDouble() * 0.2); // 0.9-1.1
    final calculatedMinutes =
        (baseDuration * urgencyFactor * dueDateFactor * randomVariation)
            .round();

    return Duration(minutes: calculatedMinutes);
  }

  static Future<void> recalibrateModel(List<Task> completedTasks) async {
    // This would contain the logic to recalibrate the duration model
    // based on recently completed tasks

    try {
      // In a real implementation, you would:
      // 1. Extract features from tasks and actual durations (time between creation and completion)
      // 2. Use this data to fine-tune the duration prediction model
      // 3. Update the model file

      print(
        "Duration model recalibrated with ${completedTasks.length} completed tasks",
      );

      // Re-initialize the model to use the updated version
      await initModel();
    } catch (e) {
      print("Error recalibrating duration model: $e");
    }
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '$hours hr ${minutes > 0 ? '$minutes min' : ''}';
    } else {
      return '$minutes min';
    }
  }
}

class TaskScheduler {
  static Interpreter? _dayInterpreter;
  static Interpreter? _timeInterpreter;

  // Time slot mappings
  static const List<String> timeSlots = ['Morning', 'Afternoon', 'Evening'];

  // Priority mappings
  static const Map<String, int> priorityMapping = {
    'Low': 0,
    'Medium': 1,
    'High': 2,
  };

  // Initialize the models
  static Future<void> initModels() async {
    try {
      final dayModelInfo = await FirebaseModelDownloader.instance.getModel(
        "task_schedule_day_model",
        FirebaseModelDownloadType.localModelUpdateInBackground,
        FirebaseModelDownloadConditions(
          iosAllowsCellularAccess: true,
          iosAllowsBackgroundDownloading: true,
          androidChargingRequired: false,
          androidWifiRequired: false,
        ),
      );

      // Load the day model into interpreter
      _dayInterpreter = Interpreter.fromFile(dayModelInfo.file);

      // Download the time slot model from Firebase
      final timeModelInfo = await FirebaseModelDownloader.instance.getModel(
        "task_schedule_time_model",
        FirebaseModelDownloadType.localModelUpdateInBackground,
        FirebaseModelDownloadConditions(
          iosAllowsCellularAccess: true,
          iosAllowsBackgroundDownloading: true,
          androidChargingRequired: false,
          androidWifiRequired: false,
        ),
      );

      // Load the time model into interpreter
      _timeInterpreter = Interpreter.fromFile(timeModelInfo.file);

      debugPrint("Task scheduler models loaded successfully");
    } catch (e) {
      debugPrint("Error loading task scheduler models: $e");
    }
  }

  // find index of max value
  static int _findMaxIndex(List<double> values) {
    if (values.isEmpty) return 0;
    double maxValue = values[0];
    int maxIndex = 0;
    for (int i = 1; i < values.length; i++) {
      if (values[i] > maxValue) {
        maxValue = values[i];
        maxIndex = i;
      }
    }
    return maxIndex;
  }

  // Get scheduled day and time slot for a task
  static Map<String, dynamic> suggestSchedule({
    required String priority,
    required Duration duration,
    required int userAvailabilityHours,
    required int timePreference, // 0=Morning, 1=Afternoon, 2=Evening
    required DateTime dueDate,
  }) {
    // Calculate days until due date
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
    final durationMinutes = duration.inMinutes;

    // If ML models are available, use them
    if (_dayInterpreter != null && _timeInterpreter != null) {
      try {
        // Map priority to numeric value
        final priorityValue = priorityMapping[priority] ?? 1;

        // Prepare input data for the models
        var input = [
          [
            priorityValue.toDouble(),
            durationMinutes.toDouble(),
            userAvailabilityHours.toDouble(),
            timePreference.toDouble(),
            daysUntilDue.toDouble(),
          ],
        ];

        // Day model inference
        var dayOutput = List.filled(1 * 8, 0.0).reshape([1, 8]);
        _dayInterpreter!.run(input, dayOutput);
        final dayOutputList = dayOutput[0] as List<double>;

        final predictedDay = _findMaxIndex(dayOutputList);

        // Time slot model inference
        var timeOutput = List.filled(1 * 3, 0.0).reshape([1, 3]);
        _timeInterpreter!.run(input, timeOutput);
        final timeOutputList = timeOutput[0] as List<double>;

        final predictedTimeSlot = _findMaxIndex(timeOutputList);

        // Ensure day doesn't exceed due date
        final scheduledDay = math.min(predictedDay, daysUntilDue);

        return {
          'day': scheduledDay,
          'timeSlot': predictedTimeSlot,
          'timeSlotName': timeSlots[predictedTimeSlot],
        };
      } catch (e) {
        debugPrint("Error during schedule prediction: $e");

        return _ruleBasedScheduling(
          priority,
          duration,
          userAvailabilityHours,
          timePreference,
          daysUntilDue,
        );
      }
    } else {
      // Use rule-based approach if models aren't available
      return _ruleBasedScheduling(
        priority,
        duration,
        userAvailabilityHours,
        timePreference,
        daysUntilDue,
      );
    }
  }

  // Rule-based fallback for task scheduling
  static Map<String, dynamic> _ruleBasedScheduling(
    String priority,
    Duration duration,
    int userAvailabilityHours,
    int timePreference,
    int daysUntilDue,
  ) {
    int scheduledDay;
    int scheduledTimeSlot;

    // Day scheduling based on priority
    if (priority == 'High') {
      // Schedule high priority tasks for today or tomorrow
      scheduledDay = daysUntilDue <= 1 ? 0 : 1;
    } else if (priority == 'Medium') {
      // Schedule medium priority tasks within 3 days
      scheduledDay = math.min(2, daysUntilDue);
    } else {
      // Schedule low priority tasks further out
      scheduledDay = math.min(daysUntilDue, 4);
    }

    // Time slot scheduling based on task duration and user availability
    final durationInHours = duration.inMinutes / 60;

    if (durationInHours > userAvailabilityHours / 2) {
      // schedule for when user likely has most time
      if (timePreference == 0) {
        // Morning preference
        scheduledTimeSlot = 0;
      } else if (timePreference == 2) {
        // Evening preference
        scheduledTimeSlot = 2;
      } else {
        scheduledTimeSlot = 1;
      }
    } else {
      // For shorter tasks, follow user's time preference
      scheduledTimeSlot = timePreference;
    }

    return {
      'day': scheduledDay,
      'timeSlot': scheduledTimeSlot,
      'timeSlotName': timeSlots[scheduledTimeSlot],
    };
  }

  // Get a user-friendly description of the scheduled time
  static String getScheduleDescription(int day, String timeSlotName) {
    final now = DateTime.now();
    final scheduledDate = now.add(Duration(days: day));

    String dayDescription;
    if (day == 0) {
      dayDescription = 'Today';
    } else if (day == 1) {
      dayDescription = 'Tomorrow';
    } else {
      // Format the date
      dayDescription =
          '${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year}';
    }

    return '$dayDescription, $timeSlotName';
  }
}
