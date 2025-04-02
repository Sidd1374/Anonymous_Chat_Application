import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'core/app_theme.dart';
import 'views/entry/login_page.dart';
import 'views/home/home_page_frame.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for async in main
  await Firebase.initializeApp(); // Initialize Firebase

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppTheme(),
      child: Consumer<AppTheme>(
        builder: (context, appTheme, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              // Dynamically set designSize based on orientation
              final designSize = constraints.maxWidth > constraints.maxHeight
                  ? const Size(800, 360) // Landscape
                  : const Size(360, 800); // Portrait

              return ScreenUtilInit(
                designSize: designSize,
                minTextAdapt: true,
                splitScreenMode: true,
                builder: (context, child) {
                  return MaterialApp(
                    debugShowCheckedModeBanner: false,
                    title: 'ChatApp',
                    theme: appTheme.currentTheme,
                    home: HomePageFrame(),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
