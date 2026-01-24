// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:firebase_core/firebase_core.dart';
// // import 'package:firebase_app_check/firebase_app_check.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:veil_chat_application/services/firestore_service.dart';
// import 'package:veil_chat_application/views/entry/welcome.dart';
// import 'package:veil_chat_application/views/home/container.dart';
// import 'package:firebase_auth/firebase_auth.dart' hide User;
// import 'firebase_options.dart';
// import 'core/app_theme.dart';
// import 'views/entry/login.dart';

// import 'package:device_preview/device_preview.dart';
// // import 'package:flutter/foundation.dart';
// import 'models/user_model.dart';

// void main() async {
//   // Ensure Flutter Engine is loaded to run async functions before runApp()
//   WidgetsFlutterBinding.ensureInitialized();

//   // Flutter Initialization
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );

//   // First time run check provider
//   final prefs = await SharedPreferences.getInstance();
//   final isFirstRun = prefs.getBool('isFirstRun') ?? true;
//   final isLoggedIn = prefs.getString('uid') != null;

//   print('Is user logged in (from SharedPreferences or Firebase Auth): $isLoggedIn');
//   // Starting the App with DevicePreview
//   runApp(
//     DevicePreview(
//       enabled: !bool.fromEnvironment('dart.vm.product'),
//       builder: (context) => MyApp(
//         isFirstRun: isFirstRun,
//         isLoggedIn: isLoggedIn,
//       ),
//     ),
//   );
// }

// class MyApp extends StatelessWidget {
//   final bool isFirstRun;
//   final bool isLoggedIn;

//   const MyApp({super.key, required this.isFirstRun, required this.isLoggedIn});

//   @override
//   Widget build(BuildContext context) {
//     // Class needed for Theme Toggle
//     return ChangeNotifierProvider(
//       create: (_) => AppTheme(),
//       child: Consumer<AppTheme>(
//         builder: (context, appTheme, _) {
//           return LayoutBuilder(
//             builder: (context, constraints) {
//               // Dynamically set designSize based on orientation
//               final designSize = constraints.maxWidth > constraints.maxHeight
//                   ? const Size(800, 360) // Landscape
//                   : const Size(360, 800); // Portrait

//               return ScreenUtilInit(
//                 designSize: designSize,
//                 minTextAdapt: true,
//                 splitScreenMode: true,
//                 builder: (context, child) {
//                   return MaterialApp(
//                     locale: DevicePreview.locale(context),
//                     builder: DevicePreview.appBuilder,
//                     debugShowCheckedModeBanner: false,
//                     title: 'ChatApp title',
//                     theme: appTheme.currentTheme,
//                     // useInheritedMediaQuery: true,

//                     // home: isLoggedIn ? HomePageFrame() : Welcome(),
//                     home: isLoggedIn
//                         ? HomePageFrame()
//                         : (isFirstRun ? Welcome() : Login()),
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

// // __________________without device preview____________________
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veil_chat_application/views/entry/welcome.dart';
import 'package:veil_chat_application/views/home/container.dart';
import 'package:veil_chat_application/services/presence_service.dart';
import 'firebase_options.dart';
import 'core/app_theme.dart';
// import 'models/user_model.dart';
import 'views/entry/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final isFirstRun = prefs.getBool('isFirstRun') ?? true;
  final isLoggedIn = prefs.getString('uid') != null;
  final userId = prefs.getString('uid');

  runApp(
    MyApp(
      isFirstRun: isFirstRun,
      isLoggedIn: isLoggedIn,
      userId: userId,
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool isFirstRun;
  final bool isLoggedIn;
  final String? userId;

  const MyApp({
    super.key,
    required this.isFirstRun,
    required this.isLoggedIn,
    this.userId,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final PresenceService _presenceService = PresenceService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Set user online when app starts
    if (widget.userId != null) {
      _presenceService.setOnlineStatus(widget.userId!, true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Set user offline when app is disposed
    if (widget.userId != null) {
      _presenceService.goOffline(widget.userId!);
    }

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (widget.userId == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        // App is in foreground - set online
        _presenceService.setOnlineStatus(widget.userId!, true);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App is in background or closed - set offline
        _presenceService.setOnlineStatus(widget.userId!, false);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppTheme(),
      child: Consumer<AppTheme>(
        builder: (context, appTheme, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final designSize = constraints.maxWidth > constraints.maxHeight
                  ? const Size(800, 360)
                  : const Size(360, 800);

              return ScreenUtilInit(
                designSize: designSize,
                minTextAdapt: true,
                splitScreenMode: true,
                builder: (context, child) {
                  return MaterialApp(
                    debugShowCheckedModeBanner: false,
                    title: 'ChatApp title',
                    theme: appTheme.currentTheme,
                    home: widget.isLoggedIn
                        ? HomePageFrame()
                        : (widget.isFirstRun ? Welcome() : Login()),
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
