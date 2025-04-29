import 'dart:math' as math;

import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/material.dart';

class DurationEstimator {
  static Interpreter? _interpreter;

  // Category mappings (must match the model training categories)
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
      // Download the custom TFLite model from Firebase
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
      // We'll fall back to rule-based estimation if model fails to load
    }
  }

  // Estimate task duration based on category and complexity
  static Duration estimateTaskDuration(String category, int complexityLevel) {
    // If ML model is available, use it
    if (_interpreter != null) {
      try {
        // Map the category string to its numeric value
        final categoryValue = categoryMapping[category] ?? 0;

        // Prepare input data for the model
        var input = [
          [categoryValue.toDouble(), complexityLevel.toDouble()],
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
        // Fall back to rule-based estimation
        return _ruleBasedDurationEstimate(category, complexityLevel);
      }
    } else {
      // Use rule-based approach if model isn't available
      return _ruleBasedDurationEstimate(category, complexityLevel);
    }
  }

  // Rule-based fallback for duration estimation
  static Duration _ruleBasedDurationEstimate(
    String category,
    int complexityLevel,
  ) {
    // Base duration in minutes for each category
    int baseDuration;

    switch (category) {
      case 'Work':
        baseDuration = 60; // 1 hour
        break;
      case 'Personal':
        baseDuration = 30; // 30 minutes
        break;
      case 'Study':
        baseDuration = 45; // 45 minutes
        break;
      case 'Health':
        baseDuration = 40; // 40 minutes
        break;
      case 'Shopping':
        baseDuration = 25; // 25 minutes
        break;
      case 'Travel':
        baseDuration = 90; // 1.5 hours
        break;
      default:
        baseDuration = 45; // Default to 45 minutes
    }

    // Adjust by complexity level (1-5)
    // Each level adds/subtracts percentage from base
    double complexityFactor =
        0.7 + (complexityLevel * 0.15); // 1=85%, 3=115%, 5=145%

    // Calculate duration with small random variation
    final randomVariation = 0.9 + (math.Random().nextDouble() * 0.2); // 0.9-1.1
    final calculatedMinutes =
        (baseDuration * complexityFactor * randomVariation).round();

    return Duration(minutes: calculatedMinutes);
  }

  // Format a duration to a user-friendly string
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
