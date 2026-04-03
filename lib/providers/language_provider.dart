import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  String _lang = 'en';
  String get lang => _lang;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _lang = prefs.getString('language') ?? 'en';
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    _lang = _lang == 'en' ? 'fr' : 'en';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _lang);
    notifyListeners();
  }
}
