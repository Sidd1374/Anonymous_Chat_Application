import 'package:flutter/widgets.dart';

class LightColors {
  static const background = Color(0xFFF1E5DD);
  static const primary    = Color(0xFFFF964B);
  static const secondary  = Color(0xFFFFF3EA);
  static const text       = Color(0xFF282725);
  static const textAlt    = Color(0xFFF1E5DD);
}

class DarkColors {
  static const background = Color(0xFF282725);
  static const primary    = Color(0xFFFF964B);
  static const secondary  = Color(0xFF433F3C);
  static const text       = Color(0xFFFFF5EE);
  static const textAlt    = Color(0xFFFFF5EE);
}

/**
  These colors need to be assigned to respective themes (light and dark).
  I am using `Theme.of(context)` to access default colors, so to make it
  work seamlessly, we need to assign these colors to each theme (light 
  and dark) of our app.

  This should be in `main.dart`:

  return MaterialApp(

    theme: ThemeData(

      brightness: Brightness.light,
      scaffoldBackgroundColor: LightColors.background,
      primaryColor: LightColors.primary,

      colorScheme: ColorScheme.light(
        primary: LightColors.primary,
        secondary: LightColors.secondary,
      ),

      textTheme: TextTheme(
        bodySmall: TextStyle(color: LightColors.text),
        bodyMedium: TextStyle(color: LightColors.textAlt)
      ),
    ),

    darkTheme: ThemeData(

      brightness: Brightness.dark,
      scaffoldBackgroundColor: DarkColors.background,
      primaryColor: DarkColors.primary,

      colorScheme: ColorScheme.dark(
        primary: DarkColors.primary,
        secondary: DarkColors.secondary,
      ),

      textTheme: TextTheme(
        bodySmall: TextStyle(color: DarkColors.text),
        bodyMedium: TextStyle(color: DarkColors.textAlt)
      ),
    ),
    themeMode: ThemeMode.system
  );

*/