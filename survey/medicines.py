import firebase_admin
from firebase_admin import credentials, firestore
import gspread
from oauth2client.service_account import ServiceAccountCredentials

# Firebase setup
cred = credentials.Certificate("medilink-d69f4-firebase-adminsdk-fbsvc-e7cf180a91.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# Google Sheets setup
scope = [
    "https://spreadsheets.google.com/feeds",
    "https://www.googleapis.com/auth/drive"
]
sheet_creds = ServiceAccountCredentials.from_json_keyfile_name(
    "medilink-d69f4-d2a8d3feb65f.json", scope
)
gc = gspread.authorize(sheet_creds)

# افتح Google Spreadsheet
spreadsheet = gc.open("استشارة  (Responses)")

# حاول تفتح ورقة 'Medicines' أو أنشئها
try:
    sheet = spreadsheet.worksheet("Medicines")
except gspread.exceptions.WorksheetNotFound:
    sheet = spreadsheet.add_worksheet(title="Medicines", rows="100", cols="2")

# امسح العمود A من A2 إلى آخر الصفوف فقط (تسيب الـ Header)
sheet.batch_clear(["A2:A"])

# تأكد إن A1 فيه header (لو فاضي، ضيفه)
# تأكد إن A1 فيه header (لو فاضي، ضيفه)
if not sheet.cell(1, 1).value:
    sheet.update("A1", [["medicine_name"]])


# اجمع أسماء الأدوية من Firebase
medicines = set()
prescriptions = db.collection('prescriptions').stream()
for pres in prescriptions:
    meds = db.collection('prescriptions').document(pres.id).collection('medicines').stream()
    for m in meds:
        name = m.to_dict().get('name')
        if name:
            medicines.add(name.strip())

# اكتب الأسماء تحت الـ Header مباشرة
if medicines:
    sheet.update("A2", [[name] for name in sorted(medicines)])

print("✅ تم تحديث قائمة الأدوية بنجاح مع الحفاظ على الـ Header.")
