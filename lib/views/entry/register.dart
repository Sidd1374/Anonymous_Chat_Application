import 'package:veil_chat_application/views/home/container.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/app_theme.dart';
import 'login.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isChecked = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

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
                    controller: emailController,
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
                    controller: passwordController,
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
                    controller: confirmPasswordController,
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
                Container(
                  alignment: Alignment.bottomLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _isChecked,
                        onChanged: (bool? newValue) {
                          setState(() {
                            _isChecked = newValue!;
                          });
                        },
                        activeColor: Theme.of(context).primaryColor,
                        checkColor: Colors.white,
                        tristate: false,
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        visualDensity: VisualDensity.adaptivePlatformDensity,
                        autofocus: false,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Agree to Our ",
                            style: TextStyle(fontSize: 12),
                          ),
                          TextButton(
                            onPressed: () {
                              print('Terms & Conditions tapped');
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              // tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              "Terms & Conditions",
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      // If form validation fails, return early
                      return;
                    }

                    if (!_isChecked) {
                      _showErrorDialog(
                          "You must agree to the Terms & Conditions to proceed.");
                      return;
                    }

                    final email = emailController.text.trim();
                    final password = passwordController.text.trim();
                    final confirmPassword =
                        confirmPasswordController.text.trim();

                    if (password != confirmPassword) {
                      _showErrorDialog(
                          "Password and Confirm Password do not match.");
                      return;
                    }

                    try {
                      // Firebase Authentication logic to register the user
                      await FirebaseAuth.instance
                          .createUserWithEmailAndPassword(
                        email: email,
                        password: password,
                      );

                      // Navigate to the next page after successful registration
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => HomePageFrame()),
                      );
                    } on FirebaseAuthException catch (e) {
                      String errorMessage =
                          "Registration failed. Please try again.";
                      if (e.code == 'email-already-in-use') {
                        errorMessage = "This email is already in use.";
                      } else if (e.code == 'weak-password') {
                        errorMessage = "The password is too weak.";
                      } else if (e.code == 'invalid-email') {
                        errorMessage = "The email address is invalid.";
                      }
                      _showErrorDialog(errorMessage);
                    } catch (e) {
                      _showErrorDialog(
                          "An unexpected error occurred. Please try again.");
                    }
                  },
                  style: AppTheme.elevatedButtonStyle(context),
                  child: const Text("Sign Up"),
                ),
                SizedBox(height: 30.h),
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
                SizedBox(height: 25.h),
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
                      onPressed: () async {
                        try {
                          print("Google Sign-In started");
                          final GoogleSignInAccount? googleUser =
                              await GoogleSignIn().signIn();
                          print("Google User: $googleUser");

                          if (googleUser == null) {
                            // The user canceled the sign-in
                            return;
                          }

                          // Obtain the Google Sign-In authentication details
                          final GoogleSignInAuthentication googleAuth =
                              await googleUser.authentication;

                          // Create a new credential for Firebase
                          final credential = GoogleAuthProvider.credential(
                            accessToken: googleAuth.accessToken,
                            idToken: googleAuth.idToken,
                          );

                          // Sign in to Firebase with the Google credential
                          await FirebaseAuth.instance
                              .signInWithCredential(credential);

                          // Navigate to the home page after successful sign-in
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HomePageFrame()),
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
                SizedBox(height: 25.h),
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
      MaterialPageRoute(builder: (context) => Login()),
    );
  }

  void showCodeInputDialog(BuildContext context) {
    final TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: const Text("Enter Code"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  letterSpacing: 8.0, // Space for the 6 underscores
                  fontSize: 20.0,
                ),
                decoration: const InputDecoration(
                  hintText: "______",
                  counterText: "hello",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Add resend functionality here
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange),
                    child: const Text("Resend"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (context) => HomePageFrame()),
                      );
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text("Submit"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
