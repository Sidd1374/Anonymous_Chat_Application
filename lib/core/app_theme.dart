import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTheme extends ChangeNotifier {
  // Global constants for colors
  static const Color _primaryColor = Color(0xFFFF964B);
  static const Color _darkBackgroundColor = Color(0xFF282725);
  static const Color _lightBackgroundColor = Color(0xFFF1E5DD);
  static const Color _darkSecondaryColor = Color(0xFF433F3C);
  static const Color _lightSecondaryColor = Color(0xFFFFF3EA);

  // Logo paths for themes
  static const String _lightLogoPath = 'assets/logo/icon-no-bg-white.png';
  static const String _darkLogoPath = 'assets/logo/icon-black-no-bg.png';

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _darkBackgroundColor,
    primaryColor: _primaryColor,
    colorScheme: const ColorScheme.dark(
      secondary: _darkSecondaryColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkBackgroundColor,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkSecondaryColor,
      border: const OutlineInputBorder(
        borderSide: BorderSide(color: _primaryColor),
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: _primaryColor),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: _primaryColor),
      ),
      labelStyle: const TextStyle(color: Colors.white),
      hintStyle: const TextStyle(color: Colors.white70),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
      titleLarge: TextStyle(color: Colors.white, fontSize: 20),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: _primaryColor,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    dialogTheme: const DialogTheme(
      backgroundColor: _darkBackgroundColor,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      contentTextStyle: TextStyle(color: Colors.white70),
    ),
  );

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: _lightBackgroundColor,
    primaryColor: _primaryColor,
    colorScheme: const ColorScheme.light(
      secondary: _lightSecondaryColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _lightBackgroundColor,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _lightSecondaryColor,
      border: const OutlineInputBorder(
        borderSide: BorderSide(color: _primaryColor),
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: _primaryColor),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: _primaryColor),
      ),
      labelStyle: const TextStyle(color: Colors.black),
      hintStyle: const TextStyle(color: Colors.black54),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black87),
      titleLarge: TextStyle(color: Colors.black, fontSize: 20),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: _primaryColor,
      contentTextStyle: TextStyle(color: Colors.black),
    ),
    dialogTheme: const DialogTheme(
      backgroundColor: _lightBackgroundColor,
      titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      contentTextStyle: TextStyle(color: Colors.black87),
    ),
  );




  static ButtonStyle elevatedButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
      minimumSize: Size(150.w, 40.h),
    );
  }

  static ButtonStyle outlinedButtonStyle(BuildContext context) {
    return OutlinedButton.styleFrom(
      shape: const CircleBorder(),
      side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      padding: const EdgeInsets.all(16),
    );
  }

  // Input Decorations
  static InputDecoration textFieldDecoration(BuildContext context,
      {required String label, IconData? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: Theme.of(context).inputDecorationTheme.fillColor,
      labelText: label,
      border: Theme.of(context).inputDecorationTheme.border,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: Theme.of(context).primaryColor)
          : null,
      suffixIcon: suffixIcon,
      contentPadding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
    );
  }





  // Theme and logo management
  ThemeData _currentTheme = darkTheme;
  String _currentLogoPath = _lightLogoPath;

  ThemeData get currentTheme => _currentTheme;
  String get currentLogoPath => _currentLogoPath;

  // Toggle between light and dark themes
  void toggleTheme() {
    if (_currentTheme == lightTheme) {
      _currentTheme = darkTheme;
      _currentLogoPath = _lightLogoPath;
    } else {
      _currentTheme = lightTheme;
      _currentLogoPath = _darkLogoPath;
    }
    notifyListeners();
  }

}

