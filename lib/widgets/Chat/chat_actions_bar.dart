import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChatActionsBar extends StatelessWidget {
  final TextEditingController inputTextController;
  final Function(String) onSend;

  const ChatActionsBar(
      {super.key, 
      required this.inputTextController, 
      required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      // spacing: 18,

      children: [
        ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.primary,
              fixedSize: Size(50, 50),
              elevation: 4,
              padding: EdgeInsets.all(0),
              shape: const CircleBorder(),
            ),
            onPressed: () {
              onSend('Heart button pressed!');
            },
            child: SvgPicture.asset(
              'assets/icons/icon_heart.svg',
              width: 32,
            )),
        const SizedBox(width: 8),
        Expanded(
            child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(25),
          child: TextField(
            // Configuration
            controller: inputTextController,

            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.send,

            autofocus: true,
            minLines: 1,
            maxLines: 5,

            onSubmitted: (text) {
              onSend(text);
            }, // Implementation of Send function.

            // Styling
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontWeight: FontWeight.w100,
            ),

            cursorColor: Theme.of(context).textTheme.bodyMedium?.color,

            decoration: InputDecoration(
                hintText: "Write a message...",
                hintStyle: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withAlpha(150),
                  fontWeight: FontWeight.w100,
                ),
                fillColor: Theme.of(context).colorScheme.secondary,
                filled: true,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25)),
                    borderSide: BorderSide(color: Colors.transparent)),
                enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25)),
                    borderSide: BorderSide(color: Colors.transparent)),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 14)),
          ),
        )),

        const SizedBox(width: 8),

        ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.primary,
                fixedSize: Size(50, 50),
                padding: EdgeInsets.all(0),
                elevation: 4,
                shape: const CircleBorder(),
                ),
            onPressed: () {
              onSend(inputTextController.text);
            },
            child: SvgPicture.asset(
              'assets/icons/icon_send.svg',
              width: 32,
            )),
      ],
    );
  }
}
