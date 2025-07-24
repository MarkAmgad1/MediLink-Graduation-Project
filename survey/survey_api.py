from flask import Flask, request, jsonify
import numpy as np
import skfuzzy as fuzz
from skfuzzy import control as ctrl
import firebase_admin
from firebase_admin import credentials, firestore
import unicodedata
import re

app = Flask(__name__)

# Firebase Initialization
cred = credentials.Certificate("medilink-d69f4-firebase-adminsdk-fbsvc-e7cf180a91.json")
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)
db = firestore.client()

# Text normalization
def clean_text(text):
    if not isinstance(text, str):
        return ""
    text = unicodedata.normalize("NFKD", text).strip()
    text = re.sub(r"\s+", " ", text)
    text = text.replace("أ", "ا").replace("إ", "ا").replace("آ", "ا")
    text = text.replace("ى", "ي").replace("ئ", "ي").replace("ؤ", "و")
    return text

@app.route('/analyze', methods=['POST'])
def analyze():

    data = request.get_json(force=True)
    

    # Extract and clean values
    age_value = {
        "18-27": 22,
        "28-40": 34,
        "40+": 50
    }.get(clean_text(data.get('age')), 0)

    response_value = {
        "تحسنت حالتي بشكل ملحوظ": 10,
        "شعرت بتحسن طفيف": 6,
        "لم الاحظ اي تحسن": 3,
        "حالتي ساءت بعد استخدام الدواء": 0
    }.get(clean_text(data.get('response')), 0)

    side_effects_value = {
        "نعم": 10,
        "لا": 0,
        "ربما": 5
    }.get(clean_text(data.get('side_effects')), 0)

    severity_value = {
        "خفيفة": 3,
        "متوسطة": 5,
        "شديدة": 10
    }.get(clean_text(data.get('severity')), 0)

    adherence_value = {
        "نعم": 10,
        "لا": 0,
        "ربما": 5
    }.get(clean_text(data.get('adherence')), 0)

    dosage_timing_value = {
        "نعم التزمت بها في كل الايام": 10,
        "نسيت الجرعة ولكن حاولت على اكبر قدر ممكن": 5,
        "لم التزم بالمواعيد": 0
    }.get(clean_text(data.get('dosage_timing')), 0)

    other_medications_value = {
        "نعم": 1,
        "لا": 0
    }.get(clean_text(data.get('other_medications')), 0)

    chronic_diseases_value = {
        "نعم": 1,
        "لا": 0
    }.get(clean_text(data.get('chronic_diseases')), 0)

    national_id = str(data.get('nationalId')).strip() if data.get('nationalId') and str(data.get('nationalId')).isdigit() else None

    medicine_name = clean_text(data.get('medicine_name'))

    if not national_id:
        return jsonify({"error": "Invalid national ID"}), 400

    # Fuzzy setup
    age = ctrl.Antecedent(np.arange(18, 70, 1), 'age')
    response = ctrl.Antecedent(np.arange(0, 11, 1), 'response')
    side_effects = ctrl.Antecedent(np.arange(0, 11, 1), 'side_effects')
    severity = ctrl.Antecedent(np.arange(0, 11, 1), 'severity')
    adherence = ctrl.Antecedent(np.arange(0, 11, 1), 'adherence')
    dosage_timing = ctrl.Antecedent(np.arange(0, 11, 1), 'dosage_timing')
    other_medications = ctrl.Antecedent(np.arange(0, 2, 1), 'other_medications')
    chronic_diseases = ctrl.Antecedent(np.arange(0, 2, 1), 'chronic_diseases')
    consultation = ctrl.Consequent(np.arange(0, 10.1, 0.1), 'consultation')

    age['young'] = fuzz.trimf(age.universe, [18, 18, 30])
    age['middle'] = fuzz.trimf(age.universe, [25, 40, 50])
    age['old'] = fuzz.trimf(age.universe, [40, 60, 70])

    response['bad'] = fuzz.trimf(response.universe, [0, 0, 3])
    response['moderate'] = fuzz.trimf(response.universe, [3, 5, 8])
    response['good'] = fuzz.trimf(response.universe, [6, 10, 10])

    side_effects['none'] = fuzz.trimf(side_effects.universe, [0, 0, 3])
    side_effects['mild'] = fuzz.trimf(side_effects.universe, [2, 4, 6])
    side_effects['severe'] = fuzz.trimf(side_effects.universe, [7, 10, 10])

    severity['mild'] = fuzz.trimf(severity.universe, [0, 0, 4])
    severity['moderate'] = fuzz.trimf(severity.universe, [2, 5, 8])
    severity['severe'] = fuzz.trimf(severity.universe, [8, 10, 10])

    adherence['low'] = fuzz.trimf(adherence.universe, [0, 0, 5])
    adherence['medium'] = fuzz.trimf(adherence.universe, [3, 5, 8])
    adherence['high'] = fuzz.trimf(adherence.universe, [6, 10, 10])

    dosage_timing['low'] = fuzz.trimf(dosage_timing.universe, [0, 0, 5])
    dosage_timing['medium'] = fuzz.trimf(dosage_timing.universe, [3, 5, 8])
    dosage_timing['high'] = fuzz.trimf(dosage_timing.universe, [6, 10, 10])

    other_medications['no'] = fuzz.trimf(other_medications.universe, [0, 0, 1])
    other_medications['yes'] = fuzz.trimf(other_medications.universe, [1, 1, 1])

    chronic_diseases['no'] = fuzz.trimf(chronic_diseases.universe, [0, 0, 1])
    chronic_diseases['yes'] = fuzz.trimf(chronic_diseases.universe, [1, 1, 1])

    consultation['not_needed'] = fuzz.trimf(consultation.universe, [0, 0, 3.5])
    consultation['maybe'] = fuzz.trimf(consultation.universe, [3, 5.5, 7.5])
    consultation['needed'] = fuzz.trimf(consultation.universe, [7, 10, 10])

    rules = [
        ctrl.Rule(response['bad'] & (side_effects['mild'] | side_effects['severe']), consultation['needed']),
        ctrl.Rule(response['bad'] & severity['severe'], consultation['needed']),
        ctrl.Rule(response['bad'] & adherence['low'], consultation['needed']),
        ctrl.Rule(response['moderate'] & adherence['medium'], consultation['maybe']),
        ctrl.Rule(side_effects['mild'] & adherence['medium'], consultation['maybe']),
        ctrl.Rule(dosage_timing['medium'] & severity['moderate'], consultation['maybe']),
        ctrl.Rule(response['good'] & side_effects['none'], consultation['not_needed']),
        ctrl.Rule(adherence['high'] & response['good'], consultation['not_needed']),
        ctrl.Rule(dosage_timing['high'] & response['good'], consultation['not_needed']),
        ctrl.Rule(chronic_diseases['yes'] | other_medications['yes'], consultation['needed']),
        ctrl.Rule(age['old'] & chronic_diseases['yes'], consultation['needed']),
        ctrl.Rule(response['moderate'] & side_effects['none'] & adherence['high'], consultation['not_needed']),
        ctrl.Rule(response['moderate'] & severity['moderate'], consultation['maybe']),
        ctrl.Rule(response['good'] & chronic_diseases['yes'], consultation['maybe']),
    ]

    consultation_ctrl = ctrl.ControlSystem(rules)
    consultation_sim = ctrl.ControlSystemSimulation(consultation_ctrl)

    consultation_sim.input['age'] = age_value
    consultation_sim.input['response'] = response_value
    consultation_sim.input['side_effects'] = side_effects_value
    consultation_sim.input['severity'] = severity_value
    consultation_sim.input['adherence'] = adherence_value
    consultation_sim.input['dosage_timing'] = dosage_timing_value
    consultation_sim.input['other_medications'] = other_medications_value
    consultation_sim.input['chronic_diseases'] = chronic_diseases_value

    consultation_sim.compute()
    result_score = consultation_sim.output['consultation']

    if result_score >= 7:
        status = "needed"
    elif result_score >= 3:
        status = "maybe"
    else:
        status = "not needed"

    doc_id = f"{national_id}_{medicine_name}"
    db.collection('survey_results').document(doc_id).set({
    'nationalId': national_id,
    'medicine': medicine_name,
    'score': result_score,
    'status': status,
    'timestamp': firestore.SERVER_TIMESTAMP
})


    return jsonify({"score": round(result_score, 2), "status": status}), 200

if __name__ == '__main__':
    app.run(port=5000)
