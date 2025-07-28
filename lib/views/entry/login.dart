import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:veil_chat_application/services/firestore_service.dart';
import 'package:veil_chat_application/views/home/container.dart';

import '../../core/app_theme.dart';
import 'register.dart';
import 'about_you.dart';
import 'package:veil_chat_application/models/user_model.dart' as mymodel;

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
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

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
              Image.asset(
                appTheme.currentLogoPath,
                height: 30,
                width: 36,
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
        body: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? 400 : 800,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 32 : 16,
                  vertical: isWide ? 32 : 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Center(
                            child: Image.asset(
                              appTheme.currentLogoPath,
                              height: 100,
                              width: 100,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              "Welcome!",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              "Sign in to your account",
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                      TextFormField(
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
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
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
                              fontSize: 12,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loginUser,
                          style: AppTheme.elevatedButtonStyle(context),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14.0),
                            child: Text(
                              "Continue",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: Divider(thickness: 1)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "or ",
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          Expanded(child: Divider(thickness: 1)),
                        ],
                      ),
                      SizedBox(height: 16),
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
                                final GoogleSignInAccount? googleUser =
                                    await _googleSignIn.signIn();

                                if (googleUser == null) {
                                  return;
                                }

                                final GoogleSignInAuthentication googleAuth =
                                    await googleUser.authentication;

                                final credential =
                                    GoogleAuthProvider.credential(
                                  accessToken: googleAuth.accessToken,
                                  idToken: googleAuth.idToken,
                                );

                                await FirebaseAuth.instance
                                    .signInWithCredential(credential);

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          EditInformation(editType: 'About')),
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
          ),
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

  void _navigateToRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Register()),
    );
  }

  Future<void> _loginUser() async {
    // if (_formKey.currentState!.validate()) {
    //   try {
    //     final email = emailController.text.trim();
    //     final password = passwordController.text;

    //     UserCredential userCredential = await FirebaseAuth.instance
    //         .signInWithEmailAndPassword(email: email, password: password);

    // Save user data to SharedPreferences or any other storage if needed
    // If you want to save user data, implement the saveToPrefs method in your User class.
    // Example:
    if (_formKey.currentState!.validate()) {
      try {
        final email = emailController.text.trim();
        final password = passwordController.text;
        // print("User logged in: ${userCredential.user?.uid}");

        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);

        if (userCredential.user != null) {
          final userDoc =
              await FirestoreService().getUser(userCredential.user!.uid);
          if (userDoc.exists) {
            final user = mymodel.User.fromJson(userDoc.data()!);
            await mymodel.User.saveToPrefs(user);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePageFrame()),
            );
          } else {
            _showErrorDialog("User data not found in Firestore.");
          }
        }
      } on FirebaseAuthException catch (e) {
        String message = 'Login failed';
        if (e.code == 'user-not-found') {
          message = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          message = 'Wrong password.';
        }
        _showErrorDialog(message);
      } catch (e) {
        _showErrorDialog(e.toString());
      }
    }
  }

  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(builder: (context) => HomePageFrame()),
  //       );
  //     } catch (e) {
  //       _showErrorDialog("Something went wrong.");
  //     }
  //   }
  // }

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
