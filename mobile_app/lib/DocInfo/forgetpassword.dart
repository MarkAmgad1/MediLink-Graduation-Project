import 'package:flutter/material.dart';
import 'login.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // ✅ استدعينا screenutil

class ForgotPasswordPage extends StatefulWidget {
  final Function(Locale) setLocale;

  const ForgotPasswordPage({super.key, required this.setLocale});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();

  Future resetPassword() async {
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: emailController.text.trim());
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Container(
                height: 100.h,
                width: 150.w,
                child: Column(
                  children: [
                    Text(
                      "Password reset link sent! Check your email",
                      style: TextStyle(fontSize: 16.sp),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10.h),
                    TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginPage(setLocale: widget.setLocale),
                            ),
                          );
                        },
                        child: Text(
                          "OK",
                          style: TextStyle(
                            color: Color(0xFF9C3FE4),
                            fontSize: 16.sp,
                          ),
                        ))
                  ],
                ),
              ),
            );
          });
    } on FirebaseAuthException catch (e) {
      print(e);
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text(
                e.message.toString(),
                style: TextStyle(fontSize: 16.sp),
              ),
            );
          });
    }
  }

  bool isEmailEntered = false;

  @override
  void initState() {
    super.initState();
    emailController.addListener(() {
      setState(() {
        isEmailEntered = emailController.text.isNotEmpty;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var localization = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(20.0.w), // ✅ responsive padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 40.h),
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
              ],
            ),
            SizedBox(height: 30.h),
            Text(
              localization.forgot_password,
              style: TextStyle(
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              localization.forgot_password_description,
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 30.h),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: localization.email,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0.r),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0.r),
                  borderSide: const BorderSide(color: Color.fromRGBO(136, 151, 108, 1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0.r),
                  borderSide: const BorderSide(color: Color.fromRGBO(136, 151, 108, 1), width: 2),
                ),
              ),
            ),
            SizedBox(height: 30.h),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEmailEntered
                      ? const Color(0xFF88976C)
                      : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  minimumSize: Size(200.w, 50.h),
                ),
                onPressed: isEmailEntered
                    ? () async {
                        await resetPassword();
                      }
                    : null,
                child: Text(
                  localization.send_link,
                  style: TextStyle(
                    fontSize: 18.sp,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Spacer(),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    localization.have_an_account,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.black,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => LoginPage(setLocale: widget.setLocale),
                        ),
                      );
                    },
                    child: Text(
                      localization.login,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Color(0xFF88976C),
                        fontWeight: FontWeight.bold,
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
