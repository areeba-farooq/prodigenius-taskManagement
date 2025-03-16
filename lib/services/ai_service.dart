// Priority predictor using Firebase ML Kit
import 'dart:math' as math;

import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class PriorityPredictor {
  static Interpreter? _interpreter;

  // Initialize the model
  static Future<void> initModel() async {
    try {
      // For this example, we're using a simple on-device model
      // In a real app, you'd download a custom TFLite model from Firebase
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
      // Fallback to rule-based prediction if model fails to load
    }
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

        // Get the predicted class (0 = Low, 1 = Medium, 2 = High)
        final predictedClass = output[0].indexOf(output[0].reduce(math.max));

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
        // Fall back to rule-based prediction
        return _ruleBasedPriority(dueDate, urgencyLevel);
      }
    } else {
      // Use rule-based approach if model isn't available
      return _ruleBasedPriority(dueDate, urgencyLevel);
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

