import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:veil_chat_application/core/constants.dart';
import 'package:veil_chat_application/views/entry/login.dart';
import 'package:veil_chat_application/widgets/button.dart';

class Welcome extends StatelessWidget {
  final double buttonWidth;
  final double borderRadius;

  const Welcome({
    super.key,
    this.buttonWidth = 150.0,
    this.borderRadius = 15,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 30,
          children: [
            Text(
              TextConstants.appName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Lottie.asset("assets/animation/ani-1.json"),
            Text(
              TextConstants.welcomeText,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            AppButton(
              isPrimary: true,
              isEnabled: true,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Login()),
              ),
              text: "Continue",
            ),
          ],
        ),
      ),
    );
  }
}
