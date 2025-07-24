# MediLink-Graduation-Project

🎓 Final year graduation project for the Faculty of Computer Science and Artificial Intelligence – Pharos University in Alexandria.  
💊 MediLink is a smart e-prescription system that prevents medication misuse and connects **doctors**, **pharmacists**, and **patients** securely.

---

## 🗂️ Folder Structure

```text
MediLink-Graduation-Project/
├── mobile_app/          # Flutter mobile app for doctors
├── web_dashboard/       # Flutter web dashboard for pharmacists
├── survey/              # Fuzzy logic + survey API for addiction risk evaluation
├── hl7/                 # HL7-compatible script for data exchange
├── LICENSE
├── README.md            # This file
└── .gitignore
```

---

## 📱 mobile_app

- A full-featured **Flutter mobile app** built for **doctors**.
- Doctors can register, log in, and manage prescriptions.
- Fingerprint login, secure prescription entry, patient linkage via National ID.

More details inside: [`mobile_app/README.md`](./mobile_app/README.md)

---

## 💻 web_dashboard

- **Flutter web app** designed for **pharmacists**.
- Search prescriptions by patient National ID, validate OTP, and mark as dispensed.
- Dashboards to monitor dispensed meds and visit history.

More details inside: [`web_dashboard/README.md`](./web_dashboard/README.md)

---

## 🧠 survey

- Python backend to evaluate patient addiction risk using fuzzy logic.
- Accepts responses from doctors’ mobile app.
- Integrates with Firestore to store evaluation results.

More details: [`survey/README.md`](./survey/README.md)

---

## 🧾 hl7

- Lightweight Python-based HL7 message simulator.
- Mimics communication with external hospital systems.
- Sends patient visit data and medication info using HL7 v2 format.

More details: [`hl7/README.md`](./hl7/README.md)

---

## 🔒 Security Notice

GitHub automatically scans for secrets like API keys. If you're working with Firebase or external APIs:

- NEVER push `google-services.json` or `.env` files publicly.
- Always add sensitive files to `.gitignore`.
- Rotate and delete any leaked keys immediately.

---

## 📜 License

This project is licensed under the [MIT License](./LICENSE).

---

## 👥 Team Members

- Mark Amgad George
- Joycie Gerges
- Marwan Mahmoud
- Samir Saeed
- Mohamed El Sayed Ayoub
- Abdelghany Mohamed

---

## 📬 Contact

For inquiries or demo requests, contact: `markamgad18@gmail.com`
