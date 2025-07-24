import 'package:flutter/material.dart';
import 'package:flutter_application_1/DocInfo/welcome.dart';
import 'package:flutter_application_1/doctoroverview.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  final Function(Locale) setLocale;

  const SplashScreen({super.key, required this.setLocale});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), checkKeepSignedInOrOnboarding);
  }

  Future<void> checkKeepSignedInOrOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final keepSignedIn = prefs.getBool('keepMeSignedIn') ?? false;
    final hasSeenOnboarding = prefs.getBool('onboardingSeen') ?? false;

    if (keepSignedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => HomePage(setLocale: widget.setLocale)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => hasSeenOnboarding
              ? WelcomePage(setLocale: widget.setLocale)
              : OnboardingScreen(setLocale: widget.setLocale),
        ),
      );
    }
  }

  void checkIfUserKeptSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final keepSignedIn = prefs.getBool('keepMeSignedIn') ?? false;

    if (keepSignedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => HomePage(setLocale: widget.setLocale)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => WelcomePage(
                  setLocale: widget.setLocale,
                )),
      );
    }
  }

  Future<void> checkIfSeenOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('onboardingSeen') ?? false;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => hasSeen
            ? WelcomePage(setLocale: widget.setLocale) // ✅ لو شاف Onboarding
            : OnboardingScreen(setLocale: widget.setLocale), // ✅ أول مرة بس
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/bgs.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                height: 300,
              ),
              const SizedBox(height: 20),
              const Text(
                "MediLink",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
