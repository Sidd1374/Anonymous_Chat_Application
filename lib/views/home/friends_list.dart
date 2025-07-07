import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:veil_chat_application/views/chat/chat_area.dart';
import '../../widgets/user_card.dart' as uc;

class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> users = [
      {
        'name': 'Alice',
        'image': 'assets/Profile_image.png',
        'isLevel2Verified': 'true',
        'address': '123 Main St'
      },
      {
        'name': 'Bob',
        'image': 'assets/Profile_image.png',
        'isLevel2Verified': 'false',
        'address': '456 Elm St'
      },
      {
        'name': 'Charlie',
        'image': 'assets/Profile_image.png',
        'isLevel2Verified': 'true',
        'address': '789 Oak St'
      },
      {
        'name': 'Diana',
        'image': 'assets/Profile_image.png',
        'isLevel2Verified': 'false',
        'address': '321 Pine St'
      },
      {
        'name': 'Eve',
        'image': 'assets/Profile_image.png',
        'isLevel2Verified': 'true',
        'address': '654 Maple St'
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Row with left-aligned title and right-aligned logo
          Row(
            children: [
              Expanded(
                child: Text(
                  "Friend",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                ),
              ),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatArea(),
                    ),
                  );
                },
                child: SvgPicture.asset(
                  "assets/icons/icon_search.svg", // Change this path to your logo
                  height: 36,
                  width: 36,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
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
                  isLevel2Verified: user['isLevel2Verified'] == 'true',
                  address: user['address'] ?? '',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Calling ${user['name']}...')),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
