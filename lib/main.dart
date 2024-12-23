import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import provider package
import 'app_theme.dart';
import 'LoginPage.dart';

void main() {
  runApp(MyApp());
}

class ThemeChanger extends ChangeNotifier {
  ThemeData _currentTheme = AppTheme.darkPurpleTheme;

  ThemeData get currentTheme => _currentTheme;

  void setTheme(ThemeData theme) {
    _currentTheme = theme;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeChanger(),
      child: Consumer<ThemeChanger>(
        builder: (context, themeChanger, _) {
          return MaterialApp(
            title: 'ChatApp',
            theme: themeChanger.currentTheme,
            home: LoginPage(),
          );
        },
      ),
    );
  }
}
