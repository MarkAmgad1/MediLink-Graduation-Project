import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import '../doctoroverview.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import '../widgets/id_ml_camera_screen.dart';
import 'package:image_picker/image_picker.dart';

class CreateDoctorAccountPage extends StatefulWidget {
  final Function(Locale) setLocale;
  final TextEditingController namecontroller;
  final TextEditingController emailcontroller;
  final TextEditingController phonecontroller;
  final TextEditingController passwordcontroller;

  const CreateDoctorAccountPage({
    super.key,
    required this.setLocale,
    required this.namecontroller,
    required this.emailcontroller,
    required this.phonecontroller,
    required this.passwordcontroller,
  });

  @override
  _CreateDoctorAccountPageState createState() =>
      _CreateDoctorAccountPageState();
}

class _CreateDoctorAccountPageState extends State<CreateDoctorAccountPage> {
  final TextEditingController licenseController = TextEditingController();
  final TextEditingController workplaceController = TextEditingController();
  final TextEditingController specializationController =
      TextEditingController();
  File? _selectedImage;
  bool _isVerifying = false;
  final _formKey = GlobalKey<FormState>();
  bool isFormValid = false;

  void _checkFormValid() {
    final formValid = _formKey.currentState?.validate() ?? false;
    setState(() {
      isFormValid = formValid && _selectedImage != null;
    });
  }

  @override
  void dispose() {
    licenseController.dispose();
    workplaceController.dispose();
    specializationController.dispose();
    super.dispose();
  }

  void _chooseImageSource() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16.w),
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: Color(0xFF88976C)),
                title: Text(AppLocalizations.of(context)!.take_photo),
                onTap: () {
                  Navigator.pop(context);
                  _openCamera();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: Color(0xFF88976C)),
                title: Text(AppLocalizations.of(context)!.choose_from_gallery),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      setState(() {
        _selectedImage = imageFile;
      });

      await verifyID(imageFile); // ✅ إرسالها للتحقق بعد الاختيار
      _checkFormValid(); // ✅ نحدث حالة الفورم
    }
  }

  void _openCamera() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            IDMLCameraScreen(onImageCaptured: (File image) async {
          setState(() {
            _selectedImage = image;
          });

          await verifyID(image); // ✅ إرسال الصورة للتحقق
          _checkFormValid(); // ✅ إعادة التحقق من صلاحية الفورم
        }),
      ),
    );
  }

  Future<bool> verifyID(File imageFile) async {
    var localization = AppLocalizations.of(context)!;
    setState(() {
      _isVerifying = true; // ✨ لما تبدأ تحقق خلي اللودينج شغال
    });

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.1.6:5000/verify_id'),
    );

    final mimeTypeData = lookupMimeType(imageFile.path)?.split('/');
    if (mimeTypeData == null) {
      setState(() {
        _isVerifying = false; // ✨ حتى لو حصل Error قفل اللودينج
      });
      return false;
    }

    request.files.add(await http.MultipartFile.fromPath(
      'image',
      imageFile.path,
      contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
    ));

    try {
      var response = await request.send();
      setState(() {
        _isVerifying = false;
      });

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = json.decode(respStr);

        if (data['verified'] == true && data['expired'] == false) {
          return true;
        } else if (data['verified'] == true && data['expired'] == true) {
          _showAlertDialog(
              localization.idExpiredTitle, localization.idExpiredMessage);
          return false;
        } else {
          _showAlertDialog(
              localization.invalidIdTitle, localization.invalidIdMessage);
          return false;
        }
      } else {
        _showAlertDialog(
            localization.errorTitle, localization.serverErrorMessage);
        return false;
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
      });
      print("Error verifying ID: $e");
      _showAlertDialog(
          localization.errorTitle, localization.generalErrorMessage);
      return false;
    }
  }

  Future<void> _sendToHL7(DoctorData data) async {
    var url = Uri.parse(
        'http://192.168.1.8:8000/send-hl7'); // الرابط بتاع الـ API بتاعك
    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "doctor_id": data.doctorId,
          "name": data.name,
          "phonenumber": data.phoneNumber,
          "specialization": data.specialization,
          "license": data.license,
          "workplace": data.workplace,
        }),
      );

      if (response.statusCode == 200) {
        print("HL7 Message sent successfully.");

        // استلام الرسالة HL7 من الـ API
        var hl7Message = json.decode(response.body)['hl7_message'];

        // تخزين الرسالة في Firebase
        await FirebaseFirestore.instance.collection('hl7_messages').add({
          'doctor_id': data.doctorId,
          'hl7_message': hl7Message, // الرسالة المُولدة
          'timestamp': FieldValue.serverTimestamp(),
        });

        print("HL7 message stored in Firebase.");
      } else {
        print("Failed to send HL7 message.");
      }
    } catch (e) {
      print("Error sending HL7 message: $e");
    }
  }

  Future<bool> allsignup() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("No user logged in.");
        return false;
      }

      String uid = user.uid;

      final db = FirebaseFirestore.instance;
      final doctorRef = db.collection("doctors").doc(uid);

      Map<String, dynamic> additionalData = {
        "license": licenseController.text,
        "workplace": workplaceController.text,
        "specialization": specializationController.text,
      };

      await doctorRef.set(additionalData, SetOptions(merge: true));

      print("✅ Extra doctor data saved with UID: $uid");
      return true;
    } catch (e) {
      print("❌ Error saving extra doctor data: $e");
      return false;
    }
  }

  Future<void> _register() async {
    var localization = AppLocalizations.of(context)!;

    // ✅ Check الأول: هل الحقول فاضية؟
    if (licenseController.text.isEmpty ||
        workplaceController.text.isEmpty ||
        specializationController.text.isEmpty ||
        _selectedImage == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(localization.incomplete_info),
          content: Text(localization.fill_all_fields),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localization.ok),
            ),
          ],
        ),
      );
      return; // ❌ متكملش التسجيل
    }

    // ✅ Check الثاني: تحقق من البطاقة قبل التسجيل
    bool idVerified = await verifyID(_selectedImage!);
    if (!idVerified) {
      return; // ❌ لو البطاقة مش متحققة متكملش
    }

    try {
      // ✅ إنشاء الحساب بعد تحقق البطاقة
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.emailcontroller.text.trim(),
        password: widget.passwordcontroller.text.trim(),
      );

      String uid = userCredential.user!.uid;

      // ✅ تخزين بيانات الدكتور
      FirebaseFirestore db = FirebaseFirestore.instance;
      final doctorRef = db.collection("doctors").doc(uid);

      Map<String, dynamic> doctorData = {
        "uid": uid,
        "name": widget.namecontroller.text,
        "email": widget.emailcontroller.text,
        "phone": widget.phonecontroller.text,
        "license": licenseController.text,
        "workplace": workplaceController.text,
        "specialization": specializationController.text,
        "timestamp": FieldValue.serverTimestamp(),
        "userType": "mobile",
      };

      await doctorRef.set(doctorData);

      // إنشاء كائن DoctorData وإرساله عبر HL7
      DoctorData doctorDataHL7 = DoctorData(
        doctorId: uid,
        name: widget.namecontroller.text,
        phoneNumber: widget.phonecontroller.text,
        specialization: specializationController.text,
        license: licenseController.text,
        workplace: workplaceController.text,
      );

      // إرسال البيانات عبر API
      await _sendToHL7(doctorDataHL7);

      // ✅ تسجيل ناجح
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/success_icon.png', height: 100.h),
              SizedBox(height: 20.h),
              Text(
                localization.register_success,
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => HomePage(setLocale: widget.setLocale),
                  ),
                );
              },
              child: Text(localization.ok),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('The password provided is too weak.')),
        );
      } else if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('The account already exists for that email.')),
        );
      }
    } catch (e) {
      print('❌ Error during registration: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred during registration.')),
      );
    }
  }

  void _showAlertDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var localization = AppLocalizations.of(context)!;
    return Scaffold(
        body: Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background2.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
            child: SingleChildScrollView(
                child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Form(
                  key: _formKey,
                  onChanged: _checkFormValid,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 60.h),
                      Center(
                        child: Text(
                          localization.create_account,
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 90.h),
                      _buildValidatedTextField(
                        label: localization.license,
                        controller: licenseController,
                        helperText: localization.license_helper,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localization.field_required;
                          }
                          if (!RegExp(r'^[a-zA-Z0-9\u0621-\u064A]+$')
                              .hasMatch(value)) {
                            return localization
                                .license_invalid; // ← ضيفها في ملف الترجمة
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 35.h),
                      _buildValidatedTextField(
                        label: localization.workplace,
                        controller: workplaceController,
                        helperText: localization.workplace_helper,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localization.field_required;
                          }
                          if (!RegExp(r'^[a-zA-Z\u0621-\u064A\s]+$')
                              .hasMatch(value)) {
                            return localization.workplace_letters_only;
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 35.h),
                      _buildValidatedTextField(
                        label: localization.specialization,
                        controller: specializationController,
                        helperText: localization.specialization_helper,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localization.field_required;
                          }
                          if (!RegExp(r'^[a-zA-Z\u0621-\u064A\s]+$')
                              .hasMatch(value)) {
                            return localization.specialization_letters_only;
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 35.h),
                      GestureDetector(
                        onTap: _chooseImageSource,
                        child: Container(
                          height: 150.h,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F4F4),
                            borderRadius: BorderRadius.circular(15.r),
                            border: Border.all(color: const Color(0xFF88976C)),
                          ),
                          child: Center(
                            child: _selectedImage == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate,
                                          size: 50.sp,
                                          color: const Color(0xFF88976C)),
                                      SizedBox(height: 20.h),
                                      Text(
                                        localization.upload_image,
                                        style: TextStyle(
                                            color: const Color(0xFF88976C),
                                            fontSize: 16.sp),
                                      ),
                                    ],
                                  )
                                : Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 150.h,
                                  ),
                          ),
                        ),
                      ),
                      SizedBox(height: 50.h),
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF88976C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50.0.r),
                            ),
                            minimumSize: Size(250.w, 60.h),
                          ),
                          onPressed: isFormValid ? _register : null,
                          child: Text(
                            localization.register,
                            style:
                                TextStyle(fontSize: 20.sp, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  )),
            )),
          ),
        ),
        if (_isVerifying)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: SizedBox(
                  height: 150.h,
                  width: 150.w,
                  child: Lottie.asset(
                      'assets/animation/Animation - 1745728014545.json',
                      repeat: true),
                ),
              ),
            ),
          )
      ],
    ));
  }

  Widget _buildValidatedTextField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required String helperText,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        labelStyle: TextStyle(color: const Color(0xFF88976C), fontSize: 16.sp),
        filled: true,
        fillColor: Colors.white.withOpacity(0.95),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0.r),
          borderSide: const BorderSide(color: Color(0xFF88976C)),
        ),
      ),
    );
  }
}

class DoctorData {
  final String doctorId;
  final String name;
  final String phoneNumber;
  final String specialization;
  final String license;
  final String workplace;

  DoctorData({
    required this.doctorId,
    required this.name,
    required this.phoneNumber,
    required this.specialization,
    required this.license,
    required this.workplace,
  });
}
