import numpy as np
import tensorflow as tf
from tensorflow import keras
from sklearn.model_selection import train_test_split
import pandas as pd
import os

# Synthetic training data
# - days_until_due: 0-30 days
# - urgency_level: 1-5 scale
# - priority: 0=Low, 1=Medium, 2=High

def generate_synthetic_data(n_samples=1000):
    # Random days until due (0-30 days)
    days_until_due = np.random.randint(0, 31, n_samples)
    
    # Random urgency levels (1-5)
    urgency_level = np.random.randint(1, 6, n_samples)
    
    # Priority labels based on rules
    priority = np.zeros(n_samples, dtype=np.int32)
    
    for i in range(n_samples):
        days = days_until_due[i]
        urgency = urgency_level[i]
        
        if days <= 1:
            priority[i] = 2 
        elif days <= 3:
            priority[i] = 2 if urgency >= 3 else 1  # High or Medium
        elif days <= 7:
            if urgency >= 4:
                priority[i] = 2  # High
            elif urgency >= 2:
                priority[i] = 1  # Medium
            else:
                priority[i] = 0  # Low
        else:
            if urgency >= 5:
                priority[i] = 2  # High
            elif urgency >= 3:
                priority[i] = 1  # Medium
            else:
                priority[i] = 0  # Low
    
    # Add some random noise (10% of data points get random priorities)
    random_indices = np.random.choice(n_samples, int(n_samples * 0.1), replace=False)
    priority[random_indices] = np.random.randint(0, 3, len(random_indices))
    
    return days_until_due, urgency_level, priority

# Generate data
days, urgency, priority = generate_synthetic_data(5000)

# Combine features into a single array
X = np.column_stack((days, urgency))
y = priority

# Split data
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# 1. Create and train the model
model = keras.Sequential([
    keras.layers.Input(shape=(2,)),  # 2 inputs: days_until_due, urgency_level
    keras.layers.Dense(16, activation='relu'),
    keras.layers.Dense(8, activation='relu'),
    keras.layers.Dense(3, activation='softmax')  # 3 outputs: Low, Medium, High
])

model.compile(
    optimizer='adam',
    loss='sparse_categorical_crossentropy',
    metrics=['accuracy']
)

# Train the model
model.fit(
    X_train, y_train,
    epochs=20,
    batch_size=32,
    validation_data=(X_test, y_test)
)

# Evaluate the model
test_loss, test_acc = model.evaluate(X_test, y_test)
print(f"Test accuracy: {test_acc:.4f}")

# 3. Convert to TensorFlow Lite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

# Save the model 
with open('task_priority_model.tflite', 'wb') as f:
    f.write(tflite_model)

print(f"Model saved to 'task_priority_model.tflite'")

# 4. Test the TFLite model
# Load the TFLite model and perform inference
interpreter = tf.lite.Interpreter(model_content=tflite_model)
interpreter.allocate_tensors()

# Get input and output tensors
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# Test with a few examples
test_examples = [
    [0, 3],   # Due today, medium urgency -> High
    [10, 2],  # Due in 10 days, low urgency -> Low
    [5, 4],   # Due in 5 days, high urgency -> Medium/High
]

print("\nTesting TFLite model with examples:")
for i, example in enumerate(test_examples):
    # Prepare input
    input_data = np.array([example], dtype=np.float32)
    interpreter.set_tensor(input_details[0]['index'], input_data)
    
    # Run inference
    interpreter.invoke()
    
    # Get output
    output_data = interpreter.get_tensor(output_details[0]['index'])
    predicted_class = np.argmax(output_data[0])
    
    priority_names = ["Low", "Medium", "High"]
    confidence = output_data[0][predicted_class] * 100
    
    print(f"Example {i+1}: Days until due = {example[0]}, Urgency = {example[1]}")
    print(f"   Predicted priority: {priority_names[predicted_class]} (confidence: {confidence:.2f}%)")