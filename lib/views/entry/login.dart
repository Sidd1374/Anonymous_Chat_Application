import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/app_theme.dart';
import 'register.dart';
import 'about_you.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

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
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isPortrait = constraints.maxHeight > constraints.maxWidth;

            return SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: isPortrait ? 80.h : 40.h),
                        Image.asset(
                          appTheme.currentLogoPath,
                          height: isPortrait ? 80.sp : 60.sp,
                          width: isPortrait ? 80.sp : 60.sp,
                        ),
                        SizedBox(height: isPortrait ? 20.h : 10.h),
                        Text(
                          "Welcome!",
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isPortrait ? 28.sp : 20.sp,
                                  ),
                        ),
                        SizedBox(height: isPortrait ? 10.h : 5.h),
                        Text(
                          "Sign in to your account",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        SizedBox(height: isPortrait ? 40.h : 20.h),
                        SizedBox(
                          width: isPortrait ? 350.w : 300.w,
                          height: 50.h,
                          child: TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: AppTheme.textFieldDecoration(
                              context,
                              label: "Email",
                              prefixIcon: Icons.email,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                  .hasMatch(value)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: 10.h),
                        SizedBox(
                          width: isPortrait ? 350.w : 300.w,
                          height: 50.h,
                          child: TextFormField(
                            obscureText: !_isPasswordVisible,
                            controller: passwordController,
                            keyboardType: TextInputType.visiblePassword,
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
                            onPressed: () async {
                              if (emailController.text.isEmpty) {
                                _showErrorDialog(
                                    "Please enter your email to reset the password.");
                                return;
                              }

                              try {
                                await FirebaseAuth.instance
                                    .sendPasswordResetEmail(
                                  email: emailController.text.trim(),
                                );
                                _showSuccessDialog(
                                    "Password reset email sent! Check your inbox.");
                              } on FirebaseAuthException catch (e) {
                                String message =
                                    "Failed to send password reset email.";
                                if (e.code == 'user-not-found') {
                                  message = "No user found with this email.";
                                }
                                _showErrorDialog1(message);
                              } catch (e) {
                                _showErrorDialog1(
                                    "Something went wrong. Please try again.");
                              }
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
                        SizedBox(height: isPortrait ? 30.h : 20.h),
                        ElevatedButton(
                          onPressed: _loginUser,
                          style: AppTheme.elevatedButtonStyle(context),
                          child: Text(
                            "Continue",
                            style: TextStyle(fontSize: 16.sp),
                          ),
                        ),
                        SizedBox(height: isPortrait ? 20.h : 10.h),
                        Row(
                          children: [
                            Expanded(child: Divider(thickness: 1)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10.w),
                              child: Text(
                                "or ",
                                style: TextStyle(fontSize: 14.sp),
                              ),
                            ),
                            Expanded(child: Divider(thickness: 1)),
                          ],
                        ),
                        SizedBox(height: isPortrait ? 20.h : 10.h),
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
                              onPressed: () async {
                                try {
                                  // Trigger Google Sign-In
                                  final GoogleSignInAccount? googleUser =
                                      await GoogleSignIn().signIn();

                                  if (googleUser == null) {
                                    // The user canceled the sign-in
                                    return;
                                  }

                                  // Obtain the Google Sign-In authentication details
                                  final GoogleSignInAuthentication googleAuth =
                                      await googleUser.authentication;

                                  // Create a new credential for Firebase
                                  final credential =
                                      GoogleAuthProvider.credential(
                                    accessToken: googleAuth.accessToken,
                                    idToken: googleAuth.idToken,
                                  );

                                  // Sign in to Firebase with the Google credential
                                  await FirebaseAuth.instance
                                      .signInWithCredential(credential);

                                  // Navigate to the home page after successful login
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => AboutYou()),
                                  );
                                } catch (e) {
                                  _showErrorDialog(
                                      "Google Sign-In failed. Please try again.");
                                }
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
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _navigateToHome(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AboutYou()),
    );
  }

  void _navigateToRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Register()),
    );
  }

  Future<void> _loginUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        final email = emailController.text.trim();
        final password = passwordController.text;

        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);

        print("User logged in: ${userCredential.user?.uid}");
        _navigateToHome(context);
      } on FirebaseAuthException catch (e) {
        String message = 'Login failed';
        if (e.code == 'user-not-found') {
          message = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          message = 'Wrong password.';
        }
        _showErrorDialog(message);
      } catch (e) {
        _showErrorDialog("Something went wrong.");
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Login Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog1(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }
}
