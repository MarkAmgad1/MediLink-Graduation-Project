import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'prescriptions_page.dart';
import 'settings_page.dart';
import 'login_page.dart';

class DashboardPage extends StatefulWidget {
  final Function(Locale) setLocale; // ← استلام setLocale

  DashboardPage({required this.setLocale}); // ← تعديل الـ Constructor

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool isSidebarCollapsed = true;
  String pharmacyName = '';
  int completedPrescriptions = 0;
  List<Map<String, dynamic>> monthlyDispensed = [];

Future<void> fetchCompletedCount() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  int count = 0;

  final prescriptionsSnapshot = await FirebaseFirestore.instance
      .collection('prescriptions')
      .get(); // ✅ شيلنا شرط الـ pharmacyId هنا

  for (var prescriptionDoc in prescriptionsSnapshot.docs) {
    final medicinesSnapshot = await prescriptionDoc.reference
        .collection('medicines')
        .where('status', isEqualTo: 'processed')
        .where('pharmacyId', isEqualTo: uid) // ✅ الشرط هنا جوا medicine
        .get();

    print(
      'Prescription ${prescriptionDoc.id} has ${medicinesSnapshot.docs.length} processed medicines',
    );

    for (var med in medicinesSnapshot.docs) {
      print('🧾 ${med.id} - status: ${med.data()['status']}');
    }

    count += medicinesSnapshot.docs.length;
  }

  setState(() {
    completedPrescriptions = count;
  });

  print('✅ Total processed medicines: $count');
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

Future<void> fetchMonthlyDispensedData() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  // 👇 ناخد كل الـ prescriptions بدون شرط
  final prescriptionsSnapshot = await FirebaseFirestore.instance
      .collection('prescriptions')
      .get();

  Map<String, Map<String, dynamic>> grouped = {};

  for (var doc in prescriptionsSnapshot.docs) {
    final medicinesSnapshot = await doc.reference
        .collection('medicines')
        .where('status', isEqualTo: 'processed')
        .where('pharmacyId', isEqualTo: uid) // ✅ فلترة على مستوى الدواء
        .get();

    for (var med in medicinesSnapshot.docs) {
      final data = med.data();

      final name = data['name']?.toString().trim().toLowerCase();
      final timestamp = data['addedAt'] as Timestamp?;
      final date = timestamp?.toDate();

      if (name == null || name.isEmpty || date == null) continue;

      final key = '${date.month}-${date.year}-$name';

      if (!grouped.containsKey(key)) {
        grouped[key] = {
          'month': '${date.month}',
          'year': '${date.year}',
          'medicineName': name,
          'quantity': 1,
        };
      } else {
        grouped[key]!['quantity'] += 1;
      }
    }
  }

  final sortedList = grouped.values.toList()
    ..sort((a, b) {
      final aMonth = int.parse(a['month']);
      final bMonth = int.parse(b['month']);
      final aYear = int.parse(a['year']);
      final bYear = int.parse(b['year']);
      return DateTime(aYear, aMonth).compareTo(DateTime(bYear, bMonth));
    });

  setState(() {
    monthlyDispensed = sortedList;
  });

  print('📦 DISPENSED BY MEDICINE & MONTH:');
  for (var entry in monthlyDispensed) {
    print('📦 ${entry['medicineName']} | ${entry['month']}/${entry['year']} = ${entry['quantity']}');
  }
}

  Future<void> autoUpdateProcessedMedicines() async {
    final prescriptionsSnapshot =
        await FirebaseFirestore.instance.collection('prescriptions').get();

    final now = DateTime.now();

    for (var doc in prescriptionsSnapshot.docs) {
      final medicinesSnapshot =
          await doc.reference
              .collection('medicines')
              .where('status', isEqualTo: 'processed')
              .get();

      for (var med in medicinesSnapshot.docs) {
        final data = med.data();
        final visitHistory = data['visitHistory'] as List<dynamic>? ?? [];

        if (visitHistory.isNotEmpty) {
          final lastVisit = visitHistory.last;
          final nextDueStr = lastVisit['nextDueDate'];

          try {
            final nextDueDate = DateFormat('dd-MM-yyyy').parse(nextDueStr);
            if (now.isAfter(nextDueDate)) {
              await med.reference.update({'status': 'pending'});
              print('🔁 Medicine ${med.id} reverted to pending');
            }
          } catch (e) {
            print('❌ Error parsing date for medicine ${med.id}: $e');
          }
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    autoUpdateProcessedMedicines();
    fetchPharmacyName();
    fetchCompletedCount();
    fetchMonthlyDispensedData(); // ← هنا
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
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          text: localization.welcome,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          children: [
                            TextSpan(
                              text: pharmacyName,
                              style: TextStyle(
                                color: Color.fromRGBO(136, 151, 108, 1),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Icon(FontAwesomeIcons.hospital, color: Colors.black),
                          SizedBox(width: 8),
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
                  // Completed Prescriptions
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFF3FAED),
                        border: Border.all(color: Color(0xFF88976C)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            FontAwesomeIcons.check,
                            color: Colors.green,
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                localization.completedPrescriptions,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF88976C),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$completedPrescriptions',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF88976C),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Prescription Table
                  Expanded(
                    child: Column(
                      children: [
                        Flexible(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(136, 151, 108, 1),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                              ),
                            ),
                            child: IntrinsicWidth(
                              child: SingleChildScrollView(
                                child: DataTable(
                                  columnSpacing: 10,
                                  dividerThickness: 1,
                                  horizontalMargin: 0,
                                  headingRowHeight: 0,
                                  dataRowHeight: 50,
                                  columns: [
                                    DataColumn(
                                      label: Container(
                                        width: 200,
                                        child: Center(child: Text('')),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Container(
                                        width: 200,
                                        child: Center(child: Text('')),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Container(
                                        width: 200,
                                        child: Center(child: Text('')),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Container(
                                        width: 200,
                                        child: Center(child: Text('')),
                                      ),
                                    ),
                                  ],
                                  rows: List<DataRow>.generate(
                                    1,
                                    (index) => DataRow(
                                      cells: [
                                        DataCell(
                                          Center(
                                            child: Text(
                                              localization.medicineName,
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 32,
                                                fontWeight: FontWeight.w700,
                                                height: 1.2,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Center(
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                right: 30,
                                              ),
                                              child: Text(
                                                localization.quantity,
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.w700,
                                                  height: 1.2,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Center(
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                right: 22,
                                              ),
                                              child: Text(
                                                localization.from,
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.w700,
                                                  height: 1.2,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Center(
                                            child: Text(
                                              localization.to,
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 32,
                                                fontWeight: FontWeight.w700,
                                                height: 1.2,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Flexible(
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(255, 255, 255, 1),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                              border: Border.all(
                                color: Color.fromRGBO(136, 151, 108, 1),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: Offset(5, 8),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              child: DataTable(
                                columnSpacing: 10,
                                dividerThickness: 1,
                                horizontalMargin: 0,
                                headingRowHeight: 0,
                                dataRowHeight: 50,
                                columns: [
                                  DataColumn(
                                    label: Container(
                                      width: 200,
                                      child: Center(child: Text('')),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Container(
                                      width: 200,
                                      child: Center(child: Text('')),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Container(
                                      width: 200,
                                      child: Center(child: Text('')),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Container(
                                      width: 200,
                                      child: Center(child: Text('')),
                                    ),
                                  ),
                                ],
                                rows:
                                    monthlyDispensed.map((data) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Center(
                                              child: Text(
                                                data['medicineName'] ?? '',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.2,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Center(
                                              child: Text(
                                                '${data['quantity'] ?? 0}',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.2,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Center(
                                              child: Text(
                                                data['month'] ?? '',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.2,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Center(
                                              child: Text(
                                                data['year'] ?? '',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
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
