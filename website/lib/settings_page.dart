import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/aboutus_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_page.dart';
import 'prescriptions_page.dart';
import 'login_page.dart';
import 'Profile_Page.dart';
import 'change_password_Page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'aboutus_page.dart';

class SettingsPage extends StatefulWidget {
  final Function(Locale) setLocale;
  SettingsPage({required this.setLocale});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isSidebarCollapsed = true; // Default: Sidebar is collapsed
  bool isProfileHovered = false;
  bool isChangePasswordHovered = false;
  bool isHelpHovered = false;
  String pharmacyName = '';

  @override
  void initState() {
    super.initState();
    fetchPharmacyName();
  }

  Future<void> fetchPharmacyName() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc =
        await FirebaseFirestore.instance
            .collection('pharmacies')
            .doc(uid)
            .get();

    if (doc.exists && doc.data()!.containsKey('name')) {
      setState(() {
        pharmacyName = doc['name'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var localization = AppLocalizations.of(context)!;
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: isSidebarCollapsed ? 70 : 250,
            color: Color(0xFFF3FAED),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo in the center
                Column(
                  children: [
                    SizedBox(height: 20),
                    Center(
                      child: Image.asset(
                        'assets/Logo.png',
                        height: isSidebarCollapsed ? 50 : 90,
                      ),
                    ),
                    if (!isSidebarCollapsed)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text(
                            'MediLink',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    SizedBox(height: isSidebarCollapsed ? 100 : 50),
                    // Menu Items
                    SidebarItem(
                      icon: FontAwesomeIcons.house,
                      label: localization.dashboard,
                      isCollapsed: isSidebarCollapsed,
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => DashboardPage(
                                    setLocale: widget.setLocale,
                                  ),
                            ),
                          ),
                    ),
                    SizedBox(height: isSidebarCollapsed ? 50 : 30),
                    SidebarItem(
                      icon: FontAwesomeIcons.prescriptionBottle,
                      label: localization.prescriptions,
                      isCollapsed: isSidebarCollapsed,
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => PrescriptionsPage(
                                    setLocale: widget.setLocale,
                                  ),
                            ),
                          ),
                    ),
                    SizedBox(height: isSidebarCollapsed ? 50 : 30),
                    SidebarItem(
                      icon: FontAwesomeIcons.gear,
                      label: localization.settings,
                      isCollapsed: isSidebarCollapsed,
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      SettingsPage(setLocale: widget.setLocale),
                            ),
                          ),
                    ),
                    SizedBox(height: isSidebarCollapsed ? 50 : 30),
                    SidebarItem(
                      icon: FontAwesomeIcons.rightFromBracket,
                      label: localization.logout,
                      isCollapsed: isSidebarCollapsed,
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('user_uid');
                        // ← تسجيل خروج من Firebase
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    LoginPage(setLocale: widget.setLocale),
                          ),
                          (route) => false, // ← يمنع الرجوع بالـ back button
                        );
                      },
                    ),
                  ],
                ),
                // Collapse Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: IconButton(
                    icon: Icon(
                      isSidebarCollapsed
                          ? Icons
                              .keyboard_double_arrow_right_rounded // Collapsed icon
                          : Icons
                              .keyboard_double_arrow_left_rounded, // Expanded icon
                      size: 30,
                    ),
                    onPressed: () {
                      setState(() {
                        isSidebarCollapsed = !isSidebarCollapsed;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Pharmacy Name and Hospital Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            FontAwesomeIcons.hospital,
                            color: Colors.black,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            pharmacyName.isNotEmpty
                                ? pharmacyName
                                : 'Loading...',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.globe,
                        color: Colors.black,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Choose Language:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      RadioListTile(
                        value: Locale('en'),
                        groupValue: Localizations.localeOf(context),
                        title: Text(localization.english),
                        activeColor: Color.fromRGBO(136, 151, 108, 1.0),
                        onChanged: (value) {
                          widget.setLocale(Locale('en'));
                        },
                      ),
                      RadioListTile(
                        value: Locale('ar'),
                        groupValue: Localizations.localeOf(context),
                        title: Text(localization.arabic),
                        activeColor: Color.fromRGBO(136, 151, 108, 1.0),
                        onChanged: (value) {
                          widget.setLocale(Locale('ar'));
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Divider(
                    color: Color.fromRGBO(136, 151, 108, 1.0),
                    thickness: 1,
                  ),
                  // Profile Option
                  SizedBox(height: 15),
                  MouseRegion(
                    onEnter: (_) => setState(() => isProfileHovered = true),
                    onExit: (_) => setState(() => isProfileHovered = false),
                    child: GestureDetector(
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      ProfilePage(setLocale: widget.setLocale),
                            ),
                          ),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 100),
                        width: 382,
                        height: 57,
                        decoration: BoxDecoration(
                          color:
                              isProfileHovered
                                  ? Colors.grey.shade300
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(17),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 15),
                            Icon(
                              FontAwesomeIcons.user,
                              color: Colors.black,
                              size: 24,
                            ),
                            SizedBox(width: 15),
                            Text(
                              localization.profile,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 39,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                                height: 48.41 / 40,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  Divider(color: Color.fromRGBO(108, 116, 93, 1), thickness: 1),
                  // Change Password Option
                  SizedBox(height: 15),
                  MouseRegion(
                    onEnter:
                        (_) => setState(() => isChangePasswordHovered = true),
                    onExit:
                        (_) => setState(() => isChangePasswordHovered = false),
                    child: GestureDetector(
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChangePasswordPage(),
                            ),
                          ),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 100),
                        width: 382,
                        height: 57,
                        decoration: BoxDecoration(
                          color:
                              isChangePasswordHovered
                                  ? Colors.grey.shade300
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(17),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 15),
                            Icon(
                              FontAwesomeIcons.key,
                              color: Colors.black,
                              size: 24,
                            ),
                            SizedBox(width: 15),
                            Text(
                              localization.changePassword,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 39,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                                height: 48.41 / 40,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  Divider(
                    color: Color.fromRGBO(136, 151, 108, 1.0),
                    thickness: 1,
                  ),

                  // Language Select
                  // Dark Mode Option
                  SizedBox(height: 15),

                  // Help Option
                  SizedBox(height: 15),
                  MouseRegion(
                    onEnter: (_) => setState(() => isHelpHovered = true),
                    onExit: (_) => setState(() => isHelpHovered = false),
                    child: GestureDetector(
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AboutUsPage(setLocale: widget.setLocale)),
                          ),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 100),
                        width: 382,
                        height: 57,
                        decoration: BoxDecoration(
                          color:
                              isHelpHovered
                                  ? Colors.grey.shade300
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(17),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 15),
                            Icon(
                              FontAwesomeIcons.questionCircle,
                              color: Colors.black,
                              size: 24,
                            ),
                            SizedBox(width: 15),
                            Text(
                              localization.aboutUs,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 39,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                                height: 48.41 / 40,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  Divider(
                    color: Color.fromRGBO(136, 151, 108, 1.0),
                    thickness: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final Function onTap;
  final bool isCollapsed;

  SidebarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isCollapsed,
  });

  @override
  _SidebarItemState createState() => _SidebarItemState();
}

class _SidebarItemState extends State<SidebarItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          isHovered = false;
        });
      },
      child: GestureDetector(
        onTap: () => widget.onTap(), // تفعيل النقر
        child: AnimatedContainer(
          duration: Duration(milliseconds: 100),
          constraints: BoxConstraints(
            minWidth: 70,
            minHeight: 50,
          ), // تحديد الحد الأدنى للحجم
          decoration: BoxDecoration(
            color: isHovered ? Colors.grey.shade300 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow:
                isHovered
                    ? [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ]
                    : [],
          ),
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Row(
            mainAxisAlignment:
                widget.isCollapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
            children: [
              Icon(
                widget.icon,
                size: widget.isCollapsed ? 25 : 35,
                color: Colors.black,
              ),
              if (!widget.isCollapsed) ...[
                SizedBox(width: 15),
                Text(
                  widget.label,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
