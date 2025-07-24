# 🏥 HL7 Message Sender (FastAPI)

This microservice is designed to generate and send **HL7 ADT_A01 messages** containing doctor information using **FastAPI** and `hl7apy`.

## 🚀 Features

- Accepts doctor data (name, phone, license, etc.) via a POST request.
- Builds a standard HL7 message (version 2.3) in ER7 format.
- Returns the HL7 message as a string in the response.
- CORS enabled for any frontend connection.

## 🧪 Example HL7 Fields
- `MSH` (Message Header)
- `PID` (Patient Identification) – used here for doctor info
- `NTE` (Notes) – includes specialization, license, workplace

## 📦 Dependencies

Make sure you have Python 3.7+ and install the following packages:

```bash
pip install fastapi hl7apy uvicorn
```

## ▶️ How to Run

```bash
uvicorn main:app --reload
```

Then send a POST request to:
```
http://127.0.0.1:8000/send-hl7
```

With a JSON body like:

```json
{
  "doctor_id": "D12345",
  "name": "Dr. Mark George",
  "phonenumber": "01012345678",
  "specialization": "Cardiology",
  "license": "LIC-6789",
  "workplace": "Alexandria Hospital"
}
```

## 🧾 Sample HL7 Output

```
MSH|^~\&|MyApp|MyFacility|HL7Receiver||20250412120000||ADT^A01|MSG00001|P|2.3
PID|||D12345||Dr. Mark George||||||||||01012345678
NTE|||Specialization: Cardiology, License: LIC-6789, Workplace: Alexandria Hospital
```

## 📂 File Structure

```
main.py         # FastAPI server with HL7 generation
README.md       # Project overview
```

## 🔐 Notes

- This API is for demo/testing only. In production, use secured headers, origin restrictions, and message signing.
