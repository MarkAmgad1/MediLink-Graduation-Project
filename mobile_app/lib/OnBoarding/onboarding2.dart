import 'package:flutter/material.dart';
import 'onboarding3.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // ✅ ضفنا ScreenUtil

class PharmacistControlPage extends StatefulWidget {
  final Function(Locale) setLocale;
  const PharmacistControlPage({super.key, required this.setLocale});

  @override
  _PharmacistControlPageState createState() => _PharmacistControlPageState();
}

class _PharmacistControlPageState extends State<PharmacistControlPage> {
  @override
  Widget build(BuildContext context) {
    var localization = AppLocalizations.of(context)!;
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0.w), // ✅ Responsive Padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 30.h),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 35.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(
                    text: localization.pharmacists,
                    style: TextStyle(
                      color: const Color(0xFF88976C),
                      fontSize: 35.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: localization.stay_in_control,
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              localization.ob2,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18.sp,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 40.h),
            Image.asset(
              'assets/pharmacist_control.png',
              height: 320.h, // ✅ Responsive Image
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
                    builder: (context) => GetStartedPage(setLocale: widget.setLocale),
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
