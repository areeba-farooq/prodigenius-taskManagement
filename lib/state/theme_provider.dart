import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  
  static const String _themeKey = 'app_theme';

  
  ThemeMode _themeMode = ThemeMode.light;

  
  ThemeMode get themeMode => _themeMode;

  
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  
  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  // Load theme from shared preferences
  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);

      if (savedTheme != null) {
        _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading theme: $e');
    }
  }

  // Save theme to shared preferences
  Future<void> _saveThemeToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _themeKey,
        _themeMode == ThemeMode.dark ? 'dark' : 'light',
      );
    } catch (e) {
      print('Error saving theme: $e');
    }
  }

  // Toggle between light and dark theme
  Future<void> toggleTheme() async {
    print(
      "Toggling theme from ${_themeMode == ThemeMode.light ? 'light' : 'dark'} to ${_themeMode == ThemeMode.light ? 'dark' : 'light'}",
    );

    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _saveThemeToPrefs();
    notifyListeners();
    print(
      "Theme toggled to: ${_themeMode == ThemeMode.light ? 'light' : 'dark'}",
    );
  }

  // Set specific theme
  Future<void> setTheme(ThemeMode themeMode) async {
    _themeMode = themeMode;
    await _saveThemeToPrefs();
    notifyListeners();
  }
}
