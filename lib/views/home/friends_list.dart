import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veil_chat_application/views/chat/chat_area.dart';
import 'package:veil_chat_application/widgets/user_card.dart' as uc;
import 'package:veil_chat_application/models/user_model.dart';
import 'package:veil_chat_application/services/relationship_service.dart';
import 'package:veil_chat_application/services/chat_service.dart';

// Make sure FriendsPage is a StatefulWidget
class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final RelationshipService _relationshipService = RelationshipService();
  final ChatService _chatService = ChatService();
  
  // Current user
  String? _currentUserId;
  User? _currentUser;
  
  // Friends data
  List<Map<String, dynamic>> _allFriends = [];
  List<Map<String, dynamic>> _filteredFriends = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _hasInitialized = false;
  
  // Cache keys
  static const String _cacheKey = 'friends_list_cache';
  
  // Stream subscription
  StreamSubscription<List<Map<String, dynamic>>>? _friendsSubscription;

  // Declare these as member variables, not inside build()
  late TextEditingController _searchController;
  bool _isSearching = false; // Controls the visibility of the search bar

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
    _initializeFriends();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _friendsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeFriends() async {
    if (_hasInitialized) return;
    _hasInitialized = true;
    
    try {
      // Get current user
      _currentUser = await User.getFromPrefs();
      if (_currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      _currentUserId = _currentUser!.uid;

      // Load from cache first
      await _loadFromCache();

      // Only sync if no friends in cache (first-time fix)
      if (_allFriends.isEmpty) {
        await _relationshipService.syncFriendsFromChatRooms(_currentUserId!);
      }

      // Subscribe to friends stream for real-time updates
      _friendsSubscription = _relationshipService
          .streamFriendsWithDetails(_currentUserId!)
          .listen(
        (friends) async {
          if (mounted) {
            if (!_areListsEqual(_allFriends, friends)) {
              setState(() {
                _allFriends = friends;
                _filterFriends(_searchController.text);
                _isLoading = false;
              });
              await _saveToCache(friends);
            } else if (_isLoading) {
              setState(() {
                _isLoading = false;
              });
            }
          }
        },
        onError: (error) {
          print('Error streaming friends: $error');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      print('Error initializing friends: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('${_cacheKey}_$_currentUserId');
      
      if (cachedData != null) {
        final List<dynamic> decoded = jsonDecode(cachedData);
        final friends = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        
        if (mounted && _allFriends.isEmpty) {
          setState(() {
            _allFriends = friends;
            _filterFriends(_searchController.text);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading friends from cache: $e');
    }
  }

  Future<void> _saveToCache(List<Map<String, dynamic>> friends) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_cacheKey}_$_currentUserId', jsonEncode(friends));
    } catch (e) {
      print('Error saving friends to cache: $e');
    }
  }

  bool _areListsEqual(List<Map<String, dynamic>> list1, List<Map<String, dynamic>> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i]['odId'] != list2[i]['odId']) return false;
    }
    return true;
  }

  Future<void> _onRefresh() async {
    if (_currentUserId == null) return;
    
    setState(() {
      _isRefreshing = true;
    });

    try {
      final friends = await _relationshipService.getFriendsWithDetails(_currentUserId!);
      
      if (mounted) {
        setState(() {
          _allFriends = friends;
          _filterFriends(_searchController.text);
          _isRefreshing = false;
        });
        await _saveToCache(friends);
      }
    } catch (e) {
      print('Error refreshing friends: $e');
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to refresh. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _onSearchChanged() {
    _filterFriends(_searchController.text);
  }

  void _filterFriends(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFriends = List.from(_allFriends);
      } else {
        _filteredFriends = _allFriends
            .where((friend) {
              final name = (friend['fullName'] ?? friend['name'] ?? '').toString().toLowerCase();
              return name.startsWith(query.toLowerCase());
            })
            .toList();
      }
    });
  }

  String _getDisplayName(Map<String, dynamic> friend) {
    return friend['fullName'] ?? friend['name'] ?? 'Unknown';
  }

  String _getProfileImage(Map<String, dynamic> friend) {
    return friend['profilePicUrl'] ?? 'assets/Profile_image.png';
  }

  bool _isVerified(Map<String, dynamic> friend) {
    final level = friend['verificationLevel'];
    return level != null && level >= 2;
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
                    "Friends",
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
                      _isSearching = true;
                      _searchController.clear();
                      _filterFriends('');
                    });
                  },
                  child: SvgPicture.asset(
                    "assets/icons/icon_search.svg",
                    height: 36,
                    width: 36,
                    colorFilter: ColorFilter.mode(theme.primaryColor,
                        BlendMode.srcIn),
                  ),
                ),
              ],
            ),
            secondChild: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search friends...',
                      hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 0),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.clear,
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.7)),
                        onPressed: () {
                          _searchController.clear();
                          _filterFriends('');
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
                      _isSearching = false;
                      _searchController.clear();
                      _filterFriends('');
                      FocusScope.of(context).unfocus();
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Content area with pull-to-refresh
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.surface,
                    child: _filteredFriends.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.5,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        size: 64,
                                        color: theme.colorScheme.outline,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchController.text.isEmpty
                                            ? "No friends yet"
                                            : "No results found for '${_searchController.text}'",
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (_searchController.text.isEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          "Match with someone and like each other\nto become friends!\n\nPull down to refresh",
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : GridView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: _filteredFriends.length,
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 180.0,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.80,
                            ),
                            itemBuilder: (context, index) {
                              final friend = _filteredFriends[index];
                              final name = _getDisplayName(friend);
                              final image = _getProfileImage(friend);
                              final isVerified = _isVerified(friend);
                              final gender = friend['gender']?.toString() ?? 'Unknown';
                              final age = friend['age']?.toString() ?? '?';
                              final friendId = friend['odId'] ?? friend['uid'] ?? '';
                              final chatRoomId = friend['chatRoomId'] ?? '';

                              return uc.UserCard(
                                name: name,
                                gender: gender,
                                age: age,
                                imagePath: image,
                                isLevel2Verified: isVerified,
                                address: '',
                                onPressed: () async {
                                  if (chatRoomId.isEmpty && _currentUserId != null) {
                                    // Get or create chat room
                                    final chatRoom = await _chatService.getChatRoomBetweenUsers(
                                      _currentUserId!,
                                      friendId,
                                    );
                                    if (chatRoom != null && mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatArea(
                                            userName: name,
                                            userImage: image,
                                            chatId: chatRoom.chatRoomId,
                                            otherUserId: friendId,
                                          ),
                                        ),
                                      );
                                    }
                                  } else if (mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatArea(
                                          userName: name,
                                          userImage: image,
                                          chatId: chatRoomId,
                                          otherUserId: friendId,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
