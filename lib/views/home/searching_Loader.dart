import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:veil_chat_application/widgets/button.dart';

class LoaderScreen extends StatelessWidget {
  final double buttonWidth;
  final double borderRadius;

  const LoaderScreen({
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
          children: [
            Lottie.asset("assets/animation/ani-3.json"),
            SizedBox(height: 20),
            Text(
              'Finding the perfect one for you...',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 40),
            AppButton(
              isPrimary: true,
              isEnabled: true,
              onPressed: () => Navigator.pop(context),
              text: "Cancel",
            ),
          ],
        ),
      ),
    );
  }
}
