// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_application_1/Prescription/addmedicine.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EditPrescriptionPage extends StatefulWidget {
  final Function(Locale) setLocale;
  final String name;
  final String nationalID;
  final String age;
  final String phoneNumber;
  final String prescriptionId;

  const EditPrescriptionPage({
    super.key,
    required this.name,
    required this.nationalID,
    required this.age,
    required this.phoneNumber,
    required this.prescriptionId,
    required this.setLocale,
  });

  @override
  _EditPrescriptionPageState createState() => _EditPrescriptionPageState();
}

class _EditPrescriptionPageState extends State<EditPrescriptionPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController nameController;
  late TextEditingController nationalIDController;
  late TextEditingController ageController;
  late TextEditingController phoneNumberController;

  List<Map<String, TextEditingController>> medicines = [];
  List<String> medicineDocIds = [];

  final RegExp nameRegex =
      RegExp(r'^[a-zA-Z\u0621-\u064A\s]{2,}$'); // حروف ومسافات فقط
  final RegExp nationalIdRegex = RegExp(r'^\d{14}$'); // 14 رقم
  final RegExp ageRegex = RegExp(r'^\d{1,2}$'); // 1 أو 2 رقم
  final RegExp phoneRegex = RegExp(r'^\d{11}$'); // 11 رقم
  final RegExp medicineNameRegex =
      RegExp(r'^[a-zA-Z0-9\u0621-\u064A\s]{2,}$'); // حروف + أرقام
  final RegExp numberRegex = RegExp(r'^\d+$'); // أرقام فقط

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    nationalIDController = TextEditingController(text: widget.nationalID);
    ageController = TextEditingController(text: widget.age);
    phoneNumberController = TextEditingController(text: widget.phoneNumber);
    fetchMedicines();
  }

  Future<void> _deleteMedicine(int index) async {
    final docId = medicineDocIds[index];
    try {
      await FirebaseFirestore.instance
          .collection('prescriptions')
          .doc(widget.prescriptionId)
          .collection('medicines')
          .doc(docId)
          .delete();

      setState(() {
        medicines.removeAt(index);
        medicineDocIds.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Medicine deleted"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error deleting medicine"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> fetchMedicines() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('prescriptions')
        .doc(widget.prescriptionId)
        .collection('medicines')
        .get();

    setState(() {
      medicines = snapshot.docs.map((doc) {
        medicineDocIds.add(doc.id);
        return {
          'name': TextEditingController(text: doc['name']),
          'dose': TextEditingController(text: doc['dose']),
          'duration': TextEditingController(text: doc['duration']),
          'frequency': TextEditingController(text: doc['frequency']),
        };
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    var localization = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/background3.png'),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20.0.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Image.asset(
                          'assets/back_icon.png',
                          height: 45.h,
                          width: 45.w,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        localization.edit_prescription,
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 55.h),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.always,
                        child: Column(
                          children: [
                            SizedBox(height: 40.h),
                            _buildValidatedField(
                                localization.name,
                                nameController,
                                nameRegex,
                                localization.enter_full_name),
                            SizedBox(height: 20.h),
                            _buildValidatedField(
                                localization.national_id,
                                nationalIDController,
                                nationalIdRegex,
                                localization.enter_national_id),
                            SizedBox(height: 20.h),
                            _buildValidatedField(
                                localization.age,
                                ageController,
                                ageRegex,
                                localization.enter_patient_age),
                            SizedBox(height: 20.h),
                            _buildValidatedField(
                                localization.phone_number,
                                phoneNumberController,
                                phoneRegex,
                                localization.enter_phone_number),
                            if (medicines.isNotEmpty) ...[
                              SizedBox(height: 20.h),
                              Text(
                                localization.edit_medicine,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 10.h),
                              ...List.generate(medicines.length, (index) {
                                final med = medicines[index];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 10.h),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Medicine ${index + 1}",
                                          style: TextStyle(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.bold,
                                            color: const Color.fromARGB(
                                                255, 0, 0, 0),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () =>
                                              _deleteMedicine(index),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10.h),
                                    _buildValidatedField(
                                        "Name",
                                        med['name']!,
                                        medicineNameRegex,
                                        "Enter medicine name"),
                                    SizedBox(height: 20.h),
                                    _buildValidatedField("Dose", med['dose']!,
                                        numberRegex, "Enter dose amount"),
                                    SizedBox(height: 20.h),
                                    _buildValidatedField(
                                        "Duration",
                                        med['duration']!,
                                        numberRegex,
                                        "Enter duration in days"),
                                    SizedBox(height: 20.h),
                                    _buildValidatedField(
                                        "Frequency",
                                        med['frequency']!,
                                        numberRegex,
                                        "Enter frequency per day"),
                                  ],
                                );
                              }),
                            ],
                            SizedBox(height: 10.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // زرار Add Medicine على الشمال
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => AddMedicinePage(
                                          setLocale: widget.setLocale,
                                          prescriptionId: widget.prescriptionId,
                                        ),
                                      ),
                                    );
                                  },
                                  
                                  label: Text(
                                    "Add Medicine",
                                    style: TextStyle(
                                              fontSize: 18.sp,
                                              color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF88976C),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 20.w, vertical: 12.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(30.0.r),
                                    ),
                                  ),
                                ),

                                // زرار Submit على اليمين
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF88976C),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(30.0.r),
                                    ),
                                    minimumSize: Size(120.w, 50.h),
                                  ),
                                  onPressed:
                                      _isLoading ? null : _updatePrescription,
                                  child: _isLoading
                                      ? CircularProgressIndicator(
                                          color: Colors.white)
                                      : Text(
                                          "Submit",
                                          style: TextStyle(
                                              fontSize: 18.sp,
                                              color: Colors.white),
                                        ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidatedField(String label, TextEditingController controller,
      RegExp pattern, String helperText) {
    return TextFormField(
      controller: controller,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return '$label is required';
        if (!pattern.hasMatch(value.trim())) return 'Invalid $label';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0.r),
          borderSide: const BorderSide(color: Color(0xFF88976C)),
        ),
      ),
    );
  }

  Future<void> _updatePrescription() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('prescriptions')
          .doc(widget.prescriptionId)
          .update({
        'patientName': nameController.text.trim(),
        'nationalId': nationalIDController.text.trim(),
        'age': ageController.text.trim(),
        'phone': phoneNumberController.text.trim(),
      });

      for (int i = 0; i < medicines.length; i++) {
        final docId = medicineDocIds[i];
        final med = medicines[i];
        await FirebaseFirestore.instance
            .collection('prescriptions')
            .doc(widget.prescriptionId)
            .collection('medicines')
            .doc(docId)
            .update({
          'name': med['name']!.text.trim(),
          'dose': med['dose']!.text.trim(),
          'duration': med['duration']!.text.trim(),
          'frequency': med['frequency']!.text.trim(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.update_success),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.update_failed),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
