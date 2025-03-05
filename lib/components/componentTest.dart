import 'package:flutter/material.dart';
import 'package:veil_chat_application/components/chatActionsBar.dart';

class ComponentTest extends StatelessWidget {
  const ComponentTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Component Test")),

      body: Center(
        child: Column(
          children: [
            // Put your components here

            ChatActionsBar(),

          ],
        ),
      ),
    );
  }
}