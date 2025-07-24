import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'newmedicine.dart';
import '../doctoroverview.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // ✅ ضفنا ScreenUtil

class AddMedicinePage extends StatefulWidget {
  final Function(Locale) setLocale;
  final String prescriptionId;

  const AddMedicinePage({
    super.key,
    required this.setLocale,
    required this.prescriptionId,
  });

  @override
  _AddMedicinePageState createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  List<String> addedMedicines = [];

  Future<void> _saveMedicines() async {
    var localization = AppLocalizations.of(context)!;

    if (addedMedicines.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(localization.success),
          content: Text(localization.medicines_saved),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => HomePage(setLocale: widget.setLocale),
                  ),
                );
              },
              child: Text(localization.ok),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(localization.error),
          content: Text(localization.no_medicines),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localization.ok),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _loadMedicines() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('prescriptions')
        .doc(widget.prescriptionId)
        .collection('medicines')
        .get();

    final List<String> medicines = snapshot.docs
        .map((doc) => doc['name']?.toString() ?? 'Unnamed')
        .toList();

    setState(() {
      addedMedicines = medicines;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadMedicines();
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
            padding: EdgeInsets.all(20.0.w), // ✅ Responsive Padding
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
                      localization.add_medicine,
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Expanded(
                  child: addedMedicines.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/add_medicine_icon.png',
                                height: 150.h,
                              ),
                              SizedBox(height: 20.h),
                              Text(
                                localization.no_medicine_added,
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 10.h),
                              Text(
                                localization.no_medicines,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: Colors.black54,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: addedMedicines.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(
                                addedMedicines[index],
                                style: TextStyle(fontSize: 18.sp),
                              ),
                              leading: const Icon(
                                Icons.medication,
                                color: Color(0xFF88976C),
                              ),
                            );
                          },
                        ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF88976C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0.r),
                        ),
                        minimumSize: Size(150.w, 50.h),
                      ),
                      onPressed: () async {
                        final result = await Navigator.of(context).push<String>(
                          MaterialPageRoute(
                            builder: (context) => AddMedicineform(
                              setLocale: widget.setLocale,
                              prescriptionId: widget.prescriptionId,
                            ),
                          ),
                        );

                        if (result != null) {
                          await FirebaseFirestore.instance
                              .collection('prescriptions')
                              .doc(widget.prescriptionId)
                              .collection('medicines')
                              .add({
                            'name': result,
                            'addedAt': Timestamp.now(),
                          });

                          setState(() {
                            addedMedicines.add(result);
                          });
                        }
                      },
                      child: Text(
                        localization.add,
                        style: TextStyle(
                          fontSize: 18.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF88976C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0.r),
                        ),
                        minimumSize: Size(150.w, 50.h),
                      ),
                      onPressed: _saveMedicines,
                      child: Text(
                        localization.submit,
                        style: TextStyle(
                          fontSize: 18.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
