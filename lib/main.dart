import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veil_chat_application/views/entry/welcome.dart';
import 'package:veil_chat_application/views/home/container.dart';
import 'firebase_options.dart';
import 'core/app_theme.dart';

import 'package:device_preview/device_preview.dart';
// import 'package:flutter/foundation.dart';
import 'models/user_model.dart';

void main() async {
  // Ensure Flutter Engine is loaded to run async functions before runApp()
  WidgetsFlutterBinding.ensureInitialized();

  // Flutter Initialization
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Check if user data is stored
  final storedUser = await User.getFromPrefs();

  // First time run check provider
  final prefs = await SharedPreferences.getInstance();
  final isFirstRun = prefs.getBool('isFirstRun') ?? true;

  // Starting the App with DevicePreview
  runApp(
    DevicePreview(
      enabled: !bool.fromEnvironment('dart.vm.product'),
      builder: (context) => MyApp(
        isFirstRun: isFirstRun,
        isLoggedIn: storedUser != null,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isFirstRun;
  final bool isLoggedIn;

  const MyApp({super.key, required this.isFirstRun, required this.isLoggedIn});

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
                    locale: DevicePreview.locale(context),
                    builder: DevicePreview.appBuilder,
                    debugShowCheckedModeBanner: false,
                    title: 'ChatApp title',
                    theme: appTheme.currentTheme,
                    // useInheritedMediaQuery: true,

                    // home: isLoggedIn ? HomePageFrame() : Welcome(),
                    home: Welcome(),
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

// // __________________without device preview____________________
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:veil_chat_application/views/entry/welcome.dart';
// import 'package:veil_chat_application/views/home/container.dart';
// // import 'package:veil_chat_application/views/home/homepage.dart';
// import 'firebase_options.dart';
// import 'core/app_theme.dart';
// import 'models/user_model.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );

//   final storedUser = await User.getFromPrefs();

//   final prefs = await SharedPreferences.getInstance();
//   final isFirstRun = prefs.getBool('isFirstRun') ?? true;

//   runApp(
//     MyApp(
//       isFirstRun: isFirstRun,
//       isLoggedIn: storedUser != null,
//     ),
//   );
// }

// class MyApp extends StatelessWidget {
//   final bool isFirstRun;
//   final bool isLoggedIn;

//   const MyApp({super.key, required this.isFirstRun, required this.isLoggedIn});

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => AppTheme(),
//       child: Consumer<AppTheme>(
//         builder: (context, appTheme, _) {
//           return LayoutBuilder(
//             builder: (context, constraints) {
//               final designSize = constraints.maxWidth > constraints.maxHeight
//                   ? const Size(800, 360)
//                   : const Size(360, 800);

//               return ScreenUtilInit(
//                 designSize: designSize,
//                 minTextAdapt: true,
//                 splitScreenMode: true,
//                 builder: (context, child) {
//                   return MaterialApp(
//                     debugShowCheckedModeBanner: false,
//                     title: 'ChatApp title',
//                     theme: appTheme.currentTheme,
//                     home: isLoggedIn
//                         ? HomePageFrame()
//                         : (isFirstRun ? Welcome() : HomePageFrame()),
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
