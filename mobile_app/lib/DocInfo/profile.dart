import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DoctorProfilePage extends StatefulWidget {
  final Function(Locale) setLocale;

  const DoctorProfilePage({super.key, required this.setLocale});

  @override
  _DoctorProfilePageState createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  bool isEditing = false;

  final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  final RegExp nameRegex = RegExp(r'^[a-zA-Z\u0621-\u064A\s]+$');

  late TextEditingController nameController;
  late TextEditingController phoneNumberController;
  late TextEditingController emailController;
  late TextEditingController workplaceController;
  late TextEditingController medicalLicenseController;
  late TextEditingController specializationController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    phoneNumberController = TextEditingController();
    emailController = TextEditingController();
    workplaceController = TextEditingController();
    medicalLicenseController = TextEditingController();
    specializationController = TextEditingController();

    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      String uid = user.uid;

      QuerySnapshot snapshot = await _firestore
          .collection('doctors')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return;

      DocumentSnapshot doc = snapshot.docs.first;
      var data = doc.data() as Map<String, dynamic>;

      setState(() {
        nameController.text = data['name'] ?? '';
        phoneNumberController.text = data['phone'] ?? '';
        emailController.text = data['email'] ?? '';
        workplaceController.text = data['workplace'] ?? '';
        medicalLicenseController.text = data['license'] ?? '';
        specializationController.text = data['specialization'] ?? '';
      });
    } catch (e) {
      print("Error loading doctor data: $e");
    }
  }

  Future<void> saveUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      QuerySnapshot snapshot = await _firestore
          .collection('doctors')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return;

      String docId = snapshot.docs.first.id;

      await _firestore.collection('doctors').doc(docId).update({
        'name': nameController.text,
        'phone': phoneNumberController.text,
        'email': emailController.text,
        'workplace': workplaceController.text,
        'license': medicalLicenseController.text,
        'specialization': specializationController.text,
      });

      print("Doctor data updated!");
    } catch (e) {
      print("Error saving Firestore data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    var localization = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.0.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Image.asset(
                        'assets/bb.png',
                        height: 45.h,
                        width: 45.w,
                      ),
                    ),
                    SizedBox(width: 15.w),
                    Text(
                      localization.doctor,
                      style: TextStyle(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF88976C),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30.h),
                Center(
                  child: CircleAvatar(
                    radius: 80.r,
                    backgroundImage: AssetImage('assets/doctor_image.png'),
                  ),
                ),
                SizedBox(height: 30.h),
                _buildEditableField(
                  icon: 'assets/name_icon.png',
                  label: localization.name,
                  controller: nameController,
                  isEditable: isEditing,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return localization.name_required;
                    }
                    if (!nameRegex.hasMatch(value.trim())) {
                      return localization.name_invalid;
                    }
                    return null;
                  },
                  helperText: localization.enter_full_name,
                ),
                _buildEditableField(
                  icon: 'assets/phone_icon.png',
                  label: localization.phone_number,
                  controller: phoneNumberController,
                  isEditable: isEditing,
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
                _buildEditableField(
                  icon: 'assets/email_icon.png',
                  label: localization.email,
                  controller: emailController,
                  isEditable: isEditing,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return localization.email_required;
                    }
                    if (!emailRegex.hasMatch(value.trim())) {
                      return localization.email_invalid;
                    }
                    return null;
                  },
                  helperText: localization.enter_valid_email,
                ),
                _buildEditableField(
                  icon: 'assets/workplace_icon.png',
                  label: localization.workplace,
                  controller: workplaceController,
                  isEditable: isEditing,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? localization.workplace_required
                      : null,
                  helperText: localization.enter_workplace,
                ),
                _buildEditableField(
                  icon: 'assets/license_icon.png',
                  label: localization.medical_license,
                  controller: medicalLicenseController,
                  isEditable: isEditing,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? localization.license_required
                      : null,
                  helperText: localization.enter_license_number,
                ),
                _buildEditableField(
                  icon: 'assets/specialization_icon.png',
                  label: localization.specialization,
                  controller: specializationController,
                  isEditable: isEditing,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? localization.specialization_required
                      : null,
                  helperText: localization.enter_specialization,
                ),
                SizedBox(height: 30.h),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF88976C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                      minimumSize: Size(200.w, 50.h),
                    ),
                    onPressed: () {
                      setState(() {
                        if (isEditing) {
                          if (_formKey.currentState!.validate()) {
                            saveUserData();
                            isEditing = false;
                          }
                        } else {
                          isEditing = true;
                        }
                      });
                    },
                    child: Text(
                      isEditing ? localization.save : localization.edit,
                      style: TextStyle(fontSize: 18.sp, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String icon,
    required String label,
    required TextEditingController controller,
    required bool isEditable,
    required String? Function(String?) validator,
    String? helperText,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.0.h),
      child: Row(
        children: [
          Image.asset(icon, height: 30.h, width: 30.w),
          SizedBox(width: 10.w),
          Expanded(
            child: TextFormField(
              controller: controller,
              readOnly: !isEditable,
              validator: validator,
              decoration: InputDecoration(
                labelText: label,
                helperText: helperText,
                labelStyle: TextStyle(fontSize: 16.sp),
                border: const UnderlineInputBorder(),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF88976C)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
