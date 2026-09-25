# ⏳ Countdown & Widget

### A simple countdown app with Android home screen widgets

**Countdown & Widget** is a Flutter-based Android application designed to help users track important events, deadlines, goals, and special dates.

The app combines a simple countdown interface with **native Android home screen widgets**, allowing users to view upcoming events directly from their device without opening the application.

<p align="center">
  <a href="https://play.google.com/store/apps/details?id=com.aashigupta_countdown&pcampaignid=web_share">
    <img src="https://img.shields.io/badge/Google%20Play-Download%20App-brightgreen?style=for-the-badge&logo=google-play" alt="Download on Google Play">
  </a>
</p>

---

## 📱 Download

The application is available on the Google Play Store.

👉 **[Download Countdown & Widget](https://play.google.com/store/apps/details?id=com.aashigupta_countdown&pcampaignid=web_share)**

---

## ✨ Features

* ⏳ Create countdowns for important events
* 📅 Track deadlines and goal dates
* 🕐 View remaining days and time
* ✏️ Edit existing countdowns
* 🗑️ Delete countdowns
* 🏠 Android home screen countdown widget
* 📌 Dedicated deadline widget
* 🔔 Local notifications and reminders
* 💾 Persistent local data storage
* 🔄 Countdown data persists across app sessions
* 📱 Native Android widget integration

---



### App Interface

<p align="center">
  <img src="WhatsApp Image 2026-08-26 at 1.58.41 PM.jpeg" width="220">
  <img src="WhatsApp Image 2026-08-26 at 1.58.41 PM (1).jpeg" width="220">
  <img src="WhatsApp Image 2026-08-26 at 1.58.41 PM (2).jpeg" width="220">
</p>

### Android Widgets

<p align="center">
  <img src="WhatsApp Image 2026-08-26 at 1.58.42 PM (1).jpeg" width="250">
  <img src="WhatsApp Image 2026-08-26 at 1.58.42 PM.jpeg" width="250">
</p>



---

## 🏗️ Application Architecture

The application combines **Flutter/Dart** for the main application experience with **native Kotlin** components for Android home screen widgets.

```text
                    ┌──────────────────────┐
                    │      Flutter App     │
                    │       Dart UI        │
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │   Countdown Logic    │
                    │   Event Management   │
                    └──────────┬───────────┘
                               │
                ┌──────────────┼──────────────┐
                ▼              ▼              ▼
        ┌──────────────┐ ┌─────────────┐ ┌──────────────┐
        │ SharedPrefs  │ │ Notifications│ │   Timezone   │
        │ Local Storage│ │   Scheduler  │ │   Handling   │
        └──────────────┘ └─────────────┘ └──────────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │ Flutter ↔ Android    │
                    │ Native Integration   │
                    └──────────┬───────────┘
                               │
                    ┌──────────┴───────────┐
                    ▼                      ▼
            ┌───────────────┐      ┌────────────────┐
            │ Countdown     │      │ Deadline       │
            │ Widget        │      │ Widget         │
            │ Kotlin       │      │ Kotlin         │
            └───────────────┘      └────────────────┘
```

---

## 🔄 How It Works

### 1. Create an Event

The user creates a countdown by entering an event name and target date/time.

```text
Event Name + Target Date
          ↓
     Save Countdown
```

### 2. Store Countdown

Countdown information is persisted locally using `SharedPreferences`.

```text
Countdown Data
      ↓
SharedPreferences
      ↓
Persistent Local Storage
```

### 3. Calculate Remaining Time

The application calculates the remaining time between the current time and the target date.

```text
Target Date
     -
Current Time
     ↓
Remaining Days / Time
```

### 4. Schedule Notifications

Local notifications can remind users about upcoming events and deadlines.

```text
Countdown
    ↓
Notification Scheduler
    ↓
Local Reminder
```

### 5. Update Android Widgets

The countdown information can be displayed directly on the Android home screen through native Kotlin widgets.

```text
Flutter App
     ↓
Widget Data
     ↓
Android Native Layer
     ↓
Home Screen Widget
```

---

## 🛠️ Tech Stack

### Frontend / Application

* **Flutter**
* **Dart**

### Android Native

* **Kotlin**
* Android App Widgets

### Local Storage

* **SharedPreferences**

### Notifications

* **flutter_local_notifications**
* **timezone**

### Widget Integration

* **home_widget**

### Development Tools

* Android Studio
* VS Code
* Flutter SDK
* Dart SDK

---

## 📦 Packages

| Package                       | Purpose                                           |
| ----------------------------- | ------------------------------------------------- |
| `shared_preferences`          | Persistent local countdown storage                |
| `flutter_local_notifications` | Local notifications and reminders                 |
| `home_widget`                 | Communication between Flutter and Android widgets |
| `timezone`                    | Timezone-aware scheduling                         |
| `flutter_launcher_icons`      | Application icon generation                       |

---

## 📂 Project Structure

```text
Count-Down-Widget-/
│
├── lib/
│   └── main.dart
│
├── android/
│   └── Native Android implementation
│       ├── Countdown Widget
│       └── Deadline Widget
│
├── assets/
│   └── app_icon.png
│
├── pubspec.yaml
├── pubspec.lock
└── README.md
```

---

## 🤖 Android Widget Architecture

One of the key parts of this project is the integration between Flutter and native Android.

The application contains two native widgets:

### ⏳ Countdown Widget

Displays the remaining time for a selected countdown directly on the Android home screen.

### 📅 Deadline Widget

Provides a dedicated widget for important deadlines and target dates.

```text
Flutter Application
        │
        │ Widget Data
        ▼
 ┌─────────────────┐
 │ Android Native  │
 │     Kotlin      │
 └────────┬────────┘
          │
     ┌────┴─────┐
     ▼          ▼
 Countdown    Deadline
  Widget       Widget
```

This allows the project to combine the flexibility of Flutter with platform-specific Android functionality.

---

## 🚀 Getting Started

### Prerequisites

Make sure you have the following installed:

* Flutter SDK
* Dart SDK
* Android Studio or VS Code
* Android SDK
* Android device or emulator

### 1. Clone the Repository

```bash
git clone https://github.com/A1shi/Count-Down-Widget-.git
```

### 2. Navigate to the Project

```bash
cd Count-Down-Widget-
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Run the Application

```bash
flutter run
```

---

## 🔐 Permissions

Depending on the Android version and enabled functionality, the application may use permissions related to:

* Notifications
* Exact alarm scheduling
* Device boot events

These permissions support scheduled reminders and maintaining countdown-related functionality.

---

## 🎯 Key Learning Outcomes

This project provided hands-on experience with:

* Flutter application development
* Dart programming
* Android native development with Kotlin
* Flutter ↔ Android platform integration
* Android App Widgets
* Local data persistence
* Notification scheduling
* Timezone-aware date/time handling
* Mobile application lifecycle
* Publishing an application to Google Play

---

## 🔮 Future Improvements

Potential future enhancements include:

* 📊 Productivity and performance insights
* 📈 Goal progress tracking
* 📅 Goal completion statistics
* 🔔 More flexible notification controls
* 🎨 Additional countdown themes
* 🖼️ More widget layouts and customization
* 🌈 Custom colors and backgrounds
* 📱 Additional widget sizes
* ☁️ Optional cloud synchronization

---

## 📱 Published Application

**Countdown & Widget** is available on Google Play.

👉 **[View the application on Google Play](https://play.google.com/store/apps/details?id=com.aashigupta_countdown&pcampaignid=web_share)**

---

## 👩‍💻 Author

**Aashi Gupta**

Software Developer | GenAI & Data Engineering Enthusiast

Interested in building applications using:

`Python` · `Flutter` · `Kotlin` · `FastAPI` · `AI/LLMs` · `Data Engineering`

---

## 📄 License

This project was created for educational and personal development purposes.
