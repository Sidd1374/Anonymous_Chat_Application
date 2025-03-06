import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChatActionsBar extends StatelessWidget {
  final TextEditingController inputTextController = TextEditingController();

  ChatActionsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 18,

      children: [

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.primary,

            fixedSize: Size(50, 50),
            padding: EdgeInsets.all(0)
          ),

          onPressed: () {}, 

          child: SvgPicture.asset(
            'assets/icons/icon_heart.svg',
            width: 32,
          )
        ),

        Expanded(child: TextField(

          // Configuration
          controller: inputTextController,

          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.send,

          autofocus: true,
          minLines: 1,
          maxLines: 5,

          onSubmitted: (String inputText) {},   // Implementation of Send function.

          // Styling
          style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontWeight: FontWeight.w100,
          ),

          decoration: InputDecoration(

            hintText: "Write a message...",
            hintStyle: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(150),
              fontWeight: FontWeight.w100,
            ),

            fillColor: Theme.of(context).colorScheme.secondary,
            filled: true,

            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(25)),
              borderSide: BorderSide(
                color: Colors.transparent
              )
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(25)),
              borderSide: BorderSide(
                color: Colors.transparent
              )
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(25)),
              borderSide: BorderSide(
                color: Colors.transparent
              )
            ),

            contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 14)

          ),
        )),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.primary,

            fixedSize: Size(50, 50),
            padding: EdgeInsets.all(0)
          ),

          onPressed: () {}, 

          child: SvgPicture.asset(
            'assets/icons/icon_send.svg',
            width: 32,
          )
        ),
      ],
    );
  }
}