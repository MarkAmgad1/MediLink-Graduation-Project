import 'package:flutter/material.dart';
import 'package:flutter_application_1/scroll_behavior.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // لازم الملف ده يكون مولود من flutterfire configure
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ تهيئة Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ استرجاع اللغة المحفوظة
  Locale savedLocale = await getSavedLocale();

  runApp(MyApp(savedLocale: savedLocale));
}

Future<Locale> getSavedLocale() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? langCode = prefs.getString('language');
  return Locale(langCode ?? 'en');
}

class MyApp extends StatefulWidget {
  final Locale savedLocale;

  const MyApp({Key? key, required this.savedLocale}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.savedLocale;

    // ✅ اختبار الربط مع Firebase
    print("🔥 Connected to Firebase project: ${Firebase.app().options.projectId}");
  }

  void setLocale(Locale locale) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', locale.languageCode);
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: MyCustomScrollBehavior(),
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: const [
        Locale('en', ''),
        Locale('ar', ''),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        for (var locale in supportedLocales) {
          if (deviceLocale != null &&
              locale.languageCode == deviceLocale.languageCode) {
            return deviceLocale;
          }
        }
        return const Locale('en');
      },
      builder: (context, child) {
        return Directionality(
          textDirection:
              _locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? Container(),
        );
      },
      home: LoginPage(setLocale: setLocale),
    );
  }
}
