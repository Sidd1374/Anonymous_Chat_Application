import 'package:flutter/material.dart';

class ToggleButton extends StatefulWidget {
  final VoidCallback?    onPressed;
  final bool          initialState;

  const ToggleButton({
    super.key,
    required this.onPressed,
    required this.initialState
  });

  @override
  State<ToggleButton> createState() => _ToggleButtonState();
}

class _ToggleButtonState extends State<ToggleButton> {
  late bool isToggled;

  @override
  void initState() {
    super.initState();
    isToggled = widget.initialState;
  }

  @override
  Widget build(BuildContext context) {

    return ElevatedButton(
      // Configuration
      onPressed: () {
        setState(() {
          isToggled = !isToggled;
        });

        widget.onPressed?.call();
      },

      // Styling
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        padding: EdgeInsets.zero,
        elevation: 4,

        side: BorderSide(
          color: (isToggled)
                  ? (Theme.of(context).colorScheme.primary)
                  : (Theme.of(context).scaffoldBackgroundColor),
        ),

        minimumSize: Size(40, 24),
        fixedSize: Size(40, 24),

        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      
      // Child Component
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 3),

        child: AnimatedAlign(
          alignment: (isToggled)
                  ? (Alignment.centerRight)
                  : (Alignment.centerLeft),

          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        
          child: Container(
            height: 18, width: 18,
            decoration: BoxDecoration(
              color: (isToggled)
                    ? (Theme.of(context).colorScheme.primary)
                    : (Theme.of(context).scaffoldBackgroundColor),
              borderRadius: BorderRadius.all(Radius.circular(9))
            ),
          ),
        ),
      )
    );

  }
}