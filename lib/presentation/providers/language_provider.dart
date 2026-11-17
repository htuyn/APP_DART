import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/l10n/app_strings.dart';

enum AppLanguage {
  vi('Tiáº¿ng Viá»‡t', 'vi'),
  en('English', 'en');

  final String label;
  final String code;
  const AppLanguage(this.label, this.code);
}

class LanguageProvider with ChangeNotifier {
  static const String _prefKey = 'selected_language';
  AppLanguage _currentLanguage = AppLanguage.vi;

  AppLanguage get currentLanguage => _currentLanguage;
  String get code => _currentLanguage.code;
  bool get isVietnamese => _currentLanguage == AppLanguage.vi;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_prefKey);
    if (savedCode != null) {
      _currentLanguage = savedCode == 'en' ? AppLanguage.en : AppLanguage.vi;
      notifyListeners();
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;
    _currentLanguage = language;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, language.code);
  }

  void toggleLanguage() {
    setLanguage(isVietnamese ? AppLanguage.en : AppLanguage.vi);
  }

  // Common UI Strings
  String translate({required String vi, required String en}) {
    return isVietnamese ? vi : en;
  }

  String t(String key) => AppStrings.text(code, key);
}
