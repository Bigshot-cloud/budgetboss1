import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  static const String _themeKey = 'user_theme_preference';

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(_themeKey);
    
    if (themeStr != null) {
      if (themeStr == 'Light') _themeMode = ThemeMode.light;
      else if (themeStr == 'Dark') _themeMode = ThemeMode.dark;
      else _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.dark; // Default
    }
    notifyListeners();
  }

  Future<void> setTheme(String mode) async {
    if (mode == 'Light') _themeMode = ThemeMode.light;
    else if (mode == 'Dark') _themeMode = ThemeMode.dark;
    else _themeMode = ThemeMode.system;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode);
    notifyListeners();
  }
}
