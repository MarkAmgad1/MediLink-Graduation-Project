import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'settings_page.dart';
import 'login_page.dart';
import 'view_details_page.dart';

class PrescriptionsPage extends StatefulWidget {
  final Function(Locale) setLocale;

  PrescriptionsPage({required this.setLocale});
  @override
  _PrescriptionsPage createState() => _PrescriptionsPage();
}

class _PrescriptionsPage extends State<PrescriptionsPage>
    with SingleTickerProviderStateMixin {
  bool isSidebarCollapsed = true;
  String pharmacyName = '';
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  bool isSearchExpanded = false;
  List<Map<String, dynamic>> searchResults = [];
  TextEditingController searchController = TextEditingController();

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void toggleSearchBar() {
    setState(() {
      isSearchExpanded = !isSearchExpanded;
      if (isSearchExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void closeSearchBar() {
    if (isSearchExpanded) {
      setState(() {
        isSearchExpanded = false;
        _controller.reverse();
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
        pharmacyName = doc['name'] ?? 'Pharmacy';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var localization = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () {
        if (isSearchExpanded) closeSearchBar();
      },
      child: Scaffold(
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
                                    (context) => SettingsPage(
                                      setLocale: widget.setLocale,
                                    ),
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
            Expanded(
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          localization.prescriptionDetails,
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
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          toggleSearchBar();
                        },
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return Container(
                              width: _widthAnimation.value,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  isSearchExpanded ? 8 : 50,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child:
                                  isSearchExpanded
                                      ? TextField(
                                        controller: searchController,
                                        autofocus: true,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: localization.search,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 20,
                                          ),
                                        ),
                                        style: TextStyle(color: Colors.black),

                                        // ✅ هنا بيتم تنفيذ البحث لما المستخدم يضغط Enter
                                        onSubmitted: (value) async {
                                          final querySnapshot =
                                              await FirebaseFirestore.instance
                                                  .collection('prescriptions')
                                                  .where(
                                                    'nationalId',
                                                    isEqualTo: value.trim(),
                                                  )
                                                  .get();

                                          List<Map<String, dynamic>> results =
                                              [];

                                          for (var doc in querySnapshot.docs) {
                                            final data = doc.data();
                                            final prescriptionId = doc.id;
                                            final patientName =
                                                data['patientName'];
                                            final nationalId =
                                                data['nationalId'];

                                            // fetch medicines
                                            final medicinesSnapshot =
                                                await FirebaseFirestore.instance
                                                    .collection('prescriptions')
                                                    .doc(prescriptionId)
                                                    .collection('medicines')
                                                    .get();

                                            final medicines =
                                                medicinesSnapshot.docs
                                                    .map((m) => m.data())
                                                    .toList();

                                            bool allProcessed = medicines.every(
                                              (m) => m['status'] == 'processed',
                                            );
                                            bool allPending = medicines.every(
                                              (m) => m['status'] == 'pending',
                                            );

                                            String status = 'partially';
                                            if (allProcessed) {
                                              status = 'processed';
                                            } else if (allPending ) {
                                              status = 'pending';
                                            }

                                            results.add({
                                              'id': prescriptionId,
                                              'patientName': patientName,
                                              'nationalId': nationalId,
                                              'status': status,
                                            });
                                          }

                                          setState(() {
                                            searchResults = results;
                                          });
                                        },
                                      )
                                      : Icon(Icons.search, color: Colors.black),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
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
                                          localization.name,
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
                                        child: Text(
                                          localization.nationalID,
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
                                        child: Text(
                                          localization.status,
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
                                        child: Text(
                                          localization.action,
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
                                searchResults.map((prescription) {
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Center(
                                          child: Text(
                                            prescription['patientName'] ?? '',
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
                                            prescription['nationalId'] ?? '',
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
                                            prescription['status'] ==
                                                    'processed'
                                                ? localization.processed
                                                : prescription['status'] ==
                                                    'pending'
                                                ? localization.pending
                                                : 'Partially Processed',
                                            style: TextStyle(
                                              color:
                                                  prescription['status'] ==
                                                          'processed'
                                                      ? Color.fromRGBO(
                                                        0,
                                                        255,
                                                        0,
                                                        1,
                                                      )
                                                      : prescription['status'] ==
                                                          'pending'
                                                      ? Color.fromRGBO(
                                                        255,
                                                        0,
                                                        0,
                                                        1,
                                                      )
                                                      : Color.fromRGBO(
                                                        255,
                                                        165,
                                                        0,
                                                        1,
                                                      ), // Orange for partial

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
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              shadowColor: Color.fromRGBO(
                                                136,
                                                151,
                                                108,
                                                1,
                                              ),
                                              elevation: 5,
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (
                                                        context,
                                                      ) => ViewDetailsPage(
                                                        setLocale:
                                                            widget.setLocale,
                                                        prescriptionId:
                                                            prescription['id'],
                                                      ),
                                                ),
                                              );
                                            },
                                            child: Text(
                                              localization.viewDetails,
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 24,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black,
                                              ),
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
            ),
          ],
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
