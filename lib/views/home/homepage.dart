import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:veil_chat_application/widgets/button.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Ready For Some Anonymous Fun ?",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 60),
              child: Lottie.asset('assets/animation/ani-1.json'),
            ),
            AppButton(
                isPrimary: true,
                isEnabled: true,
                onPressed: () => {},
                text: "Let's Go")
          ],
        ),
      ),
    );
  }
}
