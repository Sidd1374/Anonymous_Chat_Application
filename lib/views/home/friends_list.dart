import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:veil_chat_application/views/chat/chat_area.dart';
import 'package:veil_chat_application/widgets/user_card.dart'
    as uc; // Assuming UserCard is in user_card.dart

// Make sure FriendsPage is a StatefulWidget
class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  // Declare the _allUsers list as a final member variable
  final List<Map<String, String>> _allUsers = [
    {
      'name': 'Alice',
      'image': 'assets/Profile_image.png',
      'isLevel2Verified': 'true',
      'address': '123 Main St',
      'gender': 'Female', // Added gender and age for UserCard
      'age': '28',
    },
    {
      'name': 'Bob',
      'image': 'assets/Profile_image.png',
      'isLevel2Verified': 'false',
      'address': '456 Elm St',
      'gender': 'Male',
      'age': '32',
    },
    {
      'name': 'Charlie',
      'image': 'assets/Profile_image.png',
      'isLevel2Verified': 'true',
      'address': '789 Oak St',
      'gender': 'Male',
      'age': '25',
    },
    {
      'name': 'Diana',
      'image': 'assets/Profile_image.png',
      'isLevel2Verified': 'false',
      'address': '321 Pine St',
      'gender': 'Female',
      'age': '30',
    },
    {
      'name': 'Eve',
      'image': 'assets/Profile_image.png',
      'isLevel2Verified': 'true',
      'address': '654 Maple St',
      'gender': 'Female',
      'age': '22',
    },
    {
      'name': 'Frank',
      'image': 'assets/Profile_image.png',
      'isLevel2Verified': 'false',
      'address': '789 Birch Ave',
      'gender': 'Male',
      'age': '35',
      'chatId': '12345',
    },
    {
      'name': 'Grace',
      'image': 'assets/Profile.png',
      'isLevel2Verified': 'true',
      'address': '101 Cedar Ln',
      'gender': 'Female',
      'age': '29',
      'chatId': '12345',
    },
  ];

  // Declare these as member variables, not inside build()
  late TextEditingController _searchController;
  List<Map<String, String>> _filteredUsers = [];
  bool _isSearching = false; // Controls the visibility of the search bar

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredUsers = List.from(_allUsers); // Initialize with all users

    _searchController.addListener(_onSearchChanged); // Listen for text changes
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterUsers(_searchController.text);
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_allUsers); // Show all if query is empty
      } else {
        _filteredUsers = _allUsers
            .where((user) =>
                user['name']!.toLowerCase().startsWith(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Animated search bar/header
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isSearching
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Row(
              children: [
                Expanded(
                  child: Text(
                    "Friend", // Changed from "History" based on your screenshot
                    style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ) ??
                        const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSearching = true; // Show search bar
                      _searchController
                          .clear(); // Clear previous search on opening
                      _filterUsers(''); // Show all users when opening search
                    });
                  },
                  child: SvgPicture.asset(
                    "assets/icons/icon_search.svg",
                    height: 36,
                    width: 36,
                    colorFilter: ColorFilter.mode(theme.primaryColor,
                        BlendMode.srcIn), // Apply theme color
                  ),
                ),
              ],
            ),
            secondChild: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus:
                        true, // Automatically focus when search bar appears
                    decoration: InputDecoration(
                      hintText: 'Search friends...',
                      hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide.none, // No border for a cleaner look
                      ),
                      filled: true,
                      fillColor: theme.colorScheme
                          .surface, // Background color for text field
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 0),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.clear,
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.7)),
                        onPressed: () {
                          _searchController.clear(); // Clear text
                          _filterUsers(''); // Show all users
                        },
                      ),
                    ),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                  onPressed: () {
                    setState(() {
                      _isSearching = false; // Hide search bar
                      _searchController.clear(); // Clear text
                      _filterUsers(''); // Reset to show all users
                      FocusScope.of(context).unfocus(); // Dismiss keyboard
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Grid of users (filtered) or "No results" message
          Expanded(
            child: _filteredUsers.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.isEmpty
                          ? "No friends available." // Initial empty state for Friends
                          : "No results found for '${_searchController.text}'.", // No results for search
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : GridView.builder(
                    // Changed to GridView.builder for Friends page
                    padding: EdgeInsets
                        .zero, // Remove default grid padding if outer padding is enough
                    itemCount: _filteredUsers.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent:
                          180.0, // Adjust as per your card's max width
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio:
                          0.80, // Adjust this as needed for your UserCard content
                    ),
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return uc.UserCard(
                        name: user['name']!,
                        gender: user['gender']!,
                        age: user['age']!, // Pass dynamic age
                        imagePath: user['image']!,
                        isLevel2Verified: user['isLevel2Verified'] == 'true',
                        address: user['address'] ?? '',
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatArea(
                                userName: user['name']!,
                                userImage: user['image']!,
                                chatId: user['chatId'] ??'', // Pass chatId if available
                              ),
                            ),
                          );
                        },
                        // onPressed: () {
                        //   ScaffoldMessenger.of(context).showSnackBar(
                        //     SnackBar(content: Text('Calling ${user['name']}...')),
                        //   );
                        // },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
