import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTheme extends ChangeNotifier {
  // Global constants for colors
  static const Color primaryColor = Color(0xFFFF964B);
  static const Color darkBackgroundColor = Color(0xFF282725);
  static const Color lightBackgroundColor = Color(0xFFF1E5DD);
  static const Color darkSecondaryColor = Color(0xFF433F3C);
  static const Color lightSecondaryColor = Color(0xFFFFF3EA);

  static const Color darkSelectedIconColor = primaryColor;
  static const Color darkUnselectedIconColor = Color(0xFFDDDDDD);
  static const Color lightSelectedIconColor = primaryColor;
  static const Color lightUnselectedIconColor = lightSecondaryColor;


  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackgroundColor,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.dark(
      secondary: darkSecondaryColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackgroundColor,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSecondaryColor,
      border: const OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor),
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor),
      ),
      labelStyle: const TextStyle(color: Colors.white),
      hintStyle: const TextStyle(color: Colors.white70),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
      titleLarge: TextStyle(color: Colors.white, fontSize: 20),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: primaryColor,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    dialogTheme: const DialogTheme(
      backgroundColor: darkBackgroundColor,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      contentTextStyle: TextStyle(color: Colors.white70),
    ),
    // bottomNavigationBarTheme: bottomNavigationBarThemeDark,

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: darkSecondaryColor,
      selectedItemColor: darkSelectedIconColor,
      unselectedItemColor: darkUnselectedIconColor,
      selectedIconTheme: const IconThemeData(color: darkSelectedIconColor),
      unselectedIconTheme: const IconThemeData(color: darkUnselectedIconColor),
      selectedLabelStyle: TextStyle(color: darkSelectedIconColor),
      unselectedLabelStyle: const TextStyle(color: darkUnselectedIconColor),

      elevation: 8.0,
      type: BottomNavigationBarType.fixed,
    ),

  );

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBackgroundColor,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.light(
      secondary: lightSecondaryColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightBackgroundColor,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightSecondaryColor,
      border: const OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor),
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor),
      ),
      labelStyle: const TextStyle(color: Colors.black),
      hintStyle: const TextStyle(color: Colors.black54),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black87),
      titleLarge: TextStyle(color: Colors.black, fontSize: 20),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: primaryColor,
      contentTextStyle: TextStyle(color: Colors.black),
    ),
    dialogTheme: const DialogTheme(
      backgroundColor: lightBackgroundColor,
      titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      contentTextStyle: TextStyle(color: Colors.black87),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: primaryColor,
      selectedItemColor: lightSelectedIconColor,
      unselectedItemColor: lightUnselectedIconColor,
      selectedIconTheme: const IconThemeData(color: lightSelectedIconColor),
      unselectedIconTheme: IconThemeData(color: lightUnselectedIconColor),
      selectedLabelStyle: const TextStyle(color: lightSelectedIconColor),
      unselectedLabelStyle: TextStyle(color: lightUnselectedIconColor),
      elevation: 8.0,
      type: BottomNavigationBarType.fixed,
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
  String _currentLogoPath = 'assets/logo/icon-no-bg-white.png';
  Color containerColor = primaryColor;


  ThemeData get currentTheme => _currentTheme;
  String get currentLogoPath => _currentLogoPath;

  // Toggle between light and dark themes
  void toggleTheme() {
    if (_currentTheme == lightTheme) {
      _currentTheme = darkTheme;
      _currentLogoPath = 'assets/logo/icon-no-bg-white.png';
      containerColor = primaryColor;
    } else {
      _currentTheme = lightTheme;
      _currentLogoPath = 'assets/logo/icon-black-no-bg.png';
      containerColor = lightSecondaryColor;
    }
    notifyListeners();
  }
}
