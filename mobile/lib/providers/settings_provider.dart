import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String _defaultTargetLang = 'ur';
  double _ttsRate = 0.9;
  double _ttsPitch = 1.0;
  List<String> _recentLangs = [];
  bool _onboardingDone = false;
  bool _ratingShown = false;
  int _translateCount = 0;

  ThemeMode get themeMode => _themeMode;
  String get defaultTargetLang => _defaultTargetLang;
  double get ttsRate => _ttsRate;
  double get ttsPitch => _ttsPitch;
  List<String> get recentLangs => List.unmodifiable(_recentLangs);
  bool get onboardingDone => _onboardingDone;
  bool get ratingShown => _ratingShown;
  int get translateCount => _translateCount;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString('theme') ?? 'system';
    if (themeStr == 'light') _themeMode = ThemeMode.light;
    if (themeStr == 'dark') _themeMode = ThemeMode.dark;
    if (themeStr == 'system') _themeMode = ThemeMode.system;

    _defaultTargetLang = prefs.getString('defaultTargetLang') ?? 'ur';
    _ttsRate = prefs.getDouble('ttsRate') ?? 0.9;
    _ttsPitch = prefs.getDouble('ttsPitch') ?? 1.0;
    _recentLangs = prefs.getStringList('recentLangs') ?? [];
    _onboardingDone = prefs.getBool('onboardingDone') ?? false;
    _ratingShown = prefs.getBool('ratingShown') ?? false;
    _translateCount = prefs.getInt('translateCount') ?? 0;
    notifyListeners();
  }

  Future<void> addRecentLang(String code) async {
    if (code.isEmpty || code == 'auto') return;
    _recentLangs.remove(code);
    _recentLangs.insert(0, code);
    if (_recentLangs.length > 5) {
      _recentLangs = _recentLangs.sublist(0, 5);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recentLangs', _recentLangs);
  }

  Future<void> markOnboardingDone() async {
    _onboardingDone = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingDone', true);
  }

  Future<void> markRatingShown() async {
    _ratingShown = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ratingShown', true);
  }

  Future<void> incrementTranslateCount() async {
    _translateCount++;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('translateCount', _translateCount);
  }

  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.light) await prefs.setString('theme', 'light');
    if (mode == ThemeMode.dark) await prefs.setString('theme', 'dark');
    if (mode == ThemeMode.system) await prefs.setString('theme', 'system');
  }

  Future<void> setDefaultTargetLang(String lang) async {
    _defaultTargetLang = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('defaultTargetLang', lang);
  }

  Future<void> setTtsRate(double rate) async {
    _ttsRate = rate;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('ttsRate', rate);
  }

  Future<void> setTtsPitch(double pitch) async {
    _ttsPitch = pitch;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('ttsPitch', pitch);
  }
}
