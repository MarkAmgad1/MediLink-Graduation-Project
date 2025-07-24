import 'package:flutter/material.dart';
import 'package:flutter_application_1/Prescription/newpre.dart';
import 'package:flutter_application_1/Prescription/allpre.dart';
import 'package:flutter_application_1/DocInfo/setting.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // ✅ ضفنا ScreenUtil

class HomePage extends StatefulWidget {
  final Function(Locale) setLocale;
  const HomePage({super.key, required this.setLocale});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String doctorName = "";

  @override
  void initState() {
    super.initState();
    loadDoctorName();
  }

  Future<void> loadDoctorName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          doctorName = "Dr. ${doc['name'] ?? ''}";
        });
      }
    } catch (e) {
      print("Error loading doctor name: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    var localization = AppLocalizations.of(context)!;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20.0.w), // ✅ Responsive Padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 40.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  doctorName.isNotEmpty
                      ? "${localization.hi} $doctorName"
                      : localization.hi,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF88976C),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SettingsPage(
                          setLocale: widget.setLocale,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 55.w,
                    height: 55.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F4),
                      borderRadius: BorderRadius.circular(15.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.settings,
                      color: const Color(0xFF88976C),
                      size: 30.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30.h),
            Center(
              child: Image.asset(
                'assets/medical_dashboard.png',
                height: 400.h,
              ),
            ),
            SizedBox(height: 50.h),
            Center(
              child: Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3FAED),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                      minimumSize: Size(300.w, 70.h),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AddPrescriptionPage(
                            setLocale: widget.setLocale,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      localization.create_prescription,
                      style: TextStyle(
                        fontSize: 18.sp,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3FAED),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                      minimumSize: Size(300.w, 70.h),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Allpre(
                            setLocale: widget.setLocale,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      localization.view_all_prescriptions,
                      style: TextStyle(
                        fontSize: 18.sp,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
