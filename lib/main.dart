import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/app_theme.dart';
import 'views/entry/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for async in main
  await Firebase.initializeApp(); // Initialize Firebase

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
          return ScreenUtilInit(
            designSize: const Size(360, 800),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'ChatApp',
                theme: appTheme.currentTheme,
                home: LoginPage(),
              );
            },
          );
        },
      ),
    );
  }
}
