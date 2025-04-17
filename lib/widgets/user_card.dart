import 'package:flutter/material.dart';

class HorizontalUserCard extends StatelessWidget {
  final VoidCallback? onPressed;
  // Some functionality to get User Details
  // Because we need to know if user is verified or not.

  const HorizontalUserCard({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {

    return ElevatedButton(
      onPressed: onPressed,

      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).textTheme.bodySmall?.color
      ),

      child: Row(
        children: [
          
        ],
      )
    );

  }
}