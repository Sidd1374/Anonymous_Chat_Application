import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:veil_chat_application/views/chat/chat_area.dart';
import 'package:veil_chat_application/models/user_model.dart';
import 'package:veil_chat_application/services/relationship_service.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  final RelationshipService _relationshipService = RelationshipService();
  
  // Current user
  String? _currentUserId;
  User? _currentUser;
  
  // Strangers data (chat history with non-friends)
  List<Map<String, dynamic>> _allStrangers = [];
  List<Map<String, dynamic>> _filteredStrangers = [];
  bool _isLoading = true;
  
  // Stream subscription
  StreamSubscription<List<Map<String, dynamic>>>? _strangersSubscription;

  late TextEditingController _searchController;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
    _initializeHistory();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _strangersSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeHistory() async {
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

      // Subscribe to strangers stream
      _strangersSubscription = _relationshipService
          .streamStrangersWithDetails(_currentUserId!)
          .listen(
        (strangers) {
          if (mounted) {
            setState(() {
              _allStrangers = strangers;
              _filterStrangers(_searchController.text);
              _isLoading = false;
            });
          }
        },
        onError: (error) {
          print('Error streaming strangers: $error');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      print('Error initializing history: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    _filterStrangers(_searchController.text);
  }

  void _filterStrangers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStrangers = List.from(_allStrangers);
      } else {
        _filteredStrangers = _allStrangers
            .where((stranger) {
              final name = (stranger['fullName'] ?? stranger['name'] ?? '').toString().toLowerCase();
              return name.startsWith(query.toLowerCase());
            })
            .toList();
      }
    });
  }

  String _getDisplayName(Map<String, dynamic> stranger) {
    return stranger['fullName'] ?? stranger['name'] ?? 'Stranger';
  }

  String _getProfileImage(Map<String, dynamic> stranger) {
    return stranger['profilePicUrl'] ?? 'assets/Profile_image.png';
  }

  bool _isVerified(Map<String, dynamic> stranger) {
    final level = stranger['verificationLevel'];
    return level != null && level >= 2;
  }

  String _formatTimeRemaining(Timestamp? expiresAt) {
    if (expiresAt == null) return '';
    final now = DateTime.now();
    final expiry = expiresAt.toDate();
    if (expiry.isBefore(now)) return 'Expired';
    
    final diff = expiry.difference(now);
    if (diff.inHours >= 24) {
      return '${diff.inHours ~/ 24}d ${diff.inHours % 24}h left';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m left';
    } else {
      return '${diff.inMinutes}m left';
    }
  }

  String _formatLastMessage(Map<String, dynamic> stranger) {
    final lastMessage = stranger['lastMessage'] as String?;
    if (lastMessage == null || lastMessage.isEmpty) return 'No messages yet';
    if (lastMessage.length > 30) {
      return '${lastMessage.substring(0, 30)}...';
    }
    return lastMessage;
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
                      _isSearching = true;
                      _searchController.clear();
                      _filterStrangers('');
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
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search history...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 0),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterStrangers('');
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
                      _isSearching = false;
                      _searchController.clear();
                      _filterStrangers('');
                      FocusScope.of(context).unfocus();
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Content area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStrangers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? "No chat history"
                                  : "No results found for '${_searchController.text}'",
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_searchController.text.isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                "Start chatting with strangers!\nThey'll appear here.",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredStrangers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final stranger = _filteredStrangers[index];
                          final name = _getDisplayName(stranger);
                          final image = _getProfileImage(stranger);
                          final isVerified = _isVerified(stranger);
                          final chatRoomId = stranger['chatRoomId'] ?? '';
                          final strangerId = stranger['odId'] ?? stranger['uid'] ?? '';
                          final hasLiked = stranger['hasLiked'] == true;
                          final otherHasLiked = stranger['otherHasLiked'] == true;
                          final expiresAt = stranger['expiresAt'] as Timestamp?;
                          final unreadCount = stranger['unreadCount'] as int? ?? 0;
                          final lastMessage = _formatLastMessage(stranger);
                          final timeRemaining = _formatTimeRemaining(expiresAt);

                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatArea(
                                    userName: name,
                                    userImage: image,
                                    chatId: chatRoomId,
                                    otherUserId: strangerId,
                                  ),
                                ),
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
                                    // Profile image with like indicator
                                    Stack(
                                      children: [
                                        ClipOval(
                                          child: image.startsWith('http')
                                              ? Image.network(
                                                  image,
                                                  width: 56,
                                                  height: 56,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Image.asset(
                                                        'assets/Profile_image.png',
                                                        width: 56,
                                                        height: 56,
                                                        fit: BoxFit.cover,
                                                      ),
                                                )
                                              : Image.asset(
                                                  image,
                                                  width: 56,
                                                  height: 56,
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                        // Heart indicator if other user has liked
                                        if (otherHasLiked)
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.favorite,
                                                color: Colors.red,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    // Name and message info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        name,
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
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (isVerified) ...[
                                                      const SizedBox(width: 4),
                                                      SvgPicture.asset(
                                                        "assets/icons/icon_verified.svg",
                                                        width: 18,
                                                        height: 18,
                                                      ),
                                                    ],
                                                    if (hasLiked) ...[
                                                      const SizedBox(width: 4),
                                                      Icon(
                                                        Icons.favorite,
                                                        color: Colors.red,
                                                        size: 16,
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              // Unread count badge
                                              if (unreadCount > 0)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: theme.colorScheme.primary,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    unreadCount > 99 ? '99+' : '$unreadCount',
                                                    style: TextStyle(
                                                      color: theme.colorScheme.onPrimary,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          // Last message preview
                                          Text(
                                            lastMessage,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          // Time remaining
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.timer_outlined,
                                                size: 14,
                                                color: timeRemaining == 'Expired'
                                                    ? Colors.red
                                                    : theme.colorScheme.onSurface.withOpacity(0.5),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                timeRemaining,
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  fontSize: 11,
                                                  color: timeRemaining == 'Expired'
                                                      ? Colors.red
                                                      : theme.colorScheme.onSurface.withOpacity(0.5),
                                                ),
                                              ),
                                            ],
                                          ),
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
