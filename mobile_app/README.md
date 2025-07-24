
# MediLink Mobile App

This is the official Flutter mobile application for **MediLink**, designed specifically for doctors. It allows doctors to securely log in, create prescriptions, and manage patient medication histories within a secure digital health ecosystem.

## 📱 Features

- 🔐 Secure login with fingerprint or email/password.
- ➕ Add new prescriptions with patient info and medicine details.
- 🧾 View, edit, or delete previous prescriptions.
- 📦 Sync prescriptions to the central Firestore database.
- 👨‍⚕️ Each doctor only sees prescriptions they've created.
- 🌐 Built with Flutter and Firebase.

## 📂 Folder Structure

```
mobile_app/
├── android/              # Android platform-specific code
├── ios/                  # iOS platform-specific code
├── lib/                  # Main Flutter code (UI, logic)
├── assets/               # Fonts, images, etc.
├── ids/                  # Captured doctor syndicate ID images
├── test/                 # Unit and widget tests
├── web/                  # Web support (if any)
├── pubspec.yaml          # Dependencies
└── README.md             # This file
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK installed
- Firebase project setup
- Android Studio / VS Code

### Installation

1. Clone the full MediLink repo and navigate to the mobile directory:

```bash
git clone https://github.com/markamgad1234/MediLink-Graduation-Project.git
cd MediLink-Graduation-Project/mobile_app
```

2. Install dependencies:

```bash
flutter pub get
```

3. Run the app:

```bash
flutter run
```

## 🔐 Security Notes

- Do NOT upload `google-services.json` or any secrets in this repo.
- All sensitive keys are added to `.gitignore`.
- Always rotate API keys if accidentally committed.

## 📜 License

This project is licensed under the MIT License. See the main LICENSE file in the root project directory.

