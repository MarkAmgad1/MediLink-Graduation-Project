import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LocalizationService {
  static const supportedLocales = [
    Locale('en', ''), // الإنجليزية
    Locale('ar', ''), // العربية
  ];

  static Locale? localeResolutionCallback(Locale? locale, Iterable<Locale> supportedLocales) {
    if (supportedLocales.contains(locale)) {
      return locale;
    }
    return const Locale('en', ''); // الافتراضية
  }

  static List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static var delegate;
}
