import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'main.dart';  // Import ThemeChanger

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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.chat_bubble_outline, color: Theme.of(context).iconTheme.color),
                const SizedBox(width: 10),
                Text("ChatApp", style: Theme.of(context).appBarTheme.titleTextStyle),
              ],
            ),
            IconButton(
              icon: Icon(Icons.settings, color: Theme.of(context).iconTheme.color),
              onPressed: () {
                _showThemeDialog(context);
              },
            ),
          ],
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Welcome!",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Sign in to your account",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                      labelText: "Email",
                      border: Theme.of(context).inputDecorationTheme.border,
                      prefixIcon: Icon(Icons.email, color: Theme.of(context).primaryColor),
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
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                      labelText: "Password",
                      border: Theme.of(context).inputDecorationTheme.border,
                      prefixIcon: Icon(Icons.lock, color: Theme.of(context).primaryColor),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
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
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        print('Logged in successfully');
                      }
                    },
                    child: const Text("Sign In"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Divider with OR text
                  Row(
                    children: const [
                      Expanded(
                        child: Divider(
                          color: Colors.grey,
                          height: 1,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text("OR", style: TextStyle(color: Colors.grey)),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.grey,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Google sign-in button
                  OutlinedButton.icon(
                    onPressed: () {
                      // Add Google sign-in functionality
                      print('Continue with Google');
                    },
                    icon: const Icon(
                      Icons.account_circle, // Placeholder for Google icon
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Continue with Google",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white, // Button color
                      side: BorderSide(color: Colors.white, width: 2), // Border color and width for the entire button
                      minimumSize: const Size(double.infinity, 50), // Full width button
                      padding: const EdgeInsets.symmetric(vertical: 15), // Adjust padding for better button size
                    ),
                  ),


                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      GestureDetector(
                        onTap: () {
                          print('Navigate to register page');
                        },
                        child: Text(
                          "Register Now",
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose a Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Dark - Purple'),
                onTap: () {
                  context.read<ThemeChanger>().setTheme(AppTheme.darkPurpleTheme);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Dark - Orange'),
                onTap: () {
                  context.read<ThemeChanger>().setTheme(AppTheme.darkOrangeTheme);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Dark - Blue'),
                onTap: () {
                  context.read<ThemeChanger>().setTheme(AppTheme.darkBlueTheme);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}


