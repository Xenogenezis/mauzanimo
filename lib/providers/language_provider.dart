import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String defaultLang = 'en';
  static const List<String> supportedLanguages = ['en', 'fr', 'mfe'];

  String _lang = defaultLang;
  String get lang => _lang;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('language') ?? defaultLang;
    _lang = supportedLanguages.contains(stored) ? stored : defaultLang;
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (!supportedLanguages.contains(code) || code == _lang) return;
    _lang = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _lang);
    notifyListeners();
  }

  String get currentLanguageDisplayName {
    switch (_lang) {
      case 'en':
        return 'English';
      case 'fr':
        return 'Francais';
      case 'mfe':
        return 'Kreol Morisien';
      default:
        return 'English';
    }
  }
}
