import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  final Function(Locale) setLocale;

  const SignUpPage({super.key, required this.setLocale});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  String? _syndicateCardFile;
  String? _pharmacyLicenseFile;
  bool _isFormValid = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController pharmacyNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  Future<void> _pickFile(Function(String) onFileSelected) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      withData: true, // ✅ مهم في Web
    );

    if (result != null && result.files.isNotEmpty) {
      final pickedFile = result.files.first;
      final fileName = pickedFile.name; // ✅ بدل path

      onFileSelected(fileName); // ✅ خليها fileName
    }
  }

  Future<void> _handleSignup() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      String uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('pharmacies').doc(uid).set({
        'email': emailController.text.trim(),
        'name': pharmacyNameController.text.trim(),
        'address': addressController.text.trim(),
        'syndicateCardFile': _syndicateCardFile ?? '',
        'pharmacyLicenseFile': _pharmacyLicenseFile ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'userType': 'web',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(Duration(seconds: 2));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginPage(setLocale: widget.setLocale),
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Signup error'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _validateForm() {
    setState(() {
      _isFormValid =
          RegExp(
            r"^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$",
          ).hasMatch(emailController.text.trim()) &&
          passwordController.text.trim().length > 6 &&
          RegExp(
            r"^[a-zA-Z\s]+$",
          ).hasMatch(pharmacyNameController.text.trim()) &&
          addressController.text.trim().isNotEmpty &&
          (_syndicateCardFile?.isNotEmpty ?? false) &&
          (_pharmacyLicenseFile?.isNotEmpty ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    var localization = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F5),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: DropdownButton<String>(
                    value: Localizations.localeOf(context).languageCode,
                    onChanged: (String? languageCode) {
                      if (languageCode != null) {
                        widget.setLocale(Locale(languageCode));
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: "en", child: Text("English")),
                      DropdownMenuItem(value: "ar", child: Text("العربية")),
                    ],
                  ),
                ),
                Container(
                  color: const Color(0xFFF3FAED),
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      Image.asset('assets/Logo.png', height: 100),
                      const SizedBox(height: 15),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        localization.createAccount,
                        style: const TextStyle(
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        localization.username,
                        emailController,
                        helperText: "Enter a valid email like name@example.com",
                      ),
                      _buildTextField(
                        localization.password,
                        passwordController,
                        obscureText: true,
                        helperText: "Password must be at least 7 characters",
                      ),
                      _buildTextField(
                        localization.pharmacyName,
                        pharmacyNameController,
                        helperText: "Only letters are allowed, no numbers",
                      ),
                      _buildTextField(
                        localization.address,
                        addressController,
                        helperText:
                            "Can include letters and numbers (e.g., Street 12, Cairo)",
                      ),
                      _buildFileInput(
                        localization.syndicateCard,
                        _syndicateCardFile,
                        (path) => setState(() {
                          _syndicateCardFile = path;
                          _validateForm(); // ✅ بعد اختيار الصورة
                        }),
                      ),
                      _buildFileInput(
                        localization.pharmacyLicense,
                        _pharmacyLicenseFile,
                        (path) => setState(() {
                          _pharmacyLicenseFile = path;
                          _validateForm(); // ✅ بعد اختيار الصورة
                        }),
                      ),

                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isFormValid ? _handleSignup : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF88976C),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          localization.createAccount,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        LoginPage(setLocale: widget.setLocale),
                              ),
                            );
                          },
                          child: Text.rich(
                            TextSpan(
                              text: localization.alreadyHaveAccount,
                              style: const TextStyle(fontSize: 16),
                              children: [
                                TextSpan(
                                  text: localization.login,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF88976C),
                                  ),
                                ),
                              ],
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
      ),
    );
  }

  Widget _buildTextField(
    String placeholder,
    TextEditingController controller, {
    bool obscureText = false,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        onChanged: (_) => _validateForm(),
        decoration: InputDecoration(
          hintText: placeholder,
          helperText: helperText, // ✅ النص اللي تحت
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildFileInput(
    String label,
    String? filePath,
    Function(String) onFileSelected,
  ) {
    var localization = AppLocalizations.of(context)!;
    final isMissing = filePath?.isEmpty ?? true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText:
                        filePath?.isNotEmpty == true
                            ? filePath!.split('/').last
                            : localization.chooseFile,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  enabled: false,
                ),
              ),
              IconButton(
                onPressed: () async {
                  await _pickFile((path) {
                    onFileSelected(path);
                    _validateForm();
                  });
                },
                icon: const Icon(Icons.folder_open, color: Color(0xFF88976C)),
              ),
              IconButton(
                onPressed: () {
                  onFileSelected('');
                  _validateForm();
                },
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
          if (isMissing)
            const Padding(
              padding: EdgeInsets.only(top: 5, left: 4),
              child: Text(
                'Required',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
