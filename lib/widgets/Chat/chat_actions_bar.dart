import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChatActionsBar extends StatelessWidget {
  final TextEditingController inputTextController;
  final Function(String) onSend;
  final VoidCallback? onHeartPress;
  final VoidCallback? onCameraPress;
  final bool hasLiked;
  final bool isFriend;

  const ChatActionsBar({
    super.key, 
    required this.inputTextController, 
    required this.onSend,
    this.onHeartPress,
    this.onCameraPress,
    this.hasLiked = false,
    this.isFriend = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      // spacing: 18,

      children: [
        // Heart button - only show if not already friends
        if (!isFriend)
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: hasLiked 
                    ? Colors.red.shade100 
                    : Theme.of(context).colorScheme.secondary,
                foregroundColor: hasLiked 
                    ? Colors.red 
                    : Theme.of(context).colorScheme.primary,
                fixedSize: Size(50, 50),
                elevation: hasLiked ? 6 : 4,
                padding: EdgeInsets.all(0),
                shape: const CircleBorder(),
              ),
              onPressed: onHeartPress,
              child: hasLiked
                  ? Icon(Icons.favorite, color: Colors.red, size: 28)
                  : SvgPicture.asset(
                      'assets/icons/icon_heart.svg',
                      width: 32,
                    )),
          if (!isFriend) const SizedBox(width: 0),

        // Camera button
        ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.primary,
              fixedSize: Size(50, 50),
              elevation: 4,
              padding: EdgeInsets.all(0),
              shape: const CircleBorder(),
            ),
            onPressed: onCameraPress,
            child: SvgPicture.asset(
              'assets/icons/icon_camera_lens.svg',
              width: 32,
            )),
        const SizedBox(width: 0),
        
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
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w500,
              fontSize: 16,
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
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
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
