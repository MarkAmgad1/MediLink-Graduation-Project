import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../doctoroverview.dart';
import 'forgetpassword.dart';
import 'package:flutter_application_1/DocInfo/welcome.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginPage extends StatefulWidget {
  final Function(Locale) setLocale;
  const LoginPage({super.key, required this.setLocale});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailcontroller = TextEditingController();
  final TextEditingController passwordcontroller = TextEditingController();

  @override
  void dispose() {
    emailcontroller.dispose();
    passwordcontroller.dispose();
    super.dispose();
  }

  bool isPasswordVisible = false;
  bool keepMeSignedIn = false;
  final LocalAuthentication auth = LocalAuthentication();
  final FlutterSecureStorage storage = FlutterSecureStorage();

  Future<void> _authenticate() async {
    print("➡️ بدأت محاولة تسجيل الدخول بالبصمة");

    var localization = AppLocalizations.of(context)!;

    try {
      // 1. تحقق هل الجهاز بيدعم البصمة
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      print("📱 الجهاز يدعم البصمة؟ $canCheckBiometrics");

      if (!canCheckBiometrics) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Biometric authentication is not available on this device.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 2. نفذ التحقق بالبصمة
      bool authenticated = await auth.authenticate(
        localizedReason: localization.authenticate_reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      print("🔐 تم التحقق بالبصمة؟ $authenticated");

      // 3. لو تم التحقق، نحاول نقرأ البيانات المحفوظة
      if (authenticated) {
        final email = await storage.read(key: 'email');
        final password = await storage.read(key: 'password');

        print("📨 Email from storage: $email");
        print("🔑 Password from storage: $password");

        if (email != null && password != null) {
          await signin(
            TextEditingController(text: email),
            TextEditingController(text: password),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('No saved credentials. Please login manually first.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("❌ Biometric Error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fingerprint error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var localization = AppLocalizations.of(context)!;
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20.0.w), // ✅ Responsive Padding
        child: SingleChildScrollView(
          padding: EdgeInsets.only(top: 60.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                WelcomePage(setLocale: widget.setLocale),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/bb.png'),
                            fit: BoxFit.cover,
                          ),
                          shape: BoxShape.circle,
                        ),
                        width: 50.w,
                        height: 50.h,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30.h),
              Text(
                localization.login,
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 5.h),
              Text(
                localization.welcome_back_message,
                style: TextStyle(fontSize: 16.sp, color: Colors.black54),
              ),
              SizedBox(height: 20.h),
              _buildTextField(localization.email, emailcontroller),
              SizedBox(height: 20.h),
              _buildPasswordField(localization.password, passwordcontroller),
              SizedBox(height: 10.h),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => ForgotPasswordPage(
                                setLocale: widget.setLocale,
                              )),
                    );
                  },
                  child: Text(
                    localization.forgot_password,
                    style: TextStyle(color: Color(0xFF88976C), fontSize: 16.sp),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Checkbox(
                    value: keepMeSignedIn,
                    activeColor: const Color(0xFF88976C),
                    onChanged: (value) {
                      setState(() {
                        keepMeSignedIn = value!;
                      });
                    },
                  ),
                  Text(
                    localization.keep_signed_in,
                    style: TextStyle(color: Colors.black54, fontSize: 16.sp),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(child: Divider(color: Color(0xFF88976C))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0.w),
                    child: Text(
                      localization.or_sign_in_with,
                      style: TextStyle(color: Colors.black54, fontSize: 14.sp),
                    ),
                  ),
                  Expanded(child: Divider(color: Color(0xFF88976C))),
                ],
              ),
              SizedBox(height: 20.h),
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _authenticate,
                      child: Column(
                        children: [
                          Text(
                            localization.fingerprint_signin,
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Image.asset(
                            'assets/fingerprint.png',
                            height: 60.h,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30.h),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF88976C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0.r),
                  ),
                  minimumSize: Size(double.infinity, 50.h),
                ),
                onPressed: () {
                  signin(emailcontroller, passwordcontroller);
                },
                child: Text(
                  localization.login,
                  style: TextStyle(fontSize: 18.sp, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

Future<void> signin(TextEditingController emailAddress,
    TextEditingController password) async {
  try {
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emailAddress.text,
      password: password.text,
    );

    final uid = credential.user!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('doctors')
        .doc(uid)
        .get();

    if (doc.exists) {
      final userType = doc['userType'];

      if (userType == 'mobile') {
        // ✅ خزّن الإيميل والباسورد بعد أول تسجيل دخول ناجح
        await storage.write(key: 'email', value: emailAddress.text);
        await storage.write(key: 'password', value: password.text);

        // ✅ التعامل مع Keep Me Signed In
        final prefs = await SharedPreferences.getInstance();
        if (keepMeSignedIn) {
          await prefs.setBool('keepMeSignedIn', true);
          await prefs.setString('uid', uid);
        } else {
          await prefs.remove('keepMeSignedIn');
          await prefs.remove('uid');
        }

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => HomePage(setLocale: widget.setLocale),
          ),
        );
      } else {
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('This account is not allowed on this platform.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      await FirebaseAuth.instance.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('This account does not exist.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } on FirebaseAuthException catch (error) {
    String errorMessage = '';

    switch (error.code) {
      case 'invalid-email':
        errorMessage = 'The email address is badly formatted.';
        break;
      case 'user-disabled':
        errorMessage = 'This user has been disabled.';
        break;
      case 'user-not-found':
        errorMessage = 'No user found for that email.';
        break;
      case 'wrong-password':
        errorMessage = 'Wrong password provided for that user.';
        break;
      case 'too-many-requests':
        errorMessage = 'Too many requests. Please try again later.';
        break;
      case 'operation-not-allowed':
        errorMessage = 'Signing in with Email and Password is not enabled.';
        break;
      case 'invalid-credential':
        errorMessage = 'Wrong password provided for that user.';
        break;
      default:
        errorMessage = error.message ?? 'An unexpected error occurred.';
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
      ),
    );
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('An unexpected error occurred.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Color(0xFF88976C),
          fontSize: 16.sp,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0.r),
          borderSide: const BorderSide(color: Color(0xFF88976C)),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: !isPasswordVisible,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Color(0xFF88976C),
          fontSize: 16.sp,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0.r),
          borderSide: const BorderSide(color: Color(0xFF88976C)),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: const Color(0xFF88976C),
          ),
          onPressed: () {
            setState(() {
              isPasswordVisible = !isPasswordVisible;
            });
          },
        ),
      ),
    );
  }
}

