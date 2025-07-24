import 'package:flutter/material.dart';
import 'createaccount2.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // ✅ اضفنا ScreenUtil

class CreateAccountPage extends StatefulWidget {
  final Function(Locale) setLocale;
  const CreateAccountPage({super.key, required this.setLocale});

  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final TextEditingController namecontroller = TextEditingController();
  final TextEditingController emailcontroller = TextEditingController();
  final TextEditingController phonecontroller = TextEditingController();
  final TextEditingController passwordcontroller = TextEditingController();
  final TextEditingController conpasswordcontroller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isFormValid = false;

  void _checkFormValid() {
    setState(() {
      isFormValid = _formKey.currentState?.validate() ?? false;
    });
  }

  @override
  void dispose() {
    namecontroller.dispose();
    emailcontroller.dispose();
    phonecontroller.dispose();
    passwordcontroller.dispose();
    conpasswordcontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var localization = AppLocalizations.of(context)!;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background1.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.0.w), // ✅ خليت الـ padding responsive
          child: SingleChildScrollView(
              child: Form(
            key: _formKey,
            onChanged: _checkFormValid,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 60.h),
                Center(
                  child: Text(
                    localization.create_account,
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 120.h),
                _buildValidatedTextField(
                  label: localization.name,
                  controller: namecontroller,
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localization.field_required;
                    }
                    if (!RegExp(r"^[a-zA-Z\u0621-\u064A\s]+$")
                        .hasMatch(value)) {
                      return localization.name_letters_only;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 35.h),
                _buildValidatedTextField(
                  label: localization.email,
                  controller: emailcontroller,
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localization.field_required;
                    }
                    if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$")
                        .hasMatch(value)) {
                      return localization.invalid_email;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 35.h),
                _buildValidatedTextField(
                  label: localization.phone_number,
                  controller: phonecontroller,
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localization.field_required;
                    }
                    if (!RegExp(r"^[0-9]{11}$").hasMatch(value)) {
                      return localization.invalid_phone;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 35.h),
                _buildValidatedPasswordField(
                  label: localization.password,
                  controller: passwordcontroller,
                  isVisible: isPasswordVisible,
                  toggleVisibility: () => setState(() {
                    isPasswordVisible = !isPasswordVisible;
                  }),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localization.field_required;
                    }
                    if (value.length < 6) {
                      return localization.password_too_short;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 35.h),
                _buildValidatedPasswordField(
                  label: localization.confirm_password,
                  controller: conpasswordcontroller,
                  isVisible: isConfirmPasswordVisible,
                  toggleVisibility: () => setState(() {
                    isConfirmPasswordVisible = !isConfirmPasswordVisible;
                  }),
                  validator: (value) {
                    if (value != passwordcontroller.text) {
                      return localization.passwords_do_not_match;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 50.h),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF88976C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.0.r),
                      ),
                      minimumSize: Size(250.w, 60.h),
                    ),
                    onPressed: isFormValid
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => CreateDoctorAccountPage(
                                  setLocale: widget.setLocale,
                                  namecontroller: namecontroller,
                                  emailcontroller: emailcontroller,
                                  phonecontroller: phonecontroller,
                                  passwordcontroller: passwordcontroller,
                                ),
                              ),
                            );
                          }
                        : null,
                    child: Text(
                      localization.next,
                      style: TextStyle(fontSize: 20.sp, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ),
      ),
    );
  }

  Widget _buildValidatedTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF88976C)),
        labelText: label,
        labelStyle: TextStyle(color: const Color(0xFF88976C), fontSize: 16.sp),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0.r),
          borderSide: const BorderSide(color: Color(0xFF88976C)),
        ),
      ),
    );
  }

  Widget _buildValidatedPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback toggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock, color: Color(0xFF88976C)),
        labelText: label,
        labelStyle: TextStyle(color: const Color(0xFF88976C), fontSize: 16.sp),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0.r),
          borderSide: const BorderSide(color: Color(0xFF88976C)),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: const Color(0xFF88976C),
          ),
          onPressed: toggleVisibility,
        ),
      ),
    );
  }
}
