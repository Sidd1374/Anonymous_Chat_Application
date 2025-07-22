import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class History extends StatelessWidget {
  const History({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> historyUsers = [
      {
        'name': 'Alice',
        'image': 'assets/Profile_image.png',
        'isLevel2Verified': 'true',
      },
      {
        'name': 'Bob',
        'image': 'assets/Profile_image.png',
        'isLevel2Verified': 'false',
      },
      {
        'name': 'Charlie',
        'image': 'assets/Profile_image.png',
        'isLevel2Verified': 'true',
      },
      {
        'name': 'Diana',
        'image': 'assets/Profile_image.png',
        'isLevel2Verified': 'false',
      },
      {
        'name': 'Eve',
        'image': 'assets/Profile_image.png',
        'isLevel2Verified': 'true',
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "History",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Search tapped!')),
                  );
                },
                child: SvgPicture.asset(
                  "assets/icons/icon_search.svg",
                  height: 36,
                  width: 36,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: historyUsers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final user = historyUsers[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${user['name']} card tapped!')),
                    );
                  },
                  child: Card(
                    elevation: 2,
                    color: Theme.of(context).colorScheme.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      child: Row(
                        children: [
                          ClipOval(
                            child: Image.asset(
                              user['image']!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  user['name']!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                      ),
                                ),
                                if (user['isLevel2Verified'] == 'true') ...[
                                  const SizedBox(width: 8),
                                  SvgPicture.asset(
                                    "assets/icons/icon_verified.svg",
                                    width: 20,
                                    height: 20,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
