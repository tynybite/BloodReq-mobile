import 'package:flutter_test/flutter_test.dart';
import 'package:bloodreq/core/i18n/translations.dart';
import 'package:bloodreq/core/config/language_config.dart';

void main() {
  group('Localization Tests', () {
    test('Should have translations for all supported languages', () {
      final supportedLanguages = ['en', 'bn', 'de', 'pl', 'tl'];

      for (final lang in supportedLanguages) {
        expect(
          AppTranslations.translations.containsKey(lang),
          true,
          reason: 'Missing translations for $lang',
        );

        final translations = AppTranslations.translations[lang]!;
        expect(
          translations.isNotEmpty,
          true,
          reason: 'Translations for $lang should not be empty',
        );

        // Check for a few critical keys
        expect(translations.containsKey('app_name'), true);
        expect(translations.containsKey('welcome'), true);
        expect(translations.containsKey('sign_in'), true);
      }
    });

    test('Should have consistency across languages', () {
      final enKeys = AppTranslations.translations['en']!.keys.toSet();

      for (final lang in ['bn', 'de', 'pl', 'tl']) {
        final langKeys = AppTranslations.translations[lang]!.keys.toSet();

        // check if all EN keys exist in other languages
        final missingKeys = enKeys.difference(langKeys);

        // We can enforce strict equality if we want, but for now just logging warning or checking critical ones
        // enforcing strict equality for now to ensure quality
        expect(
          missingKeys.isEmpty,
          true,
          reason: 'Missing keys in $lang: $missingKeys',
        );
      }
    });

    test('Should have supportedLocales list', () {
      expect(AppTranslations.supportedLocales.length, 5);
      expect(
        AppTranslations.supportedLocales
            .map((l) => l.languageCode)
            .contains('en'),
        true,
      );
      expect(
        AppTranslations.supportedLocales
            .map((l) => l.languageCode)
            .contains('bn'),
        true,
      );
      expect(
        AppTranslations.supportedLocales
            .map((l) => l.languageCode)
            .contains('de'),
        true,
      );
      expect(
        AppTranslations.supportedLocales
            .map((l) => l.languageCode)
            .contains('pl'),
        true,
      );
      expect(
        AppTranslations.supportedLocales
            .map((l) => l.languageCode)
            .contains('tl'),
        true,
      );
    });
  });

  group('LanguageConfig Tests', () {
    test('Should have options matching supported languages', () {
      final configCodes = LanguageConfig.options.map((o) => o.code).toSet();
      final supportedCodes = AppTranslations.supportedLocales
          .map((l) => l.languageCode)
          .toSet();

      expect(configCodes.length, supportedCodes.length);
      expect(configCodes.containsAll(supportedCodes), true);

      // Check flags are present
      for (final option in LanguageConfig.options) {
        expect(option.flag.isNotEmpty, true);
        expect(option.name.isNotEmpty, true);
      }
    });

    test('getOption should return correct option', () {
      final enOption = LanguageConfig.getOption('en');
      expect(enOption.code, 'en');
      expect(enOption.flag, '🇺🇸');

      // Test fallback
      final fallbackOption = LanguageConfig.getOption('xx');
      expect(fallbackOption.code, LanguageConfig.options.first.code);
    });
  });
}
