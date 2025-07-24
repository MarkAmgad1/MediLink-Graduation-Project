import 'package:flutter/material.dart';
import 'package:flutter_application_1/Prescription/addmedicine.dart';
import 'package:flutter_application_1/Prescription/editpre.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // ✅ ضفنا ScreenUtil

class AddPrescriptionPage extends StatefulWidget {
  final Function(Locale) setLocale;
  const AddPrescriptionPage({super.key, required this.setLocale});

  @override
  _AddPrescriptionPageState createState() => _AddPrescriptionPageState();
}

class _AddPrescriptionPageState extends State<AddPrescriptionPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController nationalIdController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();

  final RegExp nameRegex = RegExp(r'^[a-zA-Z\u0621-\u064A\s]+$');

  @override
  Widget build(BuildContext context) {
    var localization = AppLocalizations.of(context)!;

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0.w),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 55.h),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Image.asset('assets/back_icon.png',
                              height: 45.h, width: 45.w),
                        ),
                        SizedBox(width: 15.w),
                        Text(
                          localization.add_prescription,
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 120.h),
                    _buildTextField(
                      controller: nameController,
                      label: localization.name,
                      hint: localization.enter_patient_name,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localization.name_required;
                        }
                        if (!nameRegex.hasMatch(value.trim())) {
                          return localization.name_invalid;
                        }
                        return null;
                      },
                      helperText: localization.enter_patient_name,
                    ),
                    SizedBox(height: 35.h),
                    _buildTextField(
                      controller: nationalIdController,
                      label: localization.national_id,
                      hint: localization.enter_national_id,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localization.national_id_required;
                        }
                        if (!RegExp(r'^\d{14}$').hasMatch(value.trim())) {
                          return localization.national_id_invalid;
                        }
                        return null;
                      },
                      helperText: localization.enter_national_id,
                    ),
                    SizedBox(height: 35.h),
                    _buildTextField(
                      controller: ageController,
                      label: localization.age,
                      hint: localization.enter_patient_age,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localization.age_required;
                        }
                        if (!RegExp(r'^\d{1,2}$').hasMatch(value.trim())) {
                          return localization.age_invalid;
                        }
                        return null;
                      },
                      helperText: localization.enter_patient_age,
                    ),
                    SizedBox(height: 35.h),
                    _buildTextField(
                      controller: phoneNumberController,
                      label: localization.phone_number,
                      hint: localization.enter_phone_number,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localization.phone_required;
                        }
                        if (!RegExp(r'^\d{11}$').hasMatch(value.trim())) {
                          return localization.phone_invalid;
                        }
                        return null;
                      },
                      helperText: localization.enter_phone_number,
                    ),
                    SizedBox(height: 60.h),
                    Center(
                      child: _isLoading
                          ? CircularProgressIndicator()
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF88976C),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50.0.r),
                                ),
                                minimumSize: Size(250.w, 70.h),
                              ),
                              onPressed: () async {
                                if (!_formKey.currentState!.validate()) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(localization
                                          .please_fill_all_fields_correctly),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                setState(() => _isLoading = true);
                                await _savePrescription();
                                setState(() => _isLoading = false);
                              },
                              child: Text(
                                localization.next,
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                    SizedBox(height: 30.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    String? helperText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        labelStyle: TextStyle(color: const Color(0xFF88976C), fontSize: 16.sp),
        hintStyle: TextStyle(fontSize: 14.sp),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0.r),
          borderSide: const BorderSide(color: Color(0xFF88976C)),
        ),
      ),
    );
  }

Future<void> _savePrescription() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("No user logged in."),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final String doctorId = user.uid;
  final String nationalId = nationalIdController.text.trim();
  final String name = nameController.text.trim();
  final String age = ageController.text.trim();
  final String phone = phoneNumberController.text.trim();

  try {
    // ✅ البحث إذا كان national ID موجود
    final existing = await FirebaseFirestore.instance
        .collection("prescriptions")
        .where("nationalId", isEqualTo: nationalId)
        .where("doctorId", isEqualTo: doctorId) // تأكد إنها وصفة لنفس الدكتور
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final existingDoc = existing.docs.first;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EditPrescriptionPage(
            setLocale: widget.setLocale,
            prescriptionId: existingDoc.id,
            name: existingDoc['patientName'],
            nationalID: existingDoc['nationalId'],
            age: existingDoc['age'],
            phoneNumber: existingDoc['phone'],
          ),
        ),
      );
      return; // ❗وقف التنفيذ بعد التحويل
    }

    // ✅ إضافة prescription جديد لو مش موجود
    final prescriptionRef =
        await FirebaseFirestore.instance.collection("prescriptions").add({
      'doctorId': doctorId,
      'patientName': name,
      'nationalId': nationalId,
      'age': age,
      'phone': phone,
      'timestamp': Timestamp.now(),
    });



    // ✅ تنظيف الحقول
    nameController.clear();
    nationalIdController.clear();
    ageController.clear();
    phoneNumberController.clear();

    // ✅ الانتقال لإضافة الأدوية
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddMedicinePage(
          setLocale: widget.setLocale,
          prescriptionId: prescriptionRef.id,
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error saving prescription: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
}
}
