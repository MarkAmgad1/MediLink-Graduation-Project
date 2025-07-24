import 'package:flutter/material.dart';
import 'package:flutter_application_1/DocInfo/login.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // ✅ أضفنا ScreenUtil

class SettingsPage extends StatefulWidget {
  final Function(Locale) setLocale;
  const SettingsPage({super.key, required this.setLocale});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String selectedLanguage = "English"; // اللغة الافتراضية

  @override
  Widget build(BuildContext context) {
    var localization = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/settingbg.png'),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.0.w), // ✅ Responsive padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 60.h),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Image.asset(
                        'assets/bb.png',
                        height: 45.h,
                        width: 45.w,
                      ),
                    ),
                    SizedBox(width: 15.w),
                    Text(
                      localization.settings,
                      style: TextStyle(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF88976C),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 100.h),
                Expanded(
                  child: ListView(
                    children: [
                      _buildSettingsItem(
                        imagePath: 'assets/language_icon.png',
                        title: localization.language,
                        onTap: () {
                          _showLanguageDialog(context,
                              setLocale: widget.setLocale);
                        },
                      ),
                      _buildSettingsItem(
                        imagePath: 'assets/profile_icon.png',
                        title: localization.profile,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => DoctorProfilePage(
                                setLocale: widget.setLocale,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildSettingsItem(
                        imagePath: 'assets/change_password_icon.png',
                        title: localization.change_password,
                        onTap: () {
                          _showChangePasswordDialog(context);
                        },
                      ),
                      _buildSettingsItem(
                        imagePath: 'assets/help_icon.png',
                        title: localization.help,
                        onTap: () {
                          showAboutUsDialog(context);
                        },
                      ),
                      _buildSettingsItem(
                        imagePath: 'assets/logout_icon.png',
                        title: localization.logout,
                        onTap: () async {
                          // ❌ امسح البيانات المحفوظة
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('keepMeSignedIn');
                          await prefs.remove('uid');

                          // ❌ امسح بيانات البصمة (اختياري لو بتستخدم التخزين الآمن)
                          const storage = FlutterSecureStorage();
                          await storage.delete(key: 'email');
                          await storage.delete(key: 'password');

                          // ❌ سجّل خروج من Firebase
                          await FirebaseAuth.instance.signOut();

                          // ✅ رجّع المستخدم لصفحة تسجيل الدخول
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) =>
                                  LoginPage(setLocale: widget.setLocale),
                            ),
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showAboutUsDialog(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            local.aboutUsTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${local.aboutUsDescription1}\n"),
                Text(
                  local.teamMembersTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text("• ${local.memberMark}"),
                Text("• ${local.memberMarwan}"),
                Text("• ${local.memberSamir}"),
                Text("• ${local.memberMohamed}"),
                Text("• ${local.memberJoycie}"),
                Text("• ${local.memberAbdelghany}"),
                const SizedBox(height: 12),
                Text(local.aboutUsDescription2),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                local.close,
                style: const TextStyle(color: Color.fromRGBO(136, 151, 108, 1)),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingsItem({
    required String imagePath,
    required String title,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Image.asset(
            imagePath,
            height: 50.h,
            width: 50.w,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 20.sp,
              color: Colors.black,
            ),
          ),
          onTap: onTap,
        ),
        Divider(
          color: const Color(0xFF88976C),
          thickness: 0.5.h,
        ),
      ],
    );
  }

  void _showLanguageDialog(BuildContext context, {required setLocale}) {
    var localization = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            localization.change_language,
            style: TextStyle(
              fontSize: 18.sp,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                widget.setLocale(const Locale('en'));
                Navigator.pop(context);
              },
              child: const Text(
                "English",
                style: TextStyle(color: Color.fromRGBO(136, 151, 108, 1)),
              ),
            ),
            TextButton(
              onPressed: () {
                widget.setLocale(const Locale('ar'));
                Navigator.pop(context);
              },
              child: const Text(
                "العربية",
                style: TextStyle(color: Color.fromRGBO(136, 151, 108, 1)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final TextEditingController passwordController = TextEditingController();
    final localization = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            localization.change_password,
            style: TextStyle(fontSize: 18.sp),
          ),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: localization.enter_new_password,
              labelStyle: TextStyle(color: Color.fromRGBO(136, 151, 108, 1)), // لون التسمية
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color: Color.fromRGBO(136, 151, 108, 1)), // لون الخط عند التركيز
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Color.fromRGBO(136, 151, 108, 1)), // لون الخط العادي
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                localization.cancel,
                style: TextStyle(color: Color.fromRGBO(136, 151, 108, 1)),
              ),
            ),
            TextButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                try {
                  await user?.updatePassword(passwordController.text.trim());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(localization.password_updated_successfully),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(localization.error_changing_password),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(
                localization.save,
                style: TextStyle(color: Color.fromRGBO(136, 151, 108, 1)),
              ),
            ),
          ],
        );
      },
    );
  }
}
