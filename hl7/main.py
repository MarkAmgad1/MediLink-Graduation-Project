from fastapi import FastAPI
from pydantic import BaseModel
from hl7apy.core import Message
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # يمكنك تخصيصها لاحقًا
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class DoctorData(BaseModel):
    doctor_id: str
    name: str
    phonenumber: str
    specialization: str
    license: str
    workplace: str

@app.post("/send-hl7")
async def send_hl7(data: DoctorData):
    msg = Message("ADT_A01")

    # إعداد الرسالة HL7
    msg.msh.msh_3 = 'MyApp'
    msg.msh.msh_4 = 'MyFacility'
    msg.msh.msh_5 = 'HL7Receiver'
    msg.msh.msh_7 = '20250412120000'  # Timestamp
    msg.msh.msh_9 = 'ADT^A01'  # Message type
    msg.msh.msh_10 = 'MSG00001'  # Message control ID
    msg.msh.msh_11 = 'P'
    msg.msh.msh_12 = '2.3'  # HL7 version

    # بيانات الطبيب
    msg.pid.pid_3 = data.doctor_id  # doctor_id
    msg.pid.pid_5 = data.name  # doctor's name
    msg.pid.pid_13 = data.phonenumber  # doctor's phone number
    
    # يمكنك إضافة المزيد من البيانات حسب الحاجة
    msg.add_segment('NTE')
    msg.nte.nte_3 = f"Specialization: {data.specialization}, License: {data.license}, Workplace: {data.workplace}"

    return {"hl7_message": msg.to_er7()}
