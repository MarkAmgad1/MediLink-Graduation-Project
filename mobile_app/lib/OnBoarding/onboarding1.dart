import 'package:flutter/material.dart';
import 'onboarding2.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // ✅ ضفنا ScreenUtil

class PrescriptionPage extends StatefulWidget {
  final Function(Locale) setLocale;
  const PrescriptionPage({super.key, required this.setLocale});

  @override
  _PrescriptionPageState createState() => _PrescriptionPageState();
}

class _PrescriptionPageState extends State<PrescriptionPage> {
  @override
  Widget build(BuildContext context) {
    var localization = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(AppLocalizations.of(context)!.change_language),
                    actions: [
                      TextButton(
                        onPressed: () {
                          widget.setLocale(const Locale('en'));
                          Navigator.pop(context);
                        },
                        child: const Text("English"),
                      ),
                      TextButton(
                        onPressed: () {
                          widget.setLocale(const Locale('ar'));
                          Navigator.pop(context);
                        },
                        child: const Text("العربية"),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0.w), // ✅ Responsive padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 30.h),
            Text(
              localization.simplify_Your,
              style: TextStyle(
                fontSize: 35.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              localization.prescriptions,
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF88976C),
              ),
            ),
            SizedBox(height: 25.h),
            Text(
              localization.ob1,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18.sp,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 30.h),
            Image.asset(
              'assets/prescription.png',
              height: 320.h, // ✅ Responsive image height
            ),
            SizedBox(height: 40.h),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF88976C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50.0.r),
                ),
                minimumSize: Size(250.w, 70.h),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PharmacistControlPage(setLocale: widget.setLocale),
                  ),
                );
              },
              child: Text(
                localization.next,
                style: TextStyle(
                  fontSize: 30.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
