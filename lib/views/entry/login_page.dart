import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../home/home_page_frame.dart';
import '../../core/app_theme.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();

    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    appTheme.currentLogoPath,
                    height: 25.sp,
                    width: 30.sp,
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  appTheme.currentTheme == AppTheme.lightTheme
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: appTheme.toggleTheme,
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(16.0.w),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 80.h),
                    Image.asset(
                      appTheme.currentLogoPath,
                      height: 80.sp,
                      width: 80.sp,
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      "Welcome!",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 28.sp,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      "Sign in to your account",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: 40.h),
                    SizedBox(
                      width: 350.w,
                      height: 50.h,
                      child: TextFormField(
                        decoration: AppTheme.textFieldDecoration(
                          context,
                          label: "Email",
                          prefixIcon: Icons.email,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: 10.h),
                    SizedBox(
                      width: 350.w,
                      height: 50.h,
                      child: TextFormField(
                        obscureText: !_isPasswordVisible,
                        decoration: AppTheme.textFieldDecoration(
                          context,
                          label: "Password",
                          prefixIcon: Icons.lock,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Theme.of(context).primaryColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          print('Forgot Password Pressed');
                        },
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30.h),
                    ElevatedButton(
                      onPressed: () => _navigateToHome(context),
                      style: AppTheme.elevatedButtonStyle(context),
                      child: Text("Continue", style: TextStyle(fontSize: 16.sp)),
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Expanded(child: Divider(thickness: 1)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                          child: Text("or ", style: TextStyle(fontSize: 14.sp)),
                        ),
                        Expanded(child: Divider(thickness: 1)),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton(
                          onPressed: () => _navigateToRegister(context),
                          style: AppTheme.outlinedButtonStyle(context),
                          child: Image.asset(
                            appTheme.currentLogoPath,
                            height: 30,
                            width: 30,
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            print('Continue with Google');
                          },
                          style: AppTheme.outlinedButtonStyle(context),
                          child: Image.asset(
                            "assets/logo/Google_logo.png",
                            height: 30,
                            width: 30,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomePageFrame()),
    );
  }

  void _navigateToRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterPage()),
    );
  }
}
