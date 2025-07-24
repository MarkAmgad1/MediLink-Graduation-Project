# 🧠 MediLink – Survey API

This folder contains the backend scripts for the **patient behavior and mental health survey** component of the MediLink system.

---

## 📌 Description

These scripts are responsible for:
- Receiving patient answers from a Google Form / App.
- Calculating a consultation score using fuzzy logic.
- Writing the result to Firebase Firestore under `survey_results`.
- Supporting medicine verification in coordination with the pharmacy system.

---

## 🗂️ Files

| File | Purpose |
|------|---------|
| `survey_api.py` | Main API script for receiving and evaluating survey responses. |
| `medicines.py` | Helper functions for retrieving patient prescriptions from Firestore. |

---

## 🔐 Firebase Credentials

This project uses Firebase Admin SDK credentials to write securely to Firestore. **Do not upload `.json` service account files to GitHub.** Keep them private and secure using `.gitignore`.

---

## ⚙️ Deployment

You can run the API using Flask locally:

```bash
pip install flask firebase-admin
python survey_api.py
```

Then test it via:

```
http://localhost:5000/verify_survey
```

---

## 📬 Sample Request Body

```json
{
  "nationalId": "12345678901234",
  "answers": [4, 3, 5, 2, 1, 5, 2, 4, 3, 5]
}
```

---

## 📡 Firebase Firestore

Survey scores are stored under the following collection:

```
survey_results / {nationalId} / score
```

---

## 📌 Note
This is an internal research component of the MediLink graduation project submitted to Pharos University, Faculty of Computer Science and Artificial Intelligence.
