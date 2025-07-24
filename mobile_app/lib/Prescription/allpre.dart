import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'editpre.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // ✅ ضفنا ScreenUtil

class Allpre extends StatefulWidget {
  final Function(Locale) setLocale;
  const Allpre({super.key, required this.setLocale});

  @override
  _AllpreState createState() => _AllpreState();
}

class _AllpreState extends State<Allpre> {
  List<DocumentSnapshot> prescriptions = [];
  List<DocumentSnapshot> filteredPrescriptions = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPrescriptions();
  }

  Future<void> _fetchPrescriptions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('prescriptions')
        .where('doctorId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      prescriptions = snapshot.docs;
      filteredPrescriptions = prescriptions;
    });
  }

  void _searchPrescriptions(String query) {
    setState(() {
      filteredPrescriptions = prescriptions.where((doc) {
        final name = (doc['patientName'] ?? '').toLowerCase();
        final nationalID = (doc['nationalId'] ?? '').toLowerCase();
        final searchQuery = query.toLowerCase();
        return name.contains(searchQuery) || nationalID.contains(searchQuery);
      }).toList();
    });
  }

  void _deletePrescription(String id) async {
    await FirebaseFirestore.instance.collection('prescriptions').doc(id).delete();
    _fetchPrescriptions();
  }

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
                  image: AssetImage('assets/background3.png'),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.0.w), // ✅ Responsive padding
            child: Column(
              children: [
                SizedBox(height: 40.h),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Image.asset(
                        'assets/back_icon.png',
                        height: 45.h,
                        width: 45.w,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      localization.all_prescriptions,
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                TextField(
                  controller: searchController,
                  onChanged: _searchPrescriptions,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: localization.search_hint,
                    filled: true,
                    fillColor: const Color(0xFFF3FAED),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Expanded(
                  child: filteredPrescriptions.isEmpty
                      ? Center(
                          child: Text(
                            localization.no_prescriptions,
                            style: TextStyle(
                              fontSize: 18.sp,
                              color: Colors.black54,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredPrescriptions.length,
                          itemBuilder: (context, index) {
                            final doc = filteredPrescriptions[index];
                            final date = (doc['timestamp'] as Timestamp?)?.toDate();

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0.r),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(15.0.w),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${localization.name} ${doc['patientName']}",
                                            style: TextStyle(
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF88976C),
                                            ),
                                          ),
                                          Text(
                                            "${localization.national_id} ${doc['nationalId']}",
                                            style: TextStyle(fontSize: 16.sp),
                                          ),
                                          Text(
                                            "${localization.date} ${date != null ? date.toLocal().toString().split(' ')[0] : ''}",
                                            style: TextStyle(fontSize: 16.sp),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Color(0xFF88976C)),
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => EditPrescriptionPage(
                                                  name: doc['patientName'],
                                                  nationalID: doc['nationalId'],
                                                  age: doc['age'] ?? '',
                                                  phoneNumber: doc['phone'] ?? '',
                                                  setLocale: widget.setLocale,
                                                  prescriptionId: doc.id,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deletePrescription(doc.id),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
