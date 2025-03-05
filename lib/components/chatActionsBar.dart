import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChatActionsBar extends StatelessWidget {
  const ChatActionsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 20,

      children: [

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),

          onPressed: () {}, 

          child: SvgPicture.asset('assets/icons/icon_heart.svg')
        ),

        // TextField(

        // ),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),

          onPressed: () {}, 

          child: SvgPicture.asset('assets/icons/icon_heart.svg')
        ),
      ],
    );
  }
}