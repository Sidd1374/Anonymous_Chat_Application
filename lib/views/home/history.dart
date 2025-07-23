import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:veil_chat_application/views/chat/chat_area.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  final List<Map<String, String>> _allHistoryUsers = [
    {
      'name': 'Alice',
      'image': 'assets/Profile_image.png',
      'isLevel2Verified': 'true',
      'chatId': '12345',
    },
    {
      'name': 'Bob',
      'image': 'assets/Profile.png',
      'isLevel2Verified': 'false',
      'chatId': '12345',
    },
    {
      'name': 'Charlie',
      'image': 'assets/Profile_image.png',
      'isLevel2Verified': 'true',
      'chatId': '12345',
    },
    {
      'name': 'Diana',
      'image': 'assets/Profile_image.png',
      'isLevel2Verified': 'false',
      'chatId': '12345',
    },
    {
      'name': 'Eve',
      'image': 'assets/Profile_image.png',
      'isLevel2Verified': 'true',
      'chatId': '12345',
    },
    // Add more users for better testing
    {
      'name': 'Frank',
      'image': 'assets/Profile_image.png',
      'isLevel2Verified': 'false',
      'chatId': '12345',
    },
    {
      'name': 'Grace',
      'image': 'assets/Profile_image.png',
      'isLevel2Verified': 'true',
      'chatId': '12345',
    },
  ];

  late TextEditingController _searchController;
  List<Map<String, String>> _filteredUsers = [];
  bool _isSearching = false; // Controls the visibility of the search bar

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredUsers = List.from(_allHistoryUsers); // Initially show all users

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
        _filteredUsers =
            List.from(_allHistoryUsers); // Show all if query is empty
      } else {
        _filteredUsers = _allHistoryUsers
            .where((user) =>
                user['name']!.toLowerCase().contains(query.toLowerCase()))
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
                    "History",
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
                        icon: const Icon(Icons.clear),
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
                  icon: const Icon(Icons.close),
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
          // List of users (filtered) or "No results" message
          Expanded(
            child: _filteredUsers.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.isEmpty
                          ? "No history available." // Initial empty state
                          : "No results found for '${_searchController.text}'.", // No results for search
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )

                // list of users
                : ListView.separated(
                    itemCount: _filteredUsers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          // Navigate to chat area with the selected user
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatArea(
                                userName: user['name']!,
                                userImage: user['image']!,
                                chatId: user['chatId']!,
                              ),
                            ),
                          );
                          // ScaffoldMessenger.of(context).showSnackBar(
                          //   SnackBar(
                          //       content: Text('${user['name']} card tapped!')),
                          // );
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
                                                ) ??
                                            const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 18),
                                      ),
                                      if (user['isLevel2Verified'] ==
                                          'true') ...[
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
