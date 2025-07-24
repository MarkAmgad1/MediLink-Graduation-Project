import 'package:flutter/material.dart';
import 'login.dart';
import 'createaccount1.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // ✅ ضفنا ScreenUtil

class WelcomePage extends StatefulWidget {
  final Function(Locale) setLocale;
  const WelcomePage({super.key, required this.setLocale});

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  Widget build(BuildContext context) {
    var localization = AppLocalizations.of(context)!;
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0.w), // ✅ Responsive padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png', // شعار الصفحة
              height: 320.h, // ✅ Responsive height
            ),
            SizedBox(height: 30.h),
            Text(
              localization.onboarding_title,
              style: TextStyle(
                fontSize: 30.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10.h),
            Text(
              localization.wp,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18.sp, color: Colors.black54),
            ),
            SizedBox(height: 30.h),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(136, 151, 108, 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50.0.r),
                ),
                minimumSize: Size(280.w, 70.h),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => LoginPage(setLocale: widget.setLocale)),
                );
              },
              child: Text(
                localization.login,
                style: TextStyle(fontSize: 28.sp, color: Colors.white),
              ),
            ),
            SizedBox(height: 15.h),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF88976C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50.0.r),
                ),
                minimumSize: Size(280.w, 70.h),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => CreateAccountPage(setLocale: widget.setLocale)),
                );
              },
              child: Text(
                localization.create_account,
                style: TextStyle(fontSize: 28.sp, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
