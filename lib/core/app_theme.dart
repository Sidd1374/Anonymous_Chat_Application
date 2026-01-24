import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'colors.dart'; // Make sure this file defines LightColors and DarkColors

class AppTheme extends ChangeNotifier {
  // === Theme Colors ===
  static const Color primaryColor = Color(0xFFFF964B);
  static const Color darkSecondaryColor = Color(0xFF433F3C);
  static const Color lightSecondaryColor = Color(0xFFFFF3EA);

  // === Light Theme ===
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: LightColors.background,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.light(
      primary: LightColors.primary,
      secondary: lightSecondaryColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: LightColors.background,
      iconTheme: IconThemeData(color: LightColors.primary),
      titleTextStyle: TextStyle(color: LightColors.text, fontSize: 20),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightSecondaryColor,
      border: const OutlineInputBorder(),
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
      bodyMedium: TextStyle(color: LightColors.text),
      bodySmall: TextStyle(color: LightColors.text),
      // titleLarge: TextStyle(color: LightColors.text, fontSize: 20),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: LightColors.secondary,
      contentTextStyle: TextStyle(color: LightColors.text),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: LightColors.secondary,
      titleTextStyle: TextStyle(
        color: LightColors.text,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
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

  // === Dark Theme ===
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: DarkColors.background,
    primaryColor: DarkColors.primary,
    colorScheme: const ColorScheme.dark(
      primary: DarkColors.primary,
      secondary: darkSecondaryColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: DarkColors.background,
      iconTheme: IconThemeData(color: DarkColors.text),
      titleTextStyle: TextStyle(color: DarkColors.textAlt, fontSize: 20),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DarkColors.secondary,
      border: const OutlineInputBorder(),
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
    dialogTheme: const DialogThemeData(
      backgroundColor: DarkColors.secondary,
      titleTextStyle: TextStyle(
        color: DarkColors.text,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(color: DarkColors.text),
    ),
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

  // === Theme Manager (used via Provider) ===
  ThemeMode _themeMode = ThemeMode.system;
  late ThemeData _currentTheme;
  late String _currentLogoPath;

  ThemeMode get themeMode => _themeMode;
  ThemeData get currentTheme => _currentTheme;
  String get currentLogoPath => _currentLogoPath;

  /// Constructor - initializes theme based on system preference
  AppTheme() {
    _initializeTheme();
    // Listen for system brightness changes
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        _onSystemBrightnessChanged;
  }

  void _initializeTheme() {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    if (_themeMode == ThemeMode.system) {
      _currentTheme = brightness == Brightness.dark ? darkTheme : lightTheme;
    } else if (_themeMode == ThemeMode.dark) {
      _currentTheme = darkTheme;
    } else {
      _currentTheme = lightTheme;
    }
    _updateLogoPath();
  }

  void _updateLogoPath() {
    _currentLogoPath = _currentTheme == darkTheme
        ? 'assets/logo/icon-no-bg-white.png'
        : 'assets/logo/icon-black-no-bg.png';
  }

  void _onSystemBrightnessChanged() {
    if (_themeMode == ThemeMode.system) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _currentTheme = brightness == Brightness.dark ? darkTheme : lightTheme;
      _updateLogoPath();
      notifyListeners();
    }
  }

  /// Set theme mode (system, light, or dark)
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    if (mode == ThemeMode.system) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _currentTheme = brightness == Brightness.dark ? darkTheme : lightTheme;
    } else if (mode == ThemeMode.dark) {
      _currentTheme = darkTheme;
    } else {
      _currentTheme = lightTheme;
    }
    _updateLogoPath();
    notifyListeners();
  }

  // Toggle Theme (light <-> dark) - legacy method
  void toggleTheme() {
    if (_currentTheme == lightTheme) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }

  // Reusable Styles
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

  static InputDecoration textFieldDecoration(
    BuildContext context, {
    required String label,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
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
}
