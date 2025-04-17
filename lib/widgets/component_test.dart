import 'package:flutter/material.dart';
import 'package:veil_chat_application/widgets/button.dart';
import 'package:veil_chat_application/widgets/chat_actions_bar.dart';
import 'package:veil_chat_application/widgets/input_field.dart';
import 'package:veil_chat_application/widgets/toggle_button.dart';

class ComponentTest extends StatelessWidget {
  const ComponentTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Component Test")),

      body: Center(
        child: Column(
          spacing: 10,
          children: [
            // Put your components here

            AppButton(
              isPrimary: true,
              isEnabled: true,
              onPressed: () {},
              text: "Button",
            ),

            AppButton(
              isPrimary: false,
              isEnabled: true,
              onPressed: () {},
              text: "Button",
            ),

            ChatActionsBar(
              inputTextController: TextEditingController(),
              onSend: (s) {},
            ),

            InputField(
              inputController: TextEditingController(),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              isPassword: false,
              hintText: "Email",
            ),

            InputField(
              inputController: TextEditingController(),
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.next,
              isPassword: true,
              hintText: "Password",
            ),

            Row(
              children: [
                Spacer(flex: 1),

                ToggleButton(
                  onPressed: () {},
                  initialState: false,
                ),

                Spacer(flex: 1),

                ToggleButton(
                  onPressed: () {},
                  initialState: true,
                ),

                Spacer(flex: 1),
              ],
            ),

          ],
        ),
      ),
    );
  }
}