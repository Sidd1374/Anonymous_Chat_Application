import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final bool isEnabled;
  final TextEditingController inputController; 
  final TextInputType keyboardType;
  final TextInputAction textInputAction; 
  final String hintText;

  const InputField({
    super.key,
    required this.isEnabled,
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
        enabled: isEnabled,

        // Styling
        cursorColor: Theme.of(context).textTheme.bodyMedium?.color,

        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: (isEnabled) 
                  ? (Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(150))
                  : (Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(100)),
            fontWeight: FontWeight.w400,
          ),

          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 18),

          filled: true,
          fillColor: Theme.of(context).colorScheme.secondary,

          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.transparent,
            ),
            borderRadius: BorderRadius.all(Radius.circular(10))
          ),
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