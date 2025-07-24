import 'package:flutter/material.dart';
import 'package:flutter_application_1/DocInfo/welcome.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ ضفنا ScreenUtil

class GetStartedPage extends StatefulWidget {
  final Function(Locale) setLocale;
  const GetStartedPage({super.key, required this.setLocale});

  @override
  _GetStartedPageState createState() => _GetStartedPageState();
}

class _GetStartedPageState extends State<GetStartedPage> {
  @override
  Widget build(BuildContext context) {
    var localization = AppLocalizations.of(context)!;
    return Scaffold(
      body: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: 20.0.w), // ✅ Responsive Padding
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
                    text: localization.lets,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 35.sp,
                    ),
                  ),
                  TextSpan(
                    text: localization.get_started,
                    style: TextStyle(
                      color: const Color(0xFF88976C),
                      fontWeight: FontWeight.bold,
                      fontSize: 35.sp,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 15.h),
            Text(
              localization.ob3,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18.sp,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 40.h),
            Image.asset(
              'assets/get_started.png',
              height: 320.h, // ✅ Responsive Image Height
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
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('onboardingSeen', true);

                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) =>
                        WelcomePage(setLocale: widget.setLocale),
                  ),
                );
              },
              child: Text(
                localization.get_started,
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
