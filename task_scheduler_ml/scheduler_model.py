import numpy as np
import tensorflow as tf
from tensorflow import keras
from sklearn.model_selection import train_test_split
import pandas as pd
import os

# Task Scheduler AI model
# Features:
# - task_priority: 0=Low, 1=Medium, 2=High
# - task_duration_minutes: estimated minutes to complete the task
# - user_availability: hours available per day (1-12)
# - time_of_day_preference: 0=Morning, 1=Afternoon, 2=Evening
# - desired_completion_date: days until desired completion
# Output:
# - scheduled_day: days from now when the task should be scheduled (0-7)
# - scheduled_time_slot: 0=Morning, 1=Afternoon, 2=Evening

def generate_synthetic_schedule_data(n_samples=5000):
    # Task priority (0=Low, 1=Medium, 2=High)
    task_priority = np.random.randint(0, 3, n_samples)
    
    # Task duration in minutes (15-240 minutes)
    task_duration = np.random.randint(15, 241, n_samples)
    
    # User availability (hours per day, 1-12)
    user_availability = np.random.randint(1, 13, n_samples)
    
    # Time of day preference (0=Morning, 1=Afternoon, 2=Evening)
    time_preference = np.random.randint(0, 3, n_samples)
    
    # Desired completion date (days from now, 0-7)
    desired_completion = np.random.randint(0, 8, n_samples)
    
    # Generate scheduled day and time slot based on rules
    scheduled_day = np.zeros(n_samples, dtype=np.int32)
    scheduled_time_slot = np.zeros(n_samples, dtype=np.int32)
    
    for i in range(n_samples):
        priority = task_priority[i]
        duration = task_duration[i]
        availability = user_availability[i]
        preference = time_preference[i]
        completion_target = desired_completion[i]
        
        # Schedule high priority tasks sooner
        if priority == 2:  # High priority
            # Schedule for today or tomorrow
            scheduled_day[i] = min(np.random.randint(0, 2), completion_target)
        elif priority == 1:  # Medium priority
            # Schedule within 0-3 days
            scheduled_day[i] = min(np.random.randint(0, 4), completion_target)
        else:  # Low priority
            # Schedule within 0-7 days
            scheduled_day[i] = min(np.random.randint(0, 8), completion_target)
        
        # Time slot scheduling logic
        # Base on preference but adjust for availability and duration
        
        # Long tasks (>90 mins) need more available time
        if duration > 90 and availability < 4:
            # If limited availability, schedule when more time is available
            # Override preference for practical reasons
            scheduled_time_slot[i] = np.random.randint(0, 3)  # Random time slot
        else:
            # Respect preference but add some variation
            # 70% chance of preferred time slot, 30% chance of another slot
            if np.random.random() < 0.7:
                scheduled_time_slot[i] = preference
            else:
                options = [0, 1, 2]
                options.remove(preference)
                scheduled_time_slot[i] = np.random.choice(options)
    
    # Add some random noise (10% of data)
    random_indices = np.random.choice(n_samples, int(n_samples * 0.1), replace=False)
    scheduled_day[random_indices] = np.random.randint(0, 8, len(random_indices))
    scheduled_time_slot[random_indices] = np.random.randint(0, 3, len(random_indices))
    
    return task_priority, task_duration, user_availability, time_preference, desired_completion, scheduled_day, scheduled_time_slot

# Generate data
priorities, durations, availability, preferences, completion_dates, days, time_slots = generate_synthetic_schedule_data(5000)

# Combine features into a single array
X = np.column_stack((priorities, durations, availability, preferences, completion_dates))
y_day = days
y_time = time_slots

# Split data
X_train, X_test, y_day_train, y_day_test, y_time_train, y_time_test = train_test_split(
    X, y_day, y_time, test_size=0.2, random_state=42
)

# Create and train the model for scheduled day
day_model = keras.Sequential([
    keras.layers.Input(shape=(5,)),
    keras.layers.Dense(32, activation='relu'),
    keras.layers.Dense(16, activation='relu'),
    keras.layers.Dense(8, activation='softmax')  # 0-7 days
])

day_model.compile(
    optimizer='adam',
    loss='sparse_categorical_crossentropy',
    metrics=['accuracy']
)

# Train the model for scheduled day
day_model.fit(
    X_train, y_day_train,
    epochs=20,
    batch_size=64,
    validation_data=(X_test, y_day_test),
    verbose=1
)

# Create and train the model for time slot
time_model = keras.Sequential([
    keras.layers.Input(shape=(5,)),
    keras.layers.Dense(24, activation='relu'),
    keras.layers.Dense(12, activation='relu'),
    keras.layers.Dense(3, activation='softmax')  # 3 time slots
])

time_model.compile(
    optimizer='adam',
    loss='sparse_categorical_crossentropy',
    metrics=['accuracy']
)

# Train the model for time slot
time_model.fit(
    X_train, y_time_train,
    epochs=20,
    batch_size=64,
    validation_data=(X_test, y_time_test),
    verbose=1
)

# Evaluate the models
day_loss, day_acc = day_model.evaluate(X_test, y_day_test)
time_loss, time_acc = time_model.evaluate(X_test, y_time_test)

print(f"Day model accuracy: {day_acc:.4f}")
print(f"Time slot model accuracy: {time_acc:.4f}")

# Convert models to TensorFlow Lite
# Day model
day_converter = tf.lite.TFLiteConverter.from_keras_model(day_model)
day_tflite_model = day_converter.convert()

# Save the day model
with open('task_schedule_day_model.tflite', 'wb') as f:
    f.write(day_tflite_model)

# Time slot model
time_converter = tf.lite.TFLiteConverter.from_keras_model(time_model)
time_tflite_model = time_converter.convert()

# Save the time slot model
with open('task_schedule_time_model.tflite', 'wb') as f:
    f.write(time_tflite_model)

print("Models saved to 'task_schedule_day_model.tflite' and 'task_schedule_time_model.tflite'")

# Test the TFLite models
day_interpreter = tf.lite.Interpreter(model_content=day_tflite_model)
day_interpreter.allocate_tensors()

time_interpreter = tf.lite.Interpreter(model_content=time_tflite_model)
time_interpreter.allocate_tensors()

# Get input and output tensors
day_input_details = day_interpreter.get_input_details()
day_output_details = day_interpreter.get_output_details()

time_input_details = time_interpreter.get_input_details()
time_output_details = time_interpreter.get_output_details()

# Test with examples
test_examples = [
    [2, 60, 6, 0, 1],    # High priority, 1hr duration, 6hrs available, morning preference, due tomorrow
    [1, 120, 4, 1, 3],   # Medium priority, 2hr duration, 4hrs available, afternoon preference, due in 3 days
    [0, 30, 2, 2, 7],    # Low priority, 30min duration, 2hrs available, evening preference, due in a week
]

time_slot_names = ["Morning", "Afternoon", "Evening"]

print("\nTesting TFLite models with examples:")
for i, example in enumerate(test_examples):
    priority_names = ["Low", "Medium", "High"]
    
    # Testing day model
    day_input = np.array([example], dtype=np.float32)
    day_interpreter.set_tensor(day_input_details[0]['index'], day_input)
    day_interpreter.invoke()
    day_output = day_interpreter.get_tensor(day_output_details[0]['index'])
    predicted_day = np.argmax(day_output[0])
    day_confidence = day_output[0][predicted_day] * 100
    
    # Testing time model
    time_input = np.array([example], dtype=np.float32)
    time_interpreter.set_tensor(time_input_details[0]['index'], time_input)
    time_interpreter.invoke()
    time_output = time_interpreter.get_tensor(time_output_details[0]['index'])
    predicted_time = np.argmax(time_output[0])
    time_confidence = time_output[0][predicted_time] * 100
    
    print(f"Example {i+1}: Priority = {priority_names[example[0]]}, Duration = {example[1]}min, "
          f"Availability = {example[2]}hrs, Preference = {time_slot_names[example[3]]}, Due in = {example[4]} days")
    print(f"   Scheduled for: Day {predicted_day} ({day_confidence:.2f}%), "
          f"Time: {time_slot_names[predicted_time]} ({time_confidence:.2f}%)")