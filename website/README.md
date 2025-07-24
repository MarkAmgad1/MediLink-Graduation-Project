# 💻 MediLink Web Dashboard

This is the **Flutter Web Dashboard** for **MediLink**, designed for **pharmacists** to securely access and process medical prescriptions.

## 🌐 Live Website
Access the dashboard here:  
🔗 [https://medilink-d69f4.web.app/](https://medilink-d69f4.web.app/)

## 📌 Purpose
This dashboard allows pharmacists to:
- Log in securely.
- View and verify prescriptions assigned to them.
- Confirm dispensation using OTP verification.
- Track medication dispensing history.

## 📁 Tech Stack
- **Flutter Web**
- **Firebase Authentication**
- **Firebase Firestore**
- **Firebase Hosting**

## 🛠️ Setup Instructions

1. Clone the repository:
   ```bash
   git clone https://github.com/markamgad1234/MediLink-Graduation-Project.git
   cd MediLink-Graduation-Project/web_dashboard
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the project locally:
   ```bash
   flutter run -d chrome
   ```

4. To deploy:
   ```bash
   flutter build web
   firebase deploy
   ```

## 🧑‍⚕️ User Role
Only **verified pharmacists** can access this dashboard.

## 🔐 Security
Sensitive credentials like API keys and Firebase config files are hidden using `.gitignore` and should never be exposed.
