import 'package:flutter/material.dart';

class ChatText extends StatelessWidget {
  final String      text;
  final bool    isSender;

  const ChatText({
    super.key,
    required this.text,
    required this.isSender
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: (isSender)
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.all(Radius.circular(10)),
        boxShadow: [BoxShadow(
          color: Colors.black.withAlpha(25),
          offset: Offset(0, 4),
          blurRadius: 10,
          spreadRadius: 0
        )]
      ),

      child: Text(
        text,

        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}