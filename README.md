# 🤖 Prodi Genius AI - Powered Task Management App (Task Genius)

Welcome to **Task Genius**, your AI-powered productivity partner! 🚀  
Built using **Flutter**, this mobile application helps users **prioritize**, **schedule**, and **track tasks** more efficiently using **on-device machine learning** — all without costly cloud infrastructure or complex custom AI models.

---

## 📱 Project Domain / Category

**Mobile Application + Machine Learning**

---

## 🧠 Abstract / Introduction

**Task Genius** is a streamlined, AI-powered task management app designed for users who want smart, efficient task organization on the go. Built with **Flutter**, this mobile app integrates **Firebase ML Kit** and **TensorFlow Lite** to provide basic AI-driven features like task prioritization, duration estimation, and smart scheduling. Best of all, it uses **pre-trained models** and **on-device AI**, making it lightweight, fast, and cloud-cost free!

---

## ✅ Functional Requirements

### 1. 📝 Task Input and Simple Categorization
- **Manual Input:** Users can manually add tasks, assign due dates, and categorize them (e.g., work, personal, study).
- **Priority Input:** Tasks can be prioritized manually or suggested by AI based on urgency and deadlines.

### 2. 🔺 Basic AI-Powered Task Prioritization
- **Library Used:** Firebase ML Kit (On-Device)
- **How it Works:** AI evaluates urgency and importance using logic based on due dates to suggest priority levels.

### 3. ⏳ Simple Task Duration Estimation
- **Library Used:** TensorFlow Lite (Pre-trained Model)
- **How it Works:** Estimates how long a task might take based on category (e.g., work > personal tasks).

### 4. 📆 AI-Driven Task Scheduling
- **Library Used:** Firebase ML Kit (On-Device)
- **How it Works:** Schedules tasks by analyzing urgency, importance, and user availability — e.g., do quick or high-priority tasks earlier.

### 5. 🔔 Smart Reminders & Notifications
- **Library Used:** Flutter Local Notifications
- **How it Works:** Simple rules trigger reminders for tasks nearing deadlines or with high priority.

### 6. 📊 Basic Productivity Tracking
- **Library Used:** Firebase ML Kit (On-Device)
- **How it Works:** Tracks completion rates and gives AI-generated insights like:
  > “You're most productive on Wednesdays!”

### 7. 📈 Progress Visualization & Task Dashboard
- **Library Used:** Flutter Charts
- **How it Works:** Presents visual dashboards (tasks completed, pending, etc.) with no AI involved.

### 8. 🔍 Search and Filter Functionality
- Easily find and filter tasks by date, priority, or category.

### 9. 🌗 Theme Toggle (Light & Dark Mode)
- Customize your app experience with light or dark themes.

---

## 🧰 Tech Stack

- **Flutter** – Cross-platform UI framework for Android & iOS.
- **Firebase ML Kit** – On-device AI for task prioritization, scheduling, and insights.
- **TensorFlow Lite** – Lightweight pre-trained model for task duration prediction.
- **tflite_flutter Plugin** – TensorFlow Lite integration in Flutter.
- **Flutter Local Notifications** – Local alerts for reminders.
- **Python** – For AI model creation (for future model customizations).

---

## 🛠️ Tools Used

| Tool | Purpose |
|------|---------|
| [Flutter SDK](https://flutter.dev/docs/get-started/install) | App Development |
| [Android Studio](https://developer.android.com/studio) / [VS Code](https://code.visualstudio.com/) | IDEs |
| [Firebase ML Kit](https://firebase.google.com/products/ml-kit) | On-device AI |
| [TensorFlow Lite Model Maker](https://www.tensorflow.org/lite/guide/model_maker) | AI Model Customization |
| [tflite_flutter Plugin](https://pub.dev/packages/tflite_flutter) | TensorFlow Lite Integration |
| [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications) | Local Notifications |
| [Dart DevTools](https://dart.dev/tools/dart-devtools) | Debugging & Performance |
| [Git](https://git-scm.com/) | Version Control |
| [Postman](https://www.postman.com/downloads/) | API Testing (Optional) |

---

## 🚀 Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/areeba-farooq/prodigenius-taskManagement.git
   ```
2. **Navigate to the project directory**
   ```bash
   cd prodigenius-taskManagement
   ```
3. **Install dependencies**
   ```bash
   flutter pub get
   ```
4. **Run the app**
   ```bash
   flutter run
   ```

> Make sure to configure Firebase and include the necessary model files in your assets.

---

## 📌 Future Enhancements

- Integration of more advanced custom AI models
- Cloud sync & multi-device support
- Voice-based task creation
- Habit tracking features

---

## 📫 Contact

For any inquiries or contributions, feel free to reach out!

---

🧠 Built with AI.  
📱 Powered by Flutter.  
🎯 Designed for productivity.

---
