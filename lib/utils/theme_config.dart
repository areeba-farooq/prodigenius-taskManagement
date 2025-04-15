import 'package:flutter/material.dart';

// class AppTheme {
//   // Light theme
//   static ThemeData lightTheme = ThemeData(
//     useMaterial3: true,
//     brightness: Brightness.light,
//     primarySwatch: Colors.blue,
//     colorScheme: ColorScheme.light(
//       primary: Colors.blue,
//       secondary: Colors.blueAccent,
//       surface: Colors.white,
//       background: Colors.grey.shade50,
//       error: Colors.red.shade700,
//     ),
//     appBarTheme: AppBarTheme(
//       backgroundColor: Colors.blue,
//       foregroundColor: Colors.white,
//       elevation: 0,
//     ),
//     cardTheme: CardTheme(
//       color: Colors.white,
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//     ),
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         foregroundColor: Colors.white,
//         backgroundColor: Colors.blue,
//         elevation: 2,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//       ),
//     ),
//     outlinedButtonTheme: OutlinedButtonThemeData(
//       style: OutlinedButton.styleFrom(
//         foregroundColor: Colors.blue,
//         side: const BorderSide(color: Colors.blue),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//       ),
//     ),
//     textButtonTheme: TextButtonThemeData(
//       style: TextButton.styleFrom(
//         foregroundColor: Colors.blue,
//       ),
//     ),
//     inputDecorationTheme: InputDecorationTheme(
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//       ),
//       filled: true,
//       fillColor: Colors.grey.shade100,
//       contentPadding: const EdgeInsets.all(16),
//     ),
//     bottomNavigationBarTheme: BottomNavigationBarThemeData(
//       backgroundColor: Colors.white,
//       selectedItemColor: Colors.blue,
//       unselectedItemColor: Colors.grey.shade600,
//       type: BottomNavigationBarType.fixed,
//       elevation: 8,
//     ),
//     dividerTheme: DividerThemeData(
//       color: Colors.grey.shade300,
//       thickness: 1,
//     ),
//     textTheme: const TextTheme(
//       titleLarge: TextStyle(
//         fontSize: 22,
//         fontWeight: FontWeight.bold,
//         color: Colors.black87,
//       ),
//       titleMedium: TextStyle(
//         fontSize: 18,
//         fontWeight: FontWeight.bold,
//         color: Colors.black87,
//       ),
//       bodyLarge: TextStyle(
//         fontSize: 16,
//         color: Colors.black87,
//       ),
//       bodyMedium: TextStyle(
//         fontSize: 14,
//         color: Colors.black87,
//       ),
//     ),
//   );

//   // Dark theme
//   static ThemeData darkTheme = ThemeData(
//     useMaterial3: true,
//     brightness: Brightness.dark,
//     primarySwatch: Colors.blue,
//     colorScheme: ColorScheme.dark(
//       primary: Colors.blue,
//       secondary: Colors.lightBlue,
//       surface: const Color(0xFF1E1E1E),
//       background: const Color(0xFF121212),
//       error: Colors.red.shade300,
//     ),
//     scaffoldBackgroundColor: const Color(0xFF121212),
//     appBarTheme: const AppBarTheme(
//       backgroundColor: Color(0xFF1E1E1E),
//       foregroundColor: Colors.white,
//       elevation: 0,
//     ),
//     cardTheme: CardTheme(
//       color: const Color(0xFF1E1E1E),
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//     ),
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         foregroundColor: Colors.white,
//         backgroundColor: Colors.blue,
//         elevation: 2,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//       ),
//     ),
//     outlinedButtonTheme: OutlinedButtonThemeData(
//       style: OutlinedButton.styleFrom(
//         foregroundColor: Colors.blue,
//         side: const BorderSide(color: Colors.blue),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//       ),
//     ),
//     textButtonTheme: TextButtonThemeData(
//       style: TextButton.styleFrom(
//         foregroundColor: Colors.blue,
//       ),
//     ),
//     inputDecorationTheme: InputDecorationTheme(
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//       ),
//       filled: true,
//       fillColor: const Color(0xFF2C2C2C),
//       contentPadding: const EdgeInsets.all(16),
//     ),
//     bottomNavigationBarTheme: const BottomNavigationBarThemeData(
//       backgroundColor: Color(0xFF1E1E1E),
//       selectedItemColor: Colors.blue,
//       unselectedItemColor: Colors.grey,
//       type: BottomNavigationBarType.fixed,
//       elevation: 8,
//     ),
//     dividerTheme: const DividerThemeData(
//       color: Color(0xFF3E3E3E),
//       thickness: 1,
//     ),
//     textTheme: const TextTheme(
//       titleLarge: TextStyle(
//         fontSize: 22,
//         fontWeight: FontWeight.bold,
//         color: Colors.white,
//       ),
//       titleMedium: TextStyle(
//         fontSize: 18,
//         fontWeight: FontWeight.bold,
//         color: Colors.white,
//       ),
//       bodyLarge: TextStyle(
//         fontSize: 16,
//         color: Colors.white,
//       ),
//       bodyMedium: TextStyle(
//         fontSize: 14,
//         color: Colors.white,
//       ),
//     ),
//   );
// }

import 'package:flutter/material.dart';

class AppTheme {
  // Define core colors
  static const Color primaryColor = Color(0xFF1565C0); // Deep Blue
  static const Color secondaryColor = Color(0xFFFF8F00); // Amber
  static const Color successColor = Color(
    0xFF43A047,
  ); // Green for completed tasks
  static const Color errorColor = Color(
    0xFFE53935,
  ); // Red for errors/high priority
  static const Color warningColor = Color(
    0xFFFB8C00,
  ); // Orange for medium priority
  static const Color infoColor = Color(
    0xFF29B6F6,
  ); // Light Blue for low priority

  // Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: Colors.white,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.black87,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primaryColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primaryColor),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: secondaryColor,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.all(16),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: Color(0xFF757575),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    tabBarTheme: const TabBarTheme(
      labelColor: Colors.white,
      unselectedLabelColor: Color(0xDDFFFFFF),
      indicatorColor: secondaryColor,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(fontWeight: FontWeight.bold),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
    ),
    dividerTheme: DividerThemeData(color: Colors.grey.shade300, thickness: 1),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        letterSpacing: 0.15,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        letterSpacing: 0.15,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.black87,
        letterSpacing: 0.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.black87,
        letterSpacing: 0.25,
      ),
    ),
    // Additional theme elements
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey.shade200,
      disabledColor: Colors.grey.shade300,
      selectedColor: primaryColor.withOpacity(0.2),
      secondarySelectedColor: secondaryColor.withOpacity(0.2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      labelStyle: const TextStyle(color: Colors.black87),
      secondaryLabelStyle: const TextStyle(color: Colors.black87),
      brightness: Brightness.light,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF323232),
      actionTextColor: secondaryColor,
      contentTextStyle: TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
  );

  // Dark theme with improved contrast and accessibility
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: const Color(0xFF1E1E1E),
      error: const Color(0xFFFF5252), // Brighter red for dark theme
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primaryColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.blue.shade300, // Lighter blue for dark theme
        side: BorderSide(color: Colors.blue.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Colors.blue.shade300),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: secondaryColor,
      foregroundColor: Colors.black,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      contentPadding: const EdgeInsets.all(16),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      selectedItemColor: Colors.blue.shade300,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    tabBarTheme: TabBarTheme(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.grey.shade400,
      indicatorColor: secondaryColor,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF3E3E3E),
      thickness: 1,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 0.15,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 0.15,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.white,
        letterSpacing: 0.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.white,
        letterSpacing: 0.25,
      ),
    ),
    // Additional theme elements
    chipTheme: const ChipThemeData(
      backgroundColor: Color(0xFF2C2C2C),
      disabledColor: Color(0xFF3E3E3E),
      selectedColor: Color(0xFF3949AB), // Indigo
      secondarySelectedColor: Color(0xFFFF8F00), // Amber
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      labelStyle: TextStyle(color: Colors.white),
      secondaryLabelStyle: TextStyle(color: Colors.white),
      brightness: Brightness.dark,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF323232),
      actionTextColor: Color(0xFFFFB74D), // Lighter amber for dark theme
      contentTextStyle: TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
  );

  // Helper methods for task priority colors
  static Color getPriorityColor(String priority, {bool isDark = false}) {
    switch (priority.toLowerCase()) {
      case 'high':
        return isDark ? const Color(0xFFFF5252) : errorColor;
      case 'medium':
        return isDark ? const Color(0xFFFFAB40) : warningColor;
      case 'low':
        return isDark ? const Color(0xFF40C4FF) : infoColor;
      default:
        return isDark ? Colors.grey.shade400 : Colors.grey.shade700;
    }
  }

  // Helper for completion status color
  static Color getCompletionColor(bool isCompleted, {bool isDark = false}) {
    return isCompleted
        ? (isDark ? const Color(0xFF69F0AE) : successColor)
        : (isDark ? Colors.grey.shade600 : Colors.grey.shade400);
  }
}
