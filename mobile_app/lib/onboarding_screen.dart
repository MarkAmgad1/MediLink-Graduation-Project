import 'package:flutter/material.dart';
import 'package:flutter_application_1/OnBoarding/onboarding1.dart';
import 'package:flutter_application_1/OnBoarding/onboarding2.dart';
import 'package:flutter_application_1/OnBoarding/onboarding3.dart';


class OnboardingScreen extends StatefulWidget {
  final Function(Locale) setLocale;

  const OnboardingScreen({super.key, required this.setLocale});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      PrescriptionPage(setLocale: widget.setLocale),
      PharmacistControlPage(setLocale: widget.setLocale),
      GetStartedPage(setLocale: widget.setLocale),
    ];
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(), // يمنع السحب يدويًا
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _pages,
      ),
    );
  }
}
