// ignore_for_file: prefer_const_constructors

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dashboard_page.dart';
import 'prescriptions_page.dart';
import 'settings_page.dart';
import 'login_page.dart';
import 'otp_page.dart';

class ViewDetailsPage extends StatefulWidget {
  final Function(Locale) setLocale; // Add setLocale parameter
  final String prescriptionId;
  ViewDetailsPage({required this.setLocale, required this.prescriptionId});
  @override
  _ViewDetailsPageState createState() => _ViewDetailsPageState();
}

class _ViewDetailsPageState extends State<ViewDetailsPage> {
  bool isSidebarCollapsed = true;
  String pharmacyName = '';
  Map<String, dynamic>? prescriptionData;
  List<Map<String, dynamic>> visitHistory = [];
  String? surveyStatus;
  double? surveyScore;
  List<Map<String, dynamic>> allMedicines = [];
  List<List<Map<String, dynamic>>> allVisitHistories = [];
  PageController _pageController = PageController();
  int currentPage = 0;
  List<String> medicineIds = [];

  @override
  void initState() {
    super.initState();
    fetchPrescriptionDetails();
    fetchPharmacyName();
  }

  Future<void> fetchSurveyStatus(String nationalId, String medicineName) async {
    final docId = '${nationalId}_$medicineName';
    final doc =
        await FirebaseFirestore.instance
            .collection('survey_results')
            .doc(docId)
            .get();

    if (doc.exists) {
      final data = doc.data();
      setState(() {
        surveyStatus = data?['status'];
        surveyScore = data?['score']?.toDouble();
      });
    } else {
      setState(() {
        surveyStatus = null;
        surveyScore = null;
      });
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
        pharmacyName = doc['name']; // تأكد إن الحقل اسمه 'name' في Firestore
      });
    }
  }

  Future<void> fetchPrescriptionDetails() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('prescriptions')
            .doc(widget.prescriptionId)
            .get();

    if (doc.exists) {
      final data = doc.data()!;
      final snapshot =
          await FirebaseFirestore.instance
              .collection('prescriptions')
              .doc(widget.prescriptionId)
              .collection('medicines')
              .get();

      List<Map<String, dynamic>> meds = [];
      List<List<Map<String, dynamic>>> visitHistories = [];
      List<String> ids = [];

      for (var medDoc in snapshot.docs) {
        final med = medDoc.data();
        final history = List<Map<String, dynamic>>.from(
          (med['visitHistory'] ?? []).map((v) => Map<String, dynamic>.from(v)),
        );

        meds.add(med);
        visitHistories.add(history);
        ids.add(medDoc.id);
      }

      setState(() {
        prescriptionData = data;
        allMedicines = meds;
        allVisitHistories = visitHistories;
        medicineIds = ids; // ✅ حفظ ID
      });

      if (data.containsKey('nationalId') &&
          data['nationalId'] != null &&
          meds.isNotEmpty) {
        await fetchSurveyStatus(
          data['nationalId'],
          meds[0]['name'],
        ); // ✅ أول دواء كبداية
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String translateSurveyStatus(
      String? status,
      AppLocalizations localization,
    ) {
      switch (status) {
        case "needed":
          return localization.surveyNeeded;
        case "maybe":
          return localization.surveyMaybe;
        case "not_needed":
          return localization.surveyNotNeeded;
        case "none":
          return localization.surveyNone;
        default:
          return localization.noSurvey;
      }
    }

    var localization = AppLocalizations.of(context)!;
    if (allMedicines.isEmpty ||
        allVisitHistories.isEmpty ||
        medicineIds.isEmpty) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final selectedMedicine = allMedicines[currentPage];
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Section (unchanged)
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: isSidebarCollapsed ? 70 : 250,
            color: Color(0xFFF3FAED),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo & Menu Items
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
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      LoginPage(setLocale: widget.setLocale),
                            ),
                          ),
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
          // Main Content Section
          Expanded(
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header: "View Details" on the left and Hospital Icon + "El Ezaby" on the right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localization.viewDetails,
                        style: TextStyle(
                          fontSize: 28,
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
                  SizedBox(height: 30),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double screenWidth = constraints.maxWidth;
                        return SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Column(
                            children: [
                              // 👇 معلومات المريض داخل Container أطول
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF3FAED),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      localization.patientInfo,
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                          0.65,

                                      child: PageView.builder(
                                        controller: _pageController,
                                        onPageChanged: (index) {
                                          setState(() {
                                            currentPage = index;
                                          });
                                          // 🟢 نحدث حالة السيرڤي بناء على الدواء الجديد
                                          final nationalId =
                                              prescriptionData?['nationalId'];
                                          final medName =
                                              allMedicines[index]['name'];
                                          if (nationalId != null &&
                                              medName != null) {
                                            fetchSurveyStatus(
                                              nationalId,
                                              medName,
                                            );
                                          }
                                        },
                                        itemCount: allMedicines.length,
                                        itemBuilder: (context, index) {
                                          final med = allMedicines[index];
                                          final visits =
                                              allVisitHistories[index];

                                          return Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: SingleChildScrollView(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      infoText(
                                                        localization.name,
                                                        prescriptionData?['patientName'],
                                                      ),
                                                      infoText(
                                                        localization.nationalID,
                                                        prescriptionData?['nationalId'],
                                                      ),
                                                      infoText(
                                                        localization
                                                            .phoneNumber,
                                                        prescriptionData?['phone'],
                                                      ),
                                                      infoText(
                                                        localization
                                                            .medicineName,
                                                        med['name'],
                                                      ),
                                                      infoText(
                                                        localization.duration,
                                                        med['duration']
                                                            .toString(),
                                                      ),
                                                      infoText(
                                                        localization.dosage,
                                                        med['dose'].toString(),
                                                      ),
                                                      infoText(
                                                        localization.frequency,
                                                        med['frequency']
                                                            .toString(),
                                                      ),
                                                      infoText(
                                                        localization.survey,
                                                        translateSurveyStatus(
                                                          surveyStatus,
                                                          localization,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 24),
                                              Container(
                                                width: 550,
                                                padding: EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFFF3FAED),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(20),

                                                  child: Table(
                                                    border: TableBorder.all(
                                                      color: Color.fromRGBO(
                                                        136,
                                                        151,
                                                        108,
                                                        1,
                                                      ),
                                                      width: 1,
                                                    ),
                                                    children: [
                                                      TableRow(
                                                        decoration:
                                                            BoxDecoration(
                                                              color:
                                                                  Color.fromRGBO(
                                                                    136,
                                                                    151,
                                                                    108,
                                                                    1,
                                                                  ),
                                                            ),
                                                        children: [
                                                          tableCell(
                                                            localization
                                                                .visitDate,
                                                            isHeader: true,
                                                          ),
                                                          tableCell(
                                                            localization
                                                                .nextdue,
                                                            isHeader: true,
                                                          ),
                                                          tableCell(
                                                            localization.status,
                                                            isHeader: true,
                                                          ),
                                                          tableCell(
                                                            localization
                                                                .dayslate,
                                                            isHeader: true,
                                                          ),
                                                        ],
                                                      ),
                                                      ...visits.map(
                                                        (visit) => TableRow(
                                                          decoration:
                                                              BoxDecoration(
                                                                color: Color(
                                                                  0xFFF3FAED,
                                                                ),
                                                              ),
                                                          children: [
                                                            tableCell(
                                                              visit['visitDate'] ??
                                                                  '',
                                                            ),
                                                            tableCell(
                                                              visit['nextDueDate'] ??
                                                                  '',
                                                            ),
                                                            tableCell(
                                                              (visit['status'] ==
                                                                      'late')
                                                                  ? localization
                                                                      .late
                                                                  : localization.ontime,
                                                            ),
                                                            tableCell(
                                                              '${visit['daysLate'] ?? '0'}',
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(
                                        allMedicines.length,
                                        (index) => Container(
                                          margin: EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                currentPage == index
                                                    ? Colors.green
                                                    : Colors.grey.shade400,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 20),
                              // 👇 الزرارين تحت الشاشة في النص
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 150,
                                    child: CustomHoverButton(
                                      label: localization.back,
                                      icon: Icons.arrow_back,
                                      onTap:
                                          () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      PrescriptionsPage(
                                                        setLocale:
                                                            widget.setLocale,
                                                      ),
                                            ),
                                          ),
                                    ),
                                  ),
                                  SizedBox(width: 20),
                                  Container(
                                    width: 150,
                                    child: AbsorbPointer(
                                      absorbing:
                                          surveyStatus == null ||
                                          (surveyScore != null &&
                                              surveyScore! >= 8),
                                      child: Opacity(
                                        opacity:
                                            (surveyStatus == null ||
                                                    (surveyScore != null &&
                                                        surveyScore! >= 8))
                                                ? 0.5
                                                : 1.0,
                                        child: CustomHoverButton(
                                          label: localization.confirm,
                                          icon: Icons.arrow_forward,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) => OtpPage(
                                                      setLocale:
                                                          widget.setLocale,
                                                      prescriptionId:
                                                          widget.prescriptionId,
                                                      selectedMedicine: {
                                                        ...allMedicines[currentPage],
                                                        'id':
                                                            medicineIds[currentPage],
                                                        'visitHistory':
                                                            allVisitHistories[currentPage],
                                                      },
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
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
}

Widget infoText(String label, dynamic value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(value?.toString() ?? '', style: TextStyle(fontSize: 20)),
      ],
    ),
  );
}

Widget tableCell(String text, {bool isHeader = false}) {
  return Padding(
    padding: const EdgeInsets.all(12.0),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 20,
        fontFamily: 'cursive',
        color: isHeader ? Colors.white : Colors.black,
        fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
      ),
      textAlign: TextAlign.center,
    ),
  );
}

class CustomHoverButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Function onTap;

  CustomHoverButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  _CustomHoverButtonState createState() => _CustomHoverButtonState();
}

class _CustomHoverButtonState extends State<CustomHoverButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color defaultColor = Color.fromRGBO(136, 151, 108, 1);
    Color hoverColor = Color.lerp(defaultColor, Colors.white, 0.2)!;

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
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            color: isHovered ? hoverColor : defaultColor,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white),
              SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
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
