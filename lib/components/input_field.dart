import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final TextEditingController inputController; 
  final TextInputType keyboardType;
  final TextInputAction textInputAction; 
  final String hintText;

  const InputField({
    super.key,
    required this.inputController,
    required this.keyboardType,
    required this.textInputAction,
    required this.hintText
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextField(
        // Configuration
        controller: inputController,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        minLines: 1, maxLines: 1,

        // Styling
        cursorColor: Theme.of(context).textTheme.bodyMedium?.color,

        style: TextStyle(
          color: Theme.of(context).textTheme.bodySmall?.color,
          fontWeight: FontWeight.w500
        ),

        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(127),
            fontWeight: FontWeight.w500,
          ),

          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 18),

          filled: true,
          fillColor: Theme.of(context).colorScheme.secondary,

          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.transparent,
            ),
            borderRadius: BorderRadius.all(Radius.circular(10))
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.transparent,
            ),
            borderRadius: BorderRadius.all(Radius.circular(10))
          ),
           
        ),
      ),
    );
  }
}