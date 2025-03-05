import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final bool          isPrimary;
  final bool          isEnabled;
  final VoidCallback  onPressed;
  final String             text;

  const AppButton({
    super.key,
    required this.isPrimary,
    required this.isEnabled,
    required this.onPressed,
    required this.text
  });

  @override
  Widget build(BuildContext context) {

    return ElevatedButton(
      onPressed: () => {},
      style: ElevatedButton.styleFrom(

        backgroundColor: (isPrimary)
            ? (Theme.of(context).primaryColor)
            : (Theme.of(context).primaryColorLight),
        foregroundColor: (isEnabled)
            ? (Theme.of(context).focusColor.withAlpha(255))
            : (Theme.of(context).focusColor.withAlpha(127)),

        fixedSize: Size(182, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)
        )
      ),

      child: Text(
        text,

        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500
        ),
      )

    );
  }
}
