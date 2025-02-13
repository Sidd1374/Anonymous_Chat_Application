import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 120.h),
            Text(
              "Ready For Some Anonymous Fun ?",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 20.h),
            Lottie.asset(
              'assets/animation/Animation - 1738660125425.lottie',
              height: 200.0,
              repeat: true,
              reverse: true,
              animate: true,
            ),
            SizedBox(height: 80.h),
            ElevatedButton(
                onPressed: () {
                  print('Button Pressed');
                },
                child: Text("Find Someone")),
          ],
        ),
      ),
    );
  }
}
