import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/app_theme.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              appTheme.currentLogoPath,
              height: 25.sp,
              width: 30.sp,
            ),
            IconButton(
              icon: Icon(
                appTheme.currentTheme == AppTheme.lightTheme
                    ? Icons.dark_mode
                    : Icons.light_mode,
              ),
              onPressed: appTheme.toggleTheme,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Form(
            key: _formKey,
            child: Column(
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
                  "Create Account",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 28.sp,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  "Sign up to start chatting",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 30.h),
                SizedBox(
                  width: 350.w,
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
                SizedBox(height: 20.h),
                SizedBox(
                  width: 350.w,
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
                SizedBox(height: 20.h),
                SizedBox(
                  width: 350.w,
                  child: TextFormField(
                    obscureText: !_isConfirmPasswordVisible,
                    decoration: AppTheme.textFieldDecoration(
                      context,
                      label: "Confirm Password",
                      prefixIcon: Icons.lock,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Theme.of(context).primaryColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                            !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 30.h),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      print('Account created successfully');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(200.w, 50.h),
                  ),
                  child: const Text("Sign Up"),
                ),
                SizedBox(height: 40.h),
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Colors.grey),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Text(
                        "OR Login In With",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Colors.grey),
                    ),
                  ],
                ),
                SizedBox(height: 30.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: () => _navigateToLogin(context),
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
    );
  }
  void _navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }
}
