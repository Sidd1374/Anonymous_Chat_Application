import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veil_chat_application/views/entry/welcome.dart';
import 'package:veil_chat_application/views/home/homepage.dart';
import 'firebase_options.dart';
import 'core/app_theme.dart';

void main() async {

  // Ensure Flutter Engine is loaded to run async functions before runApp()
  WidgetsFlutterBinding.ensureInitialized();
  
  // Flutter Initialization
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // First time run check provider
  final prefs = await SharedPreferences.getInstance();
  final isFirstRun = prefs.getBool('isFirstRun') ?? true;

  // Firebase Platform Checks
  // await FirebaseAppCheck.instance.activate(
  //   androidProvider: AndroidProvider.debug,
  //   appleProvider: AppleProvider.debug,
  // );

  // Starting the App
  runApp(MyApp(isFirstRun: isFirstRun));
}

class MyApp extends StatelessWidget {
  final bool isFirstRun;

  const MyApp({
    super.key,
    required this.isFirstRun
  });

  @override
  Widget build(BuildContext context) {

    // Class needed for Theme Toggle
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

                    home: isFirstRun ? Welcome() : FriendsList()
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
