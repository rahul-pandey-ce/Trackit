# TrackIt - Study Session Monitoring System 📚🚀

TrackIt is a Flutter application designed for students to track their study sessions and for viewers (such as parents or educators) to monitor their progress in real-time. Built with a robust Firebase backend, it provides a seamless experience for data-driven academic monitoring.

## ✨ Features

- **🔐 Dual Dashboard System:** Specialized interfaces for both Students and Viewers.
- **📊 Interactive Analytics:** Visual representation of study habits using `fl_chart`.
- **🔍 Student Search & Linking:** Viewers can search for students and request to monitor their progress.
- **⚡ Real-time Updates:** Powered by Firebase Realtime Database for instant data synchronization.
- **🔐 Secure Authentication:** User accounts managed via Firebase Authentication.
- **📁 Session Management:** Detailed logging of study durations, subjects, and sessions.

## 🛠️ Technology Stack

- **Frontend:** [Flutter](https://flutter.dev/) (Dart)
- **Backend:** [Firebase Authentication](https://firebase.google.com/docs/auth) & [Realtime Database](https://firebase.google.com/docs/database)
- **State Management:** Provider/Hooks (common in Flutter, but specifically standard widgets here)
- **Data Visualization:** [fl_chart](https://pub.dev/packages/fl_chart)
- **Date/Time Formatting:** [intl](https://pub.dev/packages/intl)

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>= 3.4.0)
- Android Studio / VS Code with Flutter extension
- Firebase project setup

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/trackit.git
    cd trackit
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Firebase Configuration:**
    - Place your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in their respective directories.
    - Run `flutterfire configure` if you have the FlutterFire CLI installed.

4.  **Run the application:**
    ```bash
    flutter run
    ```

## 📸 Screenshots

*(To be added - You can use screenshots of your Dashboards here)*

| Student Dashboard | Viewer Dashboard |
| :---: | :---: |
| ![Dashboard](https://via.placeholder.com/200x400?text=Student+UI) | ![Viewer](https://via.placeholder.com/200x400?text=Viewer+UI) |

## 📁 Project Structure

```text
lib/
├── models/         # Data models (StudySession, etc.)
├── screens/        # Main UI screens (Login, Student Dash, Viewer Dash)
├── services/       # Firebase & Business logic (Auth, Study Services)
├── utils/          # Constants and helper functions
└── widgets/        # Reusable UI components
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---
Developed with ❤️ by the TrackIt Team.