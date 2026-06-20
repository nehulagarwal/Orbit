# 🚀 Orbit - Flutter Chat Application

Orbit is a modern real-time chat application built with Flutter, Firebase, and Cloudinary. It supports instant messaging, image sharing, Google Authentication, user profiles, online/offline status tracking, and Firebase Cloud Messaging (FCM) notifications.

---

## ✨ Features

* 🔐 Google Sign-In Authentication
* 💬 Real-Time Messaging
* 📸 Image Sharing via Cloudinary
* 👤 User Profile Management
* 🟢 Online/Offline Status
* 🔔 Push Notifications using Firebase Cloud Messaging (FCM)
* 🔍 User Search
* ☁️ Cloud Firestore Backend
* 📱 Responsive Flutter UI

---

## 🛠️ Tech Stack

### Frontend

* Flutter
* Dart

### Backend & Services

* Firebase Authentication
* Cloud Firestore
* Firebase Cloud Messaging (FCM)
* Cloudinary

---

## 📂 Project Structure

```text
lib/
├── api/
│   ├── api.dart
│   └── notification_access_token.dart
│
├── models/
├── screens/
├── services/
│   └── cloudinary_service.dart
├── widgets/
└── main.dart
```

---

## ⚙️ Setup

### 1. Clone Repository

```bash
git clone https://github.com/nehulagarwal/Orbit.git
cd Orbit
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

Create your own Firebase project and connect it using FlutterFire:

```bash
flutterfire configure
```

This generates:

```text
lib/firebase_options.dart
```

---

### 4. Configure Push Notifications

The repository intentionally excludes:

```text
lib/api/notification_access_token.dart
```

Create this file and add your Firebase Service Account credentials.

Generate credentials from:

Firebase Console → Project Settings → Service Accounts → Generate New Private Key

⚠️ Never commit this file to GitHub.

---

### 5. Configure Cloudinary

Update:

```dart
lib/services/cloudinary_service.dart
```

with your own:

* Cloud Name
* Upload Preset

---

### 6. Run the App

```bash
flutter run
```

---

## 🔒 Important Security Notes

The following files are intentionally excluded from GitHub:

```text
lib/firebase_options.dart
lib/api/notification_access_token.dart
```

Reason:

* `firebase_options.dart` contains Firebase project configuration.
* `notification_access_token.dart` contains Firebase Service Account credentials used for FCM HTTP v1 authentication.

If you clone this project, you must generate these files yourself before running the application.

Never commit:

* Firebase Service Account Keys
* Private Keys
* API Secrets
* OAuth Credentials

---

## ☁️ Cloudinary Storage Structure

```text
orbit/
├── profile_pics/
│   └── {firebase_uid}/
└── chat_images/
    └── {conversation_id}/
```

---

## 🔔 Notification Flow

```text
User A sends message
        ↓
Message stored in Firestore
        ↓
FCM HTTP v1 API called
        ↓
Push Notification sent
        ↓
Recipient receives notification
```

---

## 🎯 Future Enhancements

* Group Chats
* Voice Messages
* Video Calling
* Message Reactions
* End-to-End Encryption
* AI Chat Assistant

---

## 👨‍💻 Developer

**Nehul Agarwal**

GitHub: https://github.com/nehulagarwal

---

## ⭐ Support

If you found this project useful, consider giving it a star.
