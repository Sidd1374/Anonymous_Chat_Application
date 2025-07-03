import 'package:flutter/material.dart';
import 'package:veil_chat_application/views/chat/chat_area.dart';
import '../../widgets/user_card.dart' as uc;

class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Example list of users; replace with your actual user data
    final List<Map<String, String>> users = [
      {'name': 'Alice', 'image': 'assests/Profile_image.png'},
      {'name': 'Bob', 'image': 'assets/Profile_image.png'},
      {'name': 'Charlie', 'image': 'assets/Profile_image.png'},
      {'name': 'Diana', 'image': 'assets/Profile_image.png'},
      {'name': 'Eve', 'image': 'assets/Profile_image.png'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends List'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          shrinkWrap: true,
          itemCount: users.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 columns
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 180 / 223, // match your UserCard size
          ),
          itemBuilder: (context, index) {
            final user = users[index];
            return uc.UserCard(
              name: user['name']!,
              gender: "male",
              age: "25",
              imagePath: user['image']!,
                onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatArea(),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
