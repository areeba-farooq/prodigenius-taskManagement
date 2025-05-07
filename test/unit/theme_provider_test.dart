import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskgenius/state/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeProvider Tests', () {
    late ThemeProvider themeProvider;

    setUp(() {
      // Setup shared preferences for testing
      SharedPreferences.setMockInitialValues({});
      // Initialize the provider
      themeProvider = ThemeProvider();
    });

    test('Initial theme should be light mode', () {
      // Verify the default theme is light
      expect(themeProvider.themeMode, equals(ThemeMode.light));
      expect(themeProvider.isDarkMode, isFalse);
    });

    test('Toggle theme should switch between light and dark mode', () async {
      // Initial state is light
      expect(themeProvider.themeMode, equals(ThemeMode.light));
      
      // Toggle to dark
      await themeProvider.toggleTheme();
      expect(themeProvider.themeMode, equals(ThemeMode.dark));
      expect(themeProvider.isDarkMode, isTrue);
      
      // Toggle back to light
      await themeProvider.toggleTheme();
      expect(themeProvider.themeMode, equals(ThemeMode.light));
      expect(themeProvider.isDarkMode, isFalse);
    });

    test('Set specific theme should work correctly', () async {
      // Set to dark mode
      await themeProvider.setTheme(ThemeMode.dark);
      expect(themeProvider.themeMode, equals(ThemeMode.dark));
      expect(themeProvider.isDarkMode, isTrue);
      
      // Set to light mode
      await themeProvider.setTheme(ThemeMode.light);
      expect(themeProvider.themeMode, equals(ThemeMode.light));
      expect(themeProvider.isDarkMode, isFalse);
    });

    test('Theme should persist in shared preferences', () async {
      // Set the theme to dark
      await themeProvider.setTheme(ThemeMode.dark);
      
      // Get the saved value from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString('app_theme');
      
      // Verify the saved value is 'dark'
      expect(savedTheme, equals('dark'));
      
      // Change back to light
      await themeProvider.setTheme(ThemeMode.light);
      
      // Get the updated value
      final updatedTheme = prefs.getString('app_theme');
      
      // Verify the saved value is now 'light'
      expect(updatedTheme, equals('light'));
    });

    test('Theme should load from shared preferences', () async {
      // Manually set a theme in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_theme', 'dark');
      
      // Create a new theme provider that should load the saved theme
      final newThemeProvider = ThemeProvider();
      
      // Wait a moment for the provider to load preferences asynchronously
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Verify the provider loaded the dark theme
      expect(newThemeProvider.themeMode, equals(ThemeMode.dark));
      expect(newThemeProvider.isDarkMode, isTrue);
    });
  });
}