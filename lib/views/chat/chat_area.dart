import 'package:flutter/material.dart';
import 'package:veil_chat_application/widgets/Chat/chat_text.dart';
import 'package:veil_chat_application/widgets/Chat/chat_actions_bar.dart';

class ChatArea extends StatefulWidget {
  const ChatArea({super.key});

  @override
  State<ChatArea> createState() => _ChatAreaState();
}

class _ChatAreaState extends State<ChatArea> {
  final TextEditingController _inputTextController = TextEditingController();

  // Dummy chat data
  final List<Map<String, dynamic>> _messages = [
    {'text': 'Hi there!', 'isSender': false},
    {'text': 'Hello! How are you?', 'isSender': true},
    {'text': 'I\'m good, thanks! And you?', 'isSender': false},
    {'text': 'Doing great! Working on a Flutter project.', 'isSender': true},
    {'text': 'That\'s awesome!', 'isSender': false},
  ];

  void _handleSend(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({'text': text.trim(), 'isSender': true});
    });
    _inputTextController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              reverse: false,
              itemCount: _messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg['isSender']
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: ChatText(
                    text: msg['text'],
                    isSender: msg['isSender'],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: ChatActionsBar(
              inputTextController: _inputTextController,
              onSend: (text) => _handleSend(text),
            ),
          ),
        ],
      ),
    );
  }
}
