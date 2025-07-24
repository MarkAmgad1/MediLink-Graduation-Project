// ignore_for_file: unused_field, prefer_const_constructors

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_page.dart';
import 'prescriptions_page.dart';
import 'settings_page.dart';
import 'login_page.dart';
import 'view_details_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class OtpPage extends StatefulWidget {
  final Function(Locale) setLocale;
  final String prescriptionId;
  final Map<String, dynamic> selectedMedicine;

  OtpPage({
    required this.setLocale,
    required this.prescriptionId,
    required this.selectedMedicine,
  });

  @override
  _OtpPageState createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> with SingleTickerProviderStateMixin {
  bool isSidebarCollapsed = true;
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  final int otpLength = 6;
  List<TextEditingController> _otpControllers = [];
  List<FocusNode> _otpFocusNodes = [];
  bool isVerified = false;
  int _start = 60;
  Timer? _countdownTimer;
  String? patientPhone;
  bool isLoadingDone = false;
  bool isValidated = false;
  late String patientNationalId;
  late Map<String, dynamic> prescriptionData;
  String pharmacyName = '';
  bool isVerifying = false;

  String normalizePhone(String phone) {
    if (phone.startsWith('0')) {
      return '+20${phone.substring(1)}';
    } else if (!phone.startsWith('+')) {
      return '+$phone';
    }
    return phone;
  }

  Future<void> sendOtpToServer(String phone) async {
    final url = Uri.parse(
      'https://us-central1-medilink-d69f4.cloudfunctions.net/sendOtp',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );

    if (response.statusCode == 200) {
      print('✅ OTP sent');
    } else {
      print('❌ Failed to send OTP: ${response.body}');
    }
  }

  Future<void> handleSuccess() async {
    final now = DateTime.now();

    final int duration =
        int.tryParse(widget.selectedMedicine['duration']?.toString() ?? '0') ??
        0;

    int daysLate = 0;
    String status = 'ontime';

    // ⏱️ حساب التأخير (لو فيه زيارات سابقة)
    final previousVisits = List<Map<String, dynamic>>.from(
      (widget.selectedMedicine['visitHistory'] ?? []).map(
        (v) => Map<String, dynamic>.from(v),
      ),
    );

    if (previousVisits.isNotEmpty) {
      final lastVisit = previousVisits.last;
      final nextDueDateStr = lastVisit['nextDueDate'];
      final nextDueDate = DateFormat('dd-MM-yyyy').parse(nextDueDateStr);

      final difference = now.difference(nextDueDate).inDays;
      if (difference > 0) {
        daysLate = difference;
        status = 'late';
      }
    }

    final newVisit = {
      'visitDate': DateFormat('dd-MM-yyyy').format(now),
      'nextDueDate': DateFormat(
        'dd-MM-yyyy',
      ).format(now.add(Duration(days: duration))),
      'daysLate': daysLate,
      'status': status,
    };

    // ✅ تحديث الزيارة في الدواء المحدد
    final medDocRef = FirebaseFirestore.instance
        .collection('prescriptions')
        .doc(widget.prescriptionId)
        .collection('medicines')
        .doc(
          widget.selectedMedicine['id'],
        ); // ← لازم يكون موجود في selectedMedicine

    await medDocRef.update({
      'visitHistory': FieldValue.arrayUnion([newVisit]),
      'status': 'processed',
      'dispensedAt': FieldValue.serverTimestamp(),
      'pharmacyId': FirebaseAuth.instance.currentUser!.uid,
    });

    // ✅ تحديث عدّاد الصيدلية
    final pharmacyRef = FirebaseFirestore.instance
        .collection('pharmacies')
        .doc(FirebaseAuth.instance.currentUser!.uid);

    await pharmacyRef.update({'completedCount': FieldValue.increment(1)});

    // ✅ إرسال HL7
    await sendHL7Message(
      patientId: patientNationalId,
      name: prescriptionData['patientName'] ?? 'Unknown',
      phonenumber: prescriptionData['phone'] ?? 'Unknown',
      status: 'processed',
    );

    // ✅ رجوع لـ ViewDetailsPage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => ViewDetailsPage(
              setLocale: widget.setLocale,
              prescriptionId: widget.prescriptionId,
            ),
      ),
    );
  }

  Future<void> sendHL7Message({
    required String patientId,
    required String name,
    required String phonenumber,
    required String status,
  }) async {
    final url = Uri.parse('http://192.168.1.8:8000/send-hl7');
    // غير IP هنا لو شغال Locally

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({}),
      );

      if (response.statusCode == 200) {
        print('✅ HL7 message sent successfully!');
        print('Response: ${response.body}');
      } else {
        print('❌ Failed to send HL7 message: ${response.body}');
      }
    } catch (e) {
      print('❌ Error sending HL7 message: $e');
    }
  }

  Future<void> fetchPharmacyName() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc =
        await FirebaseFirestore.instance
            .collection('pharmacies')
            .doc(uid)
            .get();
    if (doc.exists) {
      setState(() {
        pharmacyName = doc['name'] ?? 'Pharmacy';
      });
    }
  }

  Future<void> validateSelectedMedicineBeforeOTP() async {
    final now = DateTime.now();
    final visitHistory = List<Map<String, dynamic>>.from(
      (widget.selectedMedicine['visitHistory'] ?? []).map(
        (v) => Map<String, dynamic>.from(v),
      ),
    );

    final duration =
        int.tryParse(widget.selectedMedicine['duration']?.toString() ?? '0') ??
        0;

    if (visitHistory.isNotEmpty) {
      final lastVisit = visitHistory.last;
      final lastVisitDate = DateFormat(
        'dd-MM-yyyy',
      ).parse(lastVisit['visitDate']);
      final nextAllowedDate = lastVisitDate.add(Duration(days: duration));

      if (now.isBefore(nextAllowedDate)) {
        final nextDate = DateFormat('dd-MM-yyyy').format(nextAllowedDate);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '⛔ Patient came before the allowed refill date ($nextDate)',
              ),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }
    }

    final doc =
        await FirebaseFirestore.instance
            .collection('prescriptions')
            .doc(widget.prescriptionId)
            .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        patientPhone = data['phone'];
        patientNationalId = data['nationalId'];
        prescriptionData = data;
        isValidated = true;
        isLoadingDone = true;
      });
      _countdownTimer?.cancel();
      _start = 60;
      startCountdown();

      await sendOtpToServer(patientPhone!);
    }
  }

  void startCountdown() {
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_start == 0) {
        timer.cancel();
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();

    _otpControllers = List.generate(otpLength, (_) => TextEditingController());
    _otpFocusNodes = List.generate(otpLength, (_) => FocusNode());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      validateSelectedMedicineBeforeOTP();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _controller.dispose();
    _otpControllers.forEach((controller) => controller.dispose());
    _otpFocusNodes.forEach((node) => node.dispose());
    super.dispose();
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // بناء خانات OTP بحيث يتم التبديل تلقائيًا للخانة التالية عند إدخال رقم
  Widget buildOtpFields() {
    List<Widget> fields = [];
    for (int i = 0; i < otpLength; i++) {
      fields.add(
        Container(
          width: 50,
          height: 50,
          margin: EdgeInsets.symmetric(horizontal: 5),
          child: TextField(
            controller: _otpControllers[i],
            focusNode: _otpFocusNodes[i],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            decoration: InputDecoration(
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              if (value.length == 1 && i < otpLength - 1) {
                FocusScope.of(context).requestFocus(_otpFocusNodes[i + 1]);
              }
              if (value.isEmpty && i > 0) {
                FocusScope.of(context).requestFocus(_otpFocusNodes[i - 1]);
              }
            },
          ),
        ),
      );
    }
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: fields);
  }

  // زر Verify/Confirmed مع النص الأبيض
  Widget buildVerifyButton() {
    var localization = AppLocalizations.of(context)!;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isVerified ? Colors.green : Color.fromRGBO(136, 151, 108, 1),
          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        ),
        onPressed: () async {
          if (isVerifying) return; // لمنع الضغط المكرر

          setState(() {
            isVerifying = true;
          });

          String enteredOtp = _otpControllers.map((c) => c.text).join();

          try {
            String normalizedPhone = normalizePhone(patientPhone!);
            print('📞 patientPhone: $patientPhone');
            print('📞 normalizedPhone: $normalizedPhone');
            final otpDoc =
                await FirebaseFirestore.instance
                    .collection('otps')
                    .doc(normalizePhone(patientPhone!))
                    .get();

            if (otpDoc.exists) {
              final data = otpDoc.data()!;
              final storedOtp = data['otp'];
              final createdAt = (data['createdAt'] as Timestamp).toDate();
              final now = DateTime.now();

              // تحقق من صحة الكود
              if (enteredOtp == storedOtp) {
                await FirebaseFirestore.instance
                    .collection('otps')
                    .doc(normalizePhone(patientPhone!))
                    .delete();

                setState(() {
                  isVerified = true; // ✅ عدل القيمة فعليًا
                });

                await handleSuccess(); // ← تنقل بعد النجاح
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("❌ Incorrect or Expired OTP")),
                );
              }
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("❌ OTP not found")));
            }
          } catch (e) {
            print('Error verifying OTP: $e');
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("❌ Error verifying OTP")));
          } finally {
            if (mounted) {
              setState(() {
                isVerifying = false;
              });
            }
          }
        },
        child:
            isVerifying
                ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
                : Text(
                  isVerified ? localization.confirm : localization.verify,
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
      ),
    );
  }

  // زر Done باللون الرمادي (قريب من الأبيض) مع ظل بارز، في أسفل اليمين
  Widget buildDoneButton() {
    var localization = AppLocalizations.of(context)!;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ViewDetailsPage(
                    setLocale: widget.setLocale,
                    prescriptionId: widget.prescriptionId,
                  ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          child: Text(
            localization.done,
            style: TextStyle(fontSize: 18, color: Colors.black),
          ),
        ),
      ),
    );
  }

  // دالة لبناء عناصر الشريط الجانبي مع التصفح للصفحات المطلوبة
  Widget buildSidebarItem(IconData icon, String label, Widget destination) {
    return SidebarItem(
      icon: icon,
      label: label,
      isCollapsed: isSidebarCollapsed,
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var localization = AppLocalizations.of(context)!;
    if (!isLoadingDone) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                    buildSidebarItem(
                      FontAwesomeIcons.house,
                      localization.dashboard,
                      DashboardPage(setLocale: widget.setLocale),
                    ),
                    SizedBox(height: isSidebarCollapsed ? 50 : 30),
                    buildSidebarItem(
                      FontAwesomeIcons.prescriptionBottle,
                      localization.prescriptions,
                      PrescriptionsPage(setLocale: widget.setLocale),
                    ),
                    SizedBox(height: isSidebarCollapsed ? 50 : 30),
                    buildSidebarItem(
                      FontAwesomeIcons.gear,
                      localization.settings,
                      SettingsPage(setLocale: widget.setLocale),
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
          Expanded(
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // عنوان OTP Verification والشعار في الأعلى
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localization.otpVerification,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
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
                  // توسيط محتوى OTP
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // النص التوضيحي
                          Text(
                            'Enter the OTP sent to ****${patientPhone?.substring(patientPhone!.length - 3) ?? '---'}',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20, color: Colors.black),
                          ),

                          SizedBox(height: 20),
                          // حقول إدخال OTP
                          buildOtpFields(),
                          SizedBox(height: 20),
                          // Send code again مع التايمر التنازلي
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                localization.sendCodeAgain,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                formatTime(_start),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          // زر Verify
                          buildVerifyButton(),
                        ],
                      ),
                    ),
                  ),
                  // زر Done في أسفل اليمين
                  Align(
                    alignment: Alignment.bottomRight,
                    child: buildDoneButton(),
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
