import 'package:flutter/material.dart';
import 'languages/en.dart';
import 'languages/bn.dart';
import 'languages/de.dart';
import 'languages/pl.dart';
import 'languages/tl.dart';

class AppTranslations {
  static const Map<String, Map<String, String>> translations = {
    'en': en,
    'bn': bn,
    'de': de,
    'pl': pl,
    'tl': tl,
  };

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('bn'),
    Locale('de'),
    Locale('pl'),
    Locale('tl'),
  ];
}
