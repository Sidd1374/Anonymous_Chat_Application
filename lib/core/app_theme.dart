import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:veil_chat_application/components/colors.dart';

class AppTheme extends ChangeNotifier {
  // Global constants for colors
  static const Color primaryColor = Color(0xFFFF964B);
  static const Color darkBackgroundColor = Color(0xFF282725);
  static const Color lightBackgroundColor = Color(0xFFF1E5DD);
  static const Color darkSecondaryColor = Color(0xFF433F3C);
  static const Color lightSecondaryColor = Color(0xFFFFF3EA);

  static const Color darkSelectedIconColor = lightBackgroundColor;
  static const Color darkUnselectedIconColor = Color(0xFFDDDDDD);
  static const Color lightSelectedIconColor = Color(0xFF282725);
  static const Color lightUnselectedIconColor = lightSecondaryColor;

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: DarkColors.background,
    primaryColor: DarkColors.primary,
    colorScheme: const ColorScheme.dark(
      primary: DarkColors.primary,
      secondary: darkSecondaryColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: DarkColors.secondary,
      iconTheme: IconThemeData(color: DarkColors.text),
      titleTextStyle: TextStyle(color: DarkColors.textAlt, fontSize: 20),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DarkColors.secondary,
      border: const OutlineInputBorder(
        borderSide: BorderSide(color: DarkColors.primary),
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: DarkColors.primary),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: DarkColors.primary),
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
      bodyLarge: TextStyle(color: DarkColors.text),
      bodyMedium: TextStyle(color: DarkColors.textAlt),
      bodySmall: TextStyle(color: DarkColors.text),
      titleLarge: TextStyle(color: DarkColors.text, fontSize: 20),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: DarkColors.secondary,
      contentTextStyle: TextStyle(color: DarkColors.text),
    ),
    dialogTheme: const DialogTheme(
      backgroundColor: DarkColors.secondary,
      titleTextStyle: TextStyle(
          color: DarkColors.text, fontSize: 20, fontWeight: FontWeight.bold),
      contentTextStyle: TextStyle(color: DarkColors.text),
    ),
    // bottomNavigationBarTheme: bottomNavigationBarThemeDark,

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: DarkColors.secondary,
      selectedItemColor: DarkColors.primary,
      unselectedItemColor: Colors.transparent,
      selectedIconTheme: IconThemeData(color: DarkColors.text),
      unselectedIconTheme: IconThemeData(color: DarkColors.text),
      selectedLabelStyle: TextStyle(color: DarkColors.textAlt),
      unselectedLabelStyle: const TextStyle(color: DarkColors.textAlt),
      elevation: 8.0,
      type: BottomNavigationBarType.fixed,
    ),
  );

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: LightColors.background,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.light(
      primary: LightColors.primary,
      secondary: lightSecondaryColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: LightColors.secondary,
      iconTheme: IconThemeData(color: LightColors.primary),
      titleTextStyle: TextStyle(color: LightColors.textAlt, fontSize: 20),
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
      backgroundColor: LightColors.primary,
      foregroundColor: LightColors.textAlt,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: LightColors.text),
      bodyMedium: TextStyle(color: LightColors.textAlt),
      bodySmall: TextStyle(color: LightColors.text),
      titleLarge: TextStyle(color: LightColors.text, fontSize: 20),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: LightColors.secondary,
      contentTextStyle: TextStyle(color: LightColors.text),
    ),
    dialogTheme: const DialogTheme(
      backgroundColor: LightColors.secondary,
      titleTextStyle: TextStyle(
          color: LightColors.text, fontSize: 20, fontWeight: FontWeight.bold),
      contentTextStyle: TextStyle(color: LightColors.text),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: LightColors.primary,
      selectedItemColor: LightColors.secondary,
      unselectedItemColor: Colors.transparent,
      selectedIconTheme: const IconThemeData(color: LightColors.text),
      unselectedIconTheme: IconThemeData(color: LightColors.textAlt),
      selectedLabelStyle: const TextStyle(color: LightColors.text),
      unselectedLabelStyle: TextStyle(color: LightColors.textAlt),
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
