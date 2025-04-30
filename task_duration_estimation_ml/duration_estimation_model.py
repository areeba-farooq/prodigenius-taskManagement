import numpy as np
import tensorflow as tf
from tensorflow import keras
from sklearn.model_selection import train_test_split
import pandas as pd
import os

# Updated synthetic training data for task duration estimation
# Features:
# - category: encoded as numeric (0=Work, 1=Personal, 2=Study, 3=Health, 4=Shopping, 5=Travel)
# - urgency_level: 1-5 scale
# - days_until_due: number of days until the task is due
# - duration_minutes: the target variable (estimated minutes to complete)

def generate_synthetic_data(n_samples=5000):
    # Random category (0-5)
    category = np.random.randint(0, 6, n_samples)
    
    # Random urgency levels (1-5)
    urgency_level = np.random.randint(1, 6, n_samples)
    
    # Random days until due (0-30 days)
    days_until_due = np.random.randint(0, 31, n_samples)
    
    # Duration in minutes based on rules
    duration_minutes = np.zeros(n_samples, dtype=np.int32)
    
    for i in range(n_samples):
        cat = category[i]
        urgency = urgency_level[i]
        days_due = days_until_due[i]
        
        # Base duration depending on category (in minutes)
        if cat == 0:  # Work
            base_duration = 60  # 1 hour base for work tasks
        elif cat == 1:  # Personal
            base_duration = 30  # 30 min base for personal tasks
        elif cat == 2:  # Study
            base_duration = 45  # 45 min base for study tasks
        elif cat == 3:  # Health
            base_duration = 40  # 40 min base for health tasks
        elif cat == 4:  # Shopping
            base_duration = 25  # 25 min base for shopping tasks
        else:  # Travel
            base_duration = 90  # 1.5 hours base for travel tasks
        
        # Adjust by urgency (1-5 scale)
        # Higher urgency typically means task needs to be done faster
        urgency_factor = 0.8 + (urgency * 0.1)  # 1=90%, 3=110%, 5=130%
        
        # Due date adjustment factor
        # Tasks due sooner might need to be done more quickly
        due_date_factor = 1.0
        if days_due <= 1:
            due_date_factor = 0.8  # 20% less time when due today/tomorrow
        elif days_due <= 3:
            due_date_factor = 0.9  # 10% less time when due within 3 days
        
        # Calculate duration
        calculated_duration = int(base_duration * urgency_factor * due_date_factor)
        
        # Add some random variation (±20%)
        variation = np.random.uniform(0.8, 1.2)
        duration_minutes[i] = int(calculated_duration * variation)
    
    # Add some outliers (5% of data)
    outlier_indices = np.random.choice(n_samples, int(n_samples * 0.05), replace=False)
    duration_minutes[outlier_indices] = np.random.randint(15, 300, len(outlier_indices))
    
    return category, urgency_level, days_until_due, duration_minutes

# Generate data
categories, urgency_levels, days_until_due, durations = generate_synthetic_data(5000)

# Combine features into a single array
X = np.column_stack((categories, urgency_levels, days_until_due))
y = durations

# Split data
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Create and train the model
model = keras.Sequential([
    keras.layers.Input(shape=(3,)),  # 3 inputs: category, urgency_level, days_until_due
    keras.layers.Dense(32, activation='relu'),
    keras.layers.Dense(16, activation='relu'),
    keras.layers.Dense(1)  # Output is a continuous value (minutes)
])

model.compile(
    optimizer='adam',
    loss='mse',  # Mean Squared Error for regression
    metrics=['mae']  # Mean Absolute Error
)

# Train the model
model.fit(
    X_train, y_train,
    epochs=25,
    batch_size=64,
    validation_data=(X_test, y_test),
    verbose=1
)

# Evaluate the model
test_loss, test_mae = model.evaluate(X_test, y_test)
print(f"Test MAE: {test_mae:.2f} minutes")

# Convert to TensorFlow Lite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

# Save the model 
with open('task_duration_model.tflite', 'wb') as f:
    f.write(tflite_model)

print(f"Model saved to 'task_duration_model.tflite'")

# Test the TFLite model
interpreter = tf.lite.Interpreter(model_content=tflite_model)
interpreter.allocate_tensors()

# Get input and output tensors
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# Test with examples
test_examples = [
    [0, 3, 5],    # Work task, medium urgency, due in 5 days
    [1, 2, 1],    # Personal task, low-medium urgency, due tomorrow
    [2, 5, 0],    # Study task, high urgency, due today
    [5, 4, 10],   # Travel task, high urgency, due in 10 days
]

print("\nTesting TFLite model with examples:")
for i, example in enumerate(test_examples):
    category_name = ["Work", "Personal", "Study", "Health", "Shopping", "Travel"][example[0]]
    
    # Prepare input
    input_data = np.array([example], dtype=np.float32)
    interpreter.set_tensor(input_details[0]['index'], input_data)
    
    # Run inference
    interpreter.invoke()
    
    # Get output
    output_data = interpreter.get_tensor(output_details[0]['index'])
    estimated_minutes = int(output_data[0][0])
    
    # Convert to hours and minutes format
    hours = estimated_minutes // 60
    minutes = estimated_minutes % 60
    
    print(f"Example {i+1}: Category = {category_name}, Urgency = {example[1]}, Days until due = {example[2]}")
    print(f"   Estimated duration: {estimated_minutes} minutes ({hours}h {minutes}m)")