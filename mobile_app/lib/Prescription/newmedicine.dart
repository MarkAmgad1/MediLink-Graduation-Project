import 'package:flutter/material.dart';
import 'package:flutter_application_1/Prescription/addmedicine.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // ✅ ضفنا ScreenUtil

class AddMedicineform extends StatefulWidget {
  final Function(Locale) setLocale;
  final String prescriptionId;

  const AddMedicineform({
    super.key,
    required this.setLocale,
    required this.prescriptionId,
  });

  @override
  _AddMedicineformState createState() => _AddMedicineformState();
}

class _AddMedicineformState extends State<AddMedicineform> {
  final TextEditingController medicineNameController = TextEditingController();
  final TextEditingController doseController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController freqController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final RegExp alphaNumRegex = RegExp(r'^[a-zA-Z0-9\u0621-\u064A\s]+$');
  final RegExp numberRegex = RegExp(r'^\d+$');
  bool _isLoading = false;

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
              child: SingleChildScrollView(
            padding: EdgeInsets.all(20.0.w),
            child: Column(children: [
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
                    localization.add_medicine,
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.15),
              Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                    _buildTextField(
                      label: localization.medicine_name,
                      controller: medicineNameController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localization.name_required;
                        }
                        if (!RegExp(r'^[a-zA-Z0-9\u0621-\u064A\s]+$')
                            .hasMatch(value.trim())) {
                          return localization.name_invalid;
                        }
                        return null;
                      },
                      helperText: localization.enter_medicine_name,
                    ),
                    SizedBox(height: 20.h),
                    _buildTextField(
                      label: localization.dose,
                      controller: doseController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localization.dose_required;
                        }
                        if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
                          return localization.dose_invalid;
                        }
                        return null;
                      },
                      helperText: localization.enter_dose,
                    ),
                    SizedBox(height: 20.h),
                    _buildTextField(
                      label: localization.duration,
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localization.duration_required;
                        }
                        if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
                          return localization.duration_invalid;
                        }
                        return null;
                      },
                      helperText: localization.enter_duration,
                    ),
                    SizedBox(height: 20.h),
                    _buildTextField(
                      label: localization.frequency,
                      controller: freqController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localization.frequency_required;
                        }
                        if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
                          return localization.frequency_invalid;
                        }
                        return null;
                      },
                      helperText: localization.enter_frequency,
                    ),
                    SizedBox(height: 40.h),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF88976C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0.r),
                        ),
                        minimumSize: Size(150.w, 50.h),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() => _isLoading = true);
                                await _submitMedicine();
                                setState(() => _isLoading = false);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(localization.fill_all_fields),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            },
                      child: _isLoading
                          ? SizedBox(
                              height: 25.h,
                              width: 25.h,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Text(
                              localization.submit,
                              style: TextStyle(
                                  fontSize: 18.sp, color: Colors.white),
                            ),
                    ),
                  ],
                ),
              )
            ]),
          ) // ✅ Responsive Padding
              )
        ],
      ),
    );
  }

  bool _allFieldsValid() {
    return medicineNameController.text.trim().isNotEmpty &&
        doseController.text.trim().isNotEmpty &&
        durationController.text.trim().isNotEmpty &&
        freqController.text.trim().isNotEmpty;
  }

Future<void> _submitMedicine() async {
  if (_allFieldsValid()) {
    try {
      // 1. ❗ احضر بيانات الوصفة الأساسية (عشان نجيب الـ nationalId)
      final prescriptionSnapshot = await FirebaseFirestore.instance
          .collection('prescriptions')
          .doc(widget.prescriptionId)
          .get();

      if (!prescriptionSnapshot.exists) {
        throw Exception("Prescription not found.");
      }

      final prescriptionData = prescriptionSnapshot.data()!;
      final nationalId = prescriptionData['nationalId'];

      final medicineName = medicineNameController.text.trim();

      // 2. ✅ أضف الدواء في الـ subcollection
      await FirebaseFirestore.instance
          .collection('prescriptions')
          .doc(widget.prescriptionId)
          .collection('medicines')
          .add({
        'name': medicineName,
        'dose': doseController.text.trim(),
        'duration': durationController.text.trim(),
        'frequency': freqController.text.trim(),
        'status': 'pending',
        'addedAt': Timestamp.now(),
      });

      // 3. ✅ سجل entry في survey_results
      final docId = '${nationalId}_$medicineName';
      final surveyDoc = await FirebaseFirestore.instance
          .collection('survey_results')
          .doc(docId)
          .get();

      if (!surveyDoc.exists) {
        await FirebaseFirestore.instance
            .collection('survey_results')
            .doc(docId)
            .set({
          'score': 0,
          'status': 'none',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // 4. ✅ Success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.medicines_saved),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // 5. ✅ Navigate
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => AddMedicinePage(
              setLocale: widget.setLocale,
              prescriptionId: widget.prescriptionId,
            ),
          ),
          (route) => false,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving medicine: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.fill_all_fields),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
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
        helperText: helperText,
        labelStyle: TextStyle(color: const Color(0xFF88976C), fontSize: 16.sp),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0.r),
          borderSide: const BorderSide(color: Color(0xFF88976C)),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
