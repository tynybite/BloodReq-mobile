import 'package:flutter/material.dart';

class LanguageOption {
  final String code;
  final String name;
  final String flag;

  Locale get locale => Locale(code);

  const LanguageOption({
    required this.code,
    required this.name,
    required this.flag,
  });
}

class LanguageConfig {
  static const List<LanguageOption> options = [
    LanguageOption(code: 'en', name: 'English', flag: '🇺🇸'),
    LanguageOption(code: 'bn', name: 'Bangla', flag: '🇧🇩'),
    LanguageOption(code: 'de', name: 'Deutsch', flag: '🇩🇪'),
    LanguageOption(code: 'pl', name: 'Polski', flag: '🇵🇱'),
    LanguageOption(code: 'tl', name: 'Tagalog', flag: '🇵🇭'),
  ];

  static LanguageOption getOption(String code) {
    return options.firstWhere(
      (opt) => opt.code == code,
      orElse: () => options.first,
    );
  }
}
