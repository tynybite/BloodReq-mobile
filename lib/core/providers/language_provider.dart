import 'package:bloodreq/core/i18n/translations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  static const String _prefKey = 'selected_language';

  Locale get currentLocale => _currentLocale;

  Map<String, String> get texts =>
      AppTranslations.translations[_currentLocale.languageCode] ??
      AppTranslations.translations['en']!;

  /// Get text helpers
  String getText(String key) {
    return texts[key] ?? key;
  }

  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_prefKey);
    if (savedCode != null) {
      _currentLocale = Locale(savedCode);
      notifyListeners();
    }
  }

  Future<void> toggleLanguage() async {
    if (_currentLocale.languageCode == 'en') {
      await changeLanguage(const Locale('bn'));
    } else {
      await changeLanguage(const Locale('en'));
    }
  }

  Future<void> changeLanguage(Locale locale) async {
    _currentLocale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, locale.languageCode);
    notifyListeners();
  }
}
