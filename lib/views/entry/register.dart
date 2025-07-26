import 'package:veil_chat_application/views/entry/about_you.dart';
import 'package:veil_chat_application/views/home/container.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/app_theme.dart';
import 'login.dart';
import '../../widgets/docs_dialogs.dart';
import '../../models/user_model.dart' as app_user;
import '../../services/firestore_service.dart';

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
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                // maxWidth: 400, // Responsive max width for desktop/tablet
                ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    Center(
                      child: Image.asset(
                        appTheme.currentLogoPath,
                        height: 80,
                        width: 80,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        "Create Account",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        "Sign up to start chatting",
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
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
                    const SizedBox(height: 20),
                    TextFormField(
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
                    const SizedBox(height: 20),
                    TextFormField(
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
                    const SizedBox(height: 10),
                    Row(
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
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              const Text(
                                "Agree to Our ",
                                style: TextStyle(fontSize: 12),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Show terms
                                  showTermsDialog(context);
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
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
                            UserCredential userCredential = await FirebaseAuth.instance
                                .createUserWithEmailAndPassword(
                              email: email,
                              password: password,
                            );

                            if (userCredential.user != null) {
                              final newUser = app_user.User(
                                uid: userCredential.user!.uid,
                                email: email,
                                fullName: "", // Will be updated in the 'About You' screen
                                createdAt: Timestamp.now(),
                                profilePicUrl: null,
                                gender: null,
                                age: null,
                                interests: [], // Empty list for interests
                                verificationLevel: 1, // Default to Basic verification
                                chatPreferences: app_user.ChatPreferences(
                                  matchWithGender: "Any",
                                  minAge: 0,
                                  maxAge: 0,
                                  onlyVerified: false,
                                ),
                                privacySettings: app_user.PrivacySettings(
                                  showProfilePicToFriends: true,
                                  showProfilePicToStrangers: false,
                                ),
                              );

                              await FirestoreService().createUser(newUser);
                            }

                            // Navigate to the next page after successful registration
                            _navigateToAbout(context);
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
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14.0),
                          child: Text(
                            "Sign Up",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Colors.grey)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            "OR Login In With",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        const Expanded(child: Divider(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 25),
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
                    const SizedBox(height: 25),
                  ],
                ),
              ),
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

  void _navigateToAbout(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userDoc = await FirestoreService().getUser(currentUser.uid);
      if (userDoc.exists) {
        final user = app_user.User.fromJson(userDoc.data()!);
        await app_user.User.saveToPrefs(user);
      }
    }
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => EditInformation(
                editType: 'about',
              )),
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
