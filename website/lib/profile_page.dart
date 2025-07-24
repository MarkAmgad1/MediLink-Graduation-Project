import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_page.dart';
import 'prescriptions_page.dart';
import 'settings_page.dart';
import 'login_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProfilePage extends StatefulWidget {
  final Function(Locale) setLocale; // ✅ لاستقبال اللغة وتحديثها

  ProfilePage({required this.setLocale}); // ✅ تمرير المتغير

  @override
  _ProfilePage createState() => _ProfilePage();
}

class _ProfilePage extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController licenseController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController managerNameController = TextEditingController();
  final TextEditingController managerPhoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool isSidebarCollapsed = true;
  bool isHovered = false;
  String pharmacyName = '';
  final _formKey = GlobalKey<FormState>();

  late AnimationController _controller;
  late Animation<double> _widthAnimation;

  bool isEditing = false;
  Map<String, dynamic>? pharmacyData;
  Map<String, TextEditingController> controllers = {};

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
  void initState() {
    super.initState();
    fetchPharmacyName();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _widthAnimation = Tween<double>(
      begin: 50.0,
      end: 300.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    fetchPharmacyData();
  }

  Future<void> fetchPharmacyData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc =
        await FirebaseFirestore.instance
            .collection('pharmacies')
            .doc(uid)
            .get();

    if (doc.exists) {
      setState(() {
        pharmacyData = doc.data();
        // Create controllers for each field
        pharmacyData?.forEach((key, value) {
          controllers[key] = TextEditingController(text: value.toString());
        });
      });
    }
  }

  Future<void> updatePharmacyProfile({
    required String name,
    required String license,
    required String phone,
    required String address,
    required String managerName,
    required String managerPhone,
    required String email,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('pharmacies').doc(uid).update({
      'name': name,
      'license': license,
      'phone': phone,
      'address': address,
      'managerName': managerName,
      'managerPhone': managerPhone,
      'email': email,
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("✅ Profile updated successfully")));

    await fetchPharmacyData(); // علشان نحدث الـ UI كمان
  }

  Future<void> saveChanges() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    Map<String, dynamic> updatedData = {};
    controllers.forEach((key, controller) {
      updatedData[key] = controller.text;
    });

    await FirebaseFirestore.instance
        .collection('pharmacies')
        .doc(uid)
        .set(updatedData, SetOptions(merge: true));

    await fetchPharmacyData(); // ✅ دي مهمة علشان تعمل refresh حقيقي من Firestore

    setState(() {
      isEditing = false;
    });
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: IconButton(
                    icon: Icon(
                      isSidebarCollapsed
                          ? Icons.keyboard_double_arrow_right_rounded
                          : Icons.keyboard_double_arrow_left_rounded,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 394,
                        height: 67,
                        child: Text(
                          localization.profile,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 48,
                            fontWeight: FontWeight.w600,
                            height: 67.2 / 48,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            FontAwesomeIcons.hospital,
                            color: Colors.black,
                            size: 24,
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
                  Expanded(
                    child: Form(
                      key: _formKey, // ← ده اللي عرفناه فوق
                      child: ListView(
                        children: [
                          _buildProfileRow(
                            label: localization.pharmacyName,
                            key: 'name',
                            icon: FontAwesomeIcons.pills,
                            helperText:
                                "Only letters are allowed. Example: El Seha Pharmacy",
                          ),
                          Divider(color: Color.fromRGBO(136, 151, 108, 1)),
                          _buildProfileRow(
                            label: localization.licenseNumber,
                            key: 'license',
                            icon: FontAwesomeIcons.fileAlt,
                            helperText:
                                "Provide a valid license number (alphanumeric allowed)",
                          ),
                          Divider(color: Color.fromRGBO(136, 151, 108, 1)),
                          _buildProfileRow(
                            label: localization.contactInformation,
                            key: 'phone',
                            icon: FontAwesomeIcons.phone,
                            helperText:
                                "Use Egyptian format (e.g., 01012345678)",
                          ),
                          Divider(color: Color.fromRGBO(136, 151, 108, 1)),
                          _buildProfileRow(
                            label: localization.address,
                            key: 'address',
                            icon: FontAwesomeIcons.mapMarkerAlt,
                            helperText:
                                "Include street, city or any clear identifier",
                          ),
                          Divider(color: Color.fromRGBO(136, 151, 108, 1)),
                          _buildProfileRow(
                            label: localization.managerName,
                            key: 'managerName',
                            icon: FontAwesomeIcons.userTie,
                            helperText:
                                "Full name of the manager (letters only)",
                          ),
                          Divider(color: Color.fromRGBO(136, 151, 108, 1)),
                          _buildProfileRow(
                            label: localization.managerPhone,
                            key: 'managerPhone',
                            icon: FontAwesomeIcons.mobileAlt,
                            helperText:
                                "Mobile number of the manager (e.g., 010...)",
                          ),
                          Divider(color: Color.fromRGBO(136, 151, 108, 1)),
                          _buildProfileRow(
                            label: localization.managerEmail,
                            key: 'email',
                            icon: FontAwesomeIcons.envelope,
                            helperText:
                                "Enter a valid email like manager@example.com",
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: GestureDetector(
                      onTap: () async {
                        if (isEditing) {
                          if (_formKey.currentState!.validate()) {
                            await saveChanges();
                          }
                        } else {
                          setState(() {
                            isEditing = true;
                          });
                        }
                      },

                      child: MouseRegion(
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
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          width: 125,
                          height: 40,
                          decoration: BoxDecoration(
                            color:
                                isHovered
                                    ? Color.fromRGBO(136, 151, 108, 1)
                                    : Color.fromRGBO(247, 247, 247, 1),
                            borderRadius: BorderRadius.circular(17),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO(136, 151, 108, 1),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              isEditing
                                  ? localization.save
                                  : localization.editProfile,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color.fromRGBO(0, 0, 0, 0.7),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow({
    required String label,
    required String key,
    required IconData icon,
    String? helperText,
  }) {
    final controller = controllers.putIfAbsent(
      key,
      () => TextEditingController(),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.black),
          SizedBox(width: 10),
          Expanded(
            child:
                isEditing
                    ? TextFormField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: label,
                        helperText: helperText,
                        helperStyle: TextStyle(color: Colors.red),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'This field is required';
                        }

                        // 🟢 تحقق مخصص
                        if (key == 'email' &&
                            !RegExp(
                              r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$",
                            ).hasMatch(value)) {
                          return 'Enter a valid email address';
                        }

                        if (key == 'phone' || key == 'managerPhone') {
                          if (!RegExp(r"^01[0125][0-9]{8}$").hasMatch(value)) {
                            return 'Enter a valid Egyptian phone number';
                          }
                        }

                        if (key == 'name' || key == 'managerName') {
                          if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(value)) {
                            return 'Only letters are allowed';
                          }
                        }

                        return null;
                      },
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(controller.text, style: TextStyle(fontSize: 18)),
                      ],
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
        onTap: () => widget.onTap(),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color:
                isHovered
                    ? const Color.fromARGB(255, 255, 255, 255)
                    : Colors.transparent,
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
