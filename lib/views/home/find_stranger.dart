import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veil_chat_application/services/test_chat_setup.dart';
import 'package:veil_chat_application/views/chat/chat_area.dart';

class FindStrangerPage extends StatefulWidget {
  const FindStrangerPage({super.key});

  @override
  State<FindStrangerPage> createState() => _FindStrangerPageState();
}

class _FindStrangerPageState extends State<FindStrangerPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentUserId;
  bool _isLoading = false;
  Set<String> _usersWithActiveChats = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');
    if (uid != null) {
      setState(() {
        _currentUserId = uid;
      });
      await _loadUsersWithActiveChats();
    }
  }

  /// Load all user IDs that have an active chat with current user
  Future<void> _loadUsersWithActiveChats() async {
    if (_currentUserId == null) return;

    try {
      // Query chats where current user is user1
      final query1 = await _firestore
          .collection('chats')
          .where('user1Id', isEqualTo: _currentUserId)
          .where('status', isEqualTo: 'active')
          .get();

      // Query chats where current user is user2
      final query2 = await _firestore
          .collection('chats')
          .where('user2Id', isEqualTo: _currentUserId)
          .where('status', isEqualTo: 'active')
          .get();

      final Set<String> activeUserIds = {};

      for (final doc in query1.docs) {
        final data = doc.data();
        activeUserIds.add(data['user2Id'] as String);
      }

      for (final doc in query2.docs) {
        final data = doc.data();
        activeUserIds.add(data['user1Id'] as String);
      }

      if (mounted) {
        setState(() {
          _usersWithActiveChats = activeUserIds;
        });
      }
    } catch (e) {
      debugPrint('[FindStranger] Error loading active chats: $e');
    }
  }

  Future<void> _createChatWithUser(Map<String, dynamic> strangerData, String strangerId) async {
    if (_currentUserId == null) return;

    setState(() => _isLoading = true);

    try {
      // Get current user data
      final currentUserDoc = await _firestore.collection('users').doc(_currentUserId).get();
      final currentUserData = currentUserDoc.data() ?? {};

      final testSetup = TestChatSetup();
      
      // Use correct field names: fullName and profilePicUrl
      final chatRoomId = await testSetup.createTestChatRoom(
        user1Id: _currentUserId!,
        user2Id: strangerId,
        user1Name: currentUserData['fullName'] ?? currentUserData['name'] ?? 'Anonymous',
        user2Name: strangerData['fullName'] ?? strangerData['name'] ?? 'Anonymous',
        user1ProfilePic: currentUserData['profilePicUrl'] ?? currentUserData['profileImage'],
        user2ProfilePic: strangerData['profilePicUrl'] ?? strangerData['profileImage'],
        asStranger: true,
      );

      // Add to active chats set to hide from list
      setState(() {
        _usersWithActiveChats.add(strangerId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chat created with ${strangerData['fullName'] ?? strangerData['name'] ?? 'Stranger'}!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to chat screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatArea(
              userName: strangerData['fullName'] ?? strangerData['name'] ?? 'Anonymous',
              userImage: strangerData['profilePicUrl'] ?? strangerData['profileImage'] ?? '',
              chatId: chatRoomId,
              otherUserId: strangerId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Find Strangers',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _currentUserId == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    // Filter out current user and users with active chats
                    var users = snapshot.data?.docs
                            .where((doc) => 
                                doc.id != _currentUserId &&
                                !_usersWithActiveChats.contains(doc.id))
                            .toList() ??
                        [];

                    // Sort alphabetically by name
                    users.sort((a, b) {
                      final aData = a.data() as Map<String, dynamic>;
                      final bData = b.data() as Map<String, dynamic>;
                      final aName = (aData['fullName'] ?? aData['name'] ?? 'Anonymous').toString().toLowerCase();
                      final bName = (bData['fullName'] ?? bData['name'] ?? 'Anonymous').toString().toLowerCase();
                      return aName.compareTo(bName);
                    });

                    if (users.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search,
                              size: 80.sp,
                              color: theme.colorScheme.primary.withOpacity(0.5),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'No strangers found',
                              style: TextStyle(
                                fontSize: 18.sp,
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Check back later!',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final userDoc = users[index];
                        final userData = userDoc.data() as Map<String, dynamic>;
                        final userId = userDoc.id;

                        return _StrangerCard(
                          userData: userData,
                          userId: userId,
                          onTap: () => _createChatWithUser(userData, userId),
                          theme: theme,
                        );
                      },
                    );
                  },
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _StrangerCard extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String userId;
  final VoidCallback onTap;
  final ThemeData theme;

  const _StrangerCard({
    required this.userData,
    required this.userId,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // Use correct field names with fallbacks for compatibility
    final name = userData['fullName'] ?? userData['name'] ?? 'Anonymous';
    final profileImage = (userData['profilePicUrl'] ?? userData['profileImage']) as String?;
    final bio = userData['bio'] as String?;
    final isVerified = userData['verificationLevel'] == 2;

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // Profile Image
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30.r,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                    backgroundImage: profileImage != null && profileImage.isNotEmpty
                        ? NetworkImage(profileImage)
                        : null,
                    child: profileImage == null || profileImage.isEmpty
                        ? Icon(
                            Icons.person,
                            size: 30.sp,
                            color: theme.colorScheme.primary,
                          )
                        : null,
                  ),
                  if (isVerified)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.star,
                          size: 16.sp,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 16.w),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (bio != null && bio.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        bio,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              // Chat Button
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 24.sp,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
