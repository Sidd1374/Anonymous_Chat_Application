import 'package:flutter/material.dart';
// import 'package:lottie/lottie.dart';
import 'login_page.dart';

class EntryPage extends StatelessWidget {
  final double buttonWidth;
  final double borderRadius;

  EntryPage({
    this.buttonWidth = 150.0,
    this.borderRadius = 15,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Center(
          //   child: AspectRatio(
          //     aspectRatio: 1.2,
          //     child: Lottie.asset(
          //       'assets/animation/home_animation_1735286422424.json',
          //       fit: BoxFit.scaleDown,
          //     ),
          //
          //   ),
          // ),

          Center(
            child: Image.asset(
              'assets/animations/Animation - 1735759321649.gif',
              height: 300,
              width: 300,
              fit: BoxFit.contain,
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: SizedBox(
              width: buttonWidth,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text("Continue"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
