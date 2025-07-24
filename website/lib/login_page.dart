import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/forgetpassword.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sign_up_page.dart';
import 'dashboard_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  final Function(Locale) setLocale;

  const LoginPage({super.key, required this.setLocale});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool rememberMe = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkSavedLogin();
  }

  @override
  Widget build(BuildContext context) {
    var localization = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F5),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Language Switcher
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: DropdownButton<String>(
                    value: Localizations.localeOf(context).languageCode,
                    onChanged: (String? languageCode) {
                      if (languageCode != null) {
                        widget.setLocale(Locale(languageCode));
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: "en", child: Text("English")),
                      DropdownMenuItem(value: "ar", child: Text("العربية")),
                    ],
                  ),
                ),
                Container(
                  color: const Color(0xFFF3FAED),
                  padding: const EdgeInsets.all(50),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/Logo.png', height: 120),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(50),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        localization.welcomeBack,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        localization.enterDetails,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(localization.username, emailController),
                      _buildTextField(
                        localization.password,
                        passwordController,
                        obscureText: true,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: rememberMe,
                                onChanged: (bool? value) {
                                  setState(() {
                                    rememberMe = value ?? false;
                                  });
                                },
                              ),
                              Text(localization.rememberMe),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ForgetPasswordPage(),
                                ),
                              );
                            },

                            child: Text(
                              localization.forgotPassword,
                              style: const TextStyle(
                                color: Color(0xFF88976C),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            // 1. تسجيل الدخول
                            UserCredential credential = await FirebaseAuth
                                .instance
                                .signInWithEmailAndPassword(
                                  email: emailController.text.trim(),
                                  password: passwordController.text.trim(),
                                );

                            final uid = credential.user!.uid;

                            // 2. قراءة بيانات المستخدم من Firestore
                            final doc =
                                await FirebaseFirestore.instance
                                    .collection('pharmacies')
                                    .doc(uid)
                                    .get();

                            // 3. التأكد من نوع الحساب
                            if (doc.exists &&
                                doc.data()!['userType'] == 'web') {
                              if (rememberMe) {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setString('user_uid', uid);
                              }

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => DashboardPage(
                                        setLocale: widget.setLocale,
                                      ),
                                ),
                              );
                            } else {
                              await FirebaseAuth.instance
                                  .signOut(); // يسجله خروج
                              showDialog(
                                context: context,
                                builder:
                                    (_) => AlertDialog(
                                      title: Text('Unauthorized'),
                                      content: Text(
                                        'This account is not allowed on this platform.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(context),
                                          child: Text('OK'),
                                        ),
                                      ],
                                    ),
                              );
                            }
                          } on FirebaseAuthException catch (e) {
                            String errorMessage = '';
                            if (e.code == 'user-not-found') {
                              errorMessage = localization.userNotFound;
                            } else if (e.code == 'wrong-password') {
                              errorMessage = localization.wrongPassword;
                            } else {
                              errorMessage = localization.loginFailed;
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Unexpected error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF88976C),
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 50,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          localization.login,
                          style: const TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        SignUpPage(setLocale: widget.setLocale),
                              ),
                            );
                          },
                          child: Text.rich(
                            TextSpan(
                              text: localization.dontHaveAccount,
                              style: const TextStyle(fontSize: 16),
                              children: [
                                TextSpan(
                                  text: localization.signUp,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF88976C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUid = prefs.getString('user_uid');

    if (savedUid != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('pharmacies')
              .doc(savedUid)
              .get();

      if (doc.exists && doc.data()!['userType'] == 'web') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardPage(setLocale: widget.setLocale),
          ),
        );
      } else {
        await prefs.remove('user_uid'); // لو المستخدم مش web امسحه
      }
    }
  }

  Widget _buildTextField(
    String hint,
    TextEditingController controller, {
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
