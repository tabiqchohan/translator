import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translater/core/constants.dart';
import 'package:translater/core/language_detector.dart';
import 'package:translater/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppConstants', () {
    test('getLanguageName resolves known codes', () {
      expect(AppConstants.getLanguageName('ur'), 'Urdu');
      expect(AppConstants.getLanguageName('en'), 'English');
      expect(AppConstants.getLanguageName('zh-TW'), 'Chinese (Traditional)');
    });

    test('getLanguageName falls back to uppercased code', () {
      expect(AppConstants.getLanguageName('xx'), 'XX');
    });
  });

  group('LanguageDetector', () {
    test('detects Urdu script', () {
      expect(LanguageDetector.detect('یہ ایک اردو جملہ ہے'), 'ur');
      expect(LanguageDetector.detect('آپ کیسے ہیں؟'), 'ur');
    });

    test('detects Arabic script', () {
      expect(LanguageDetector.detect('هذا جملة بالعربية'), 'ar');
    });

    test('detects Devanagari scripts', () {
      expect(LanguageDetector.detect('यह एक हिंदी वाक्य है'), 'hi');
      expect(LanguageDetector.detect('এটি একটি বাংলা বাক্য'), 'bn');
    });

    test('returns null for Latin script', () {
      expect(LanguageDetector.detect('This is English text'), isNull);
      expect(LanguageDetector.detect(''), isNull);
    });
  });

  group('SettingsProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('init loads defaults', () async {
      final provider = SettingsProvider();
      await provider.init();

      expect(provider.themeMode, ThemeMode.system);
      expect(provider.defaultTargetLang, 'ur');
      expect(provider.ttsRate, 0.9);
      expect(provider.ttsPitch, 1.0);
      expect(provider.recentLangs, isEmpty);
      expect(provider.onboardingDone, isFalse);
      expect(provider.ratingShown, isFalse);
      expect(provider.translateCount, 0);
    });

    test('init loads persisted values', () async {
      SharedPreferences.setMockInitialValues({
        'theme': 'dark',
        'defaultTargetLang': 'fr',
        'ttsRate': 1.2,
        'ttsPitch': 1.8,
        'recentLangs': ['en', 'ur'],
        'onboardingDone': true,
        'ratingShown': true,
        'translateCount': 5,
      });

      final provider = SettingsProvider();
      await provider.init();

      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.defaultTargetLang, 'fr');
      expect(provider.ttsRate, 1.2);
      expect(provider.ttsPitch, 1.8);
      expect(provider.recentLangs, ['en', 'ur']);
      expect(provider.onboardingDone, isTrue);
      expect(provider.ratingShown, isTrue);
      expect(provider.translateCount, 5);
    });

    test('addRecentLang dedupes, moves to front and caps at 5', () async {
      final provider = SettingsProvider();
      await provider.init();

      for (final code in ['en', 'ur', 'hi', 'fr', 'de', 'es']) {
        await provider.addRecentLang(code);
      }

      expect(provider.recentLangs.length, 5);
      expect(provider.recentLangs.first, 'es');
      expect(provider.recentLangs.contains('en'), isFalse);

      await provider.addRecentLang('de');
      expect(provider.recentLangs.first, 'de');
      expect(provider.recentLangs.length, 5);
    });

    test('addRecentLang ignores auto', () async {
      final provider = SettingsProvider();
      await provider.init();

      await provider.addRecentLang('auto');
      expect(provider.recentLangs, isEmpty);
    });

    test('recent langs persist across instances', () async {
      final provider = SettingsProvider();
      await provider.init();
      await provider.addRecentLang('hi');

      final reloaded = SettingsProvider();
      await reloaded.init();

      expect(reloaded.recentLangs, ['hi']);
    });

    test('setTtsRate persists', () async {
      final provider = SettingsProvider();
      await provider.init();
      await provider.setTtsRate(1.5);

      final reloaded = SettingsProvider();
      await reloaded.init();

      expect(reloaded.ttsRate, 1.5);
    });

    test('setTtsPitch persists', () async {
      final provider = SettingsProvider();
      await provider.init();
      await provider.setTtsPitch(1.5);

      final reloaded = SettingsProvider();
      await reloaded.init();

      expect(reloaded.ttsPitch, 1.5);
    });

    test('markOnboardingDone persists', () async {
      final provider = SettingsProvider();
      await provider.init();
      await provider.markOnboardingDone();

      final reloaded = SettingsProvider();
      await reloaded.init();

      expect(reloaded.onboardingDone, isTrue);
    });

    test('markRatingShown persists', () async {
      final provider = SettingsProvider();
      await provider.init();
      await provider.markRatingShown();

      final reloaded = SettingsProvider();
      await reloaded.init();

      expect(reloaded.ratingShown, isTrue);
    });

    test('incrementTranslateCount accumulates and persists', () async {
      final provider = SettingsProvider();
      await provider.init();

      await provider.incrementTranslateCount();
      await provider.incrementTranslateCount();
      await provider.incrementTranslateCount();

      expect(provider.translateCount, 3);

      final reloaded = SettingsProvider();
      await reloaded.init();

      expect(reloaded.translateCount, 3);
    });
  });
}
