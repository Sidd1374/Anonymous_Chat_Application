import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veil_chat_application/models/chat_room_model.dart';
import 'package:veil_chat_application/services/chat_service.dart';

/// Enum to represent the relationship between two users
enum RelationshipStatus {
  none,       // No relationship
  stranger,   // Matched but not friends yet
  pending,    // One user has liked, waiting for other
  friend,     // Both users have liked each other
  blocked,    // One user has blocked the other
}

/// Model class for a user in the context of relationships
class RelationshipUser {
  final String odId;
  final String? name;
  final String? profilePicUrl;
  final String? gender;
  final String? age;
  final int? verificationLevel;
  final RelationshipStatus relationshipStatus;
  final String? chatRoomId;
  final Timestamp? matchedAt;
  final Timestamp? expiresAt;
  final bool hasLiked;  // Current user has liked this person

  RelationshipUser({
    required this.odId,
    this.name,
    this.profilePicUrl,
    this.gender,
    this.age,
    this.verificationLevel,
    this.relationshipStatus = RelationshipStatus.none,
    this.chatRoomId,
    this.matchedAt,
    this.expiresAt,
    this.hasLiked = false,
  });

  /// Get remaining time until expiry (for stranger relationships)
  Duration? get timeUntilExpiry {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    final expiry = expiresAt!.toDate();
    if (expiry.isBefore(now)) return Duration.zero;
    return expiry.difference(now);
  }

  /// Check if the relationship has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!.toDate());
  }

  factory RelationshipUser.fromJson(Map<String, dynamic> json) {
    return RelationshipUser(
      odId: json['odId'] as String,
      name: json['name'] as String?,
      profilePicUrl: json['profilePicUrl'] as String?,
      gender: json['gender'] as String?,
      age: json['age']?.toString(),
      verificationLevel: json['verificationLevel'] as int?,
      relationshipStatus: RelationshipStatus.values.firstWhere(
        (e) => e.name == json['relationshipStatus'],
        orElse: () => RelationshipStatus.none,
      ),
      chatRoomId: json['chatRoomId'] as String?,
      matchedAt: json['matchedAt'] as Timestamp?,
      expiresAt: json['expiresAt'] as Timestamp?,
      hasLiked: json['hasLiked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'odId': odId,
      'name': name,
      'profilePicUrl': profilePicUrl,
      'gender': gender,
      'age': age,
      'verificationLevel': verificationLevel,
      'relationshipStatus': relationshipStatus.name,
      'chatRoomId': chatRoomId,
      'matchedAt': matchedAt,
      'expiresAt': expiresAt,
      'hasLiked': hasLiked,
    };
  }
}

/// Service class for managing user relationships (strangers, friends, blocked)
class RelationshipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatService _chatService = ChatService();

  CollectionReference get _usersCollection => _firestore.collection('users');

  // ==================== STRANGER MATCHING ====================

  /// Add a user to strangers list after matching
  /// This is called when two users are matched from the search/random matching feature
  Future<String> matchWithStranger({
    required String currentUserId,
    required String strangerId,
    String? currentUserName,
    String? strangerName,
    String? currentUserProfilePic,
    String? strangerProfilePic,
  }) async {
    // Create a chat room for the matched users
    final chatRoom = await _chatService.createChatRoom(
      user1Id: currentUserId,
      user2Id: strangerId,
      user1Name: currentUserName,
      user2Name: strangerName,
      user1ProfilePic: currentUserProfilePic,
      user2ProfilePic: strangerProfilePic,
      roomType: ChatRoomType.stranger,
    );

    // Add stranger to current user's strangers list
    await _addToStrangersList(
      userId: currentUserId,
      strangerId: strangerId,
      chatRoomId: chatRoom.chatRoomId,
    );

    // Add current user to stranger's strangers list
    await _addToStrangersList(
      userId: strangerId,
      strangerId: currentUserId,
      chatRoomId: chatRoom.chatRoomId,
    );

    return chatRoom.chatRoomId;
  }

  /// Add a user to the strangers list
  Future<void> _addToStrangersList({
    required String userId,
    required String strangerId,
    required String chatRoomId,
  }) async {
    await _usersCollection.doc(userId).set({
      'strangersList': FieldValue.arrayUnion([
        {
          'userId': strangerId,
          'chatRoomId': chatRoomId,
          'matchedAt': Timestamp.now(),
        }
      ]),
    }, SetOptions(merge: true));
  }

  /// Remove a user from the strangers list
  Future<void> removeFromStrangersList(String userId, String strangerId) async {
    // First, get the current strangers list
    final userDoc = await _usersCollection.doc(userId).get();
    if (!userDoc.exists) return;

    final data = userDoc.data() as Map<String, dynamic>?;
    final strangersList = data?['strangersList'] as List<dynamic>? ?? [];

    // Find and remove the stranger
    final updatedList = strangersList
        .where((s) => (s as Map<String, dynamic>)['userId'] != strangerId)
        .toList();

    await _usersCollection.doc(userId).update({
      'strangersList': updatedList,
    });
  }

  // ==================== FRIENDS MANAGEMENT ====================

  /// Get the friends list for a user
  Future<List<String>> getFriendsList(String userId) async {
    final userDoc = await _usersCollection.doc(userId).get();
    if (!userDoc.exists) return [];

    final data = userDoc.data() as Map<String, dynamic>?;
    final friends = data?['friends'] as List<dynamic>? ?? [];
    return friends.map((e) => e.toString()).toList();
  }

  /// Stream the friends list for real-time updates
  Stream<List<String>> streamFriendsList(String userId) {
    return _usersCollection.doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) return [];
      final data = snapshot.data() as Map<String, dynamic>?;
      final friends = data?['friends'] as List<dynamic>? ?? [];
      return friends.map((e) => e.toString()).toList();
    });
  }

  /// Get friends with their details
  Future<List<Map<String, dynamic>>> getFriendsWithDetails(String userId) async {
    final friendIds = await getFriendsList(userId);
    if (friendIds.isEmpty) return [];

    final friends = <Map<String, dynamic>>[];
    
    // Fetch friend details in batches of 10 (Firestore whereIn limit)
    for (var i = 0; i < friendIds.length; i += 10) {
      final batch = friendIds.skip(i).take(10).toList();
      final snapshot = await _usersCollection
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['odId'] = doc.id;
        
        // Get the chat room for this friend
        final chatRoom = await _chatService.getChatRoomBetweenUsers(userId, doc.id);
        data['chatRoomId'] = chatRoom?.chatRoomId;
        
        friends.add(data);
      }
    }

    return friends;
  }

  /// Stream friends with their details for real-time updates
  /// Optimized: generates chatRoomId without extra reads
  Stream<List<Map<String, dynamic>>> streamFriendsWithDetails(String userId) {
    return streamFriendsList(userId).asyncMap((friendIds) async {
      if (friendIds.isEmpty) return [];

      final friends = <Map<String, dynamic>>[];
      
      for (var i = 0; i < friendIds.length; i += 10) {
        final batch = friendIds.skip(i).take(10).toList();
        final snapshot = await _usersCollection
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        
        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          data['odId'] = doc.id;
          
          // Generate chatRoomId directly instead of querying
          // This saves 1 read per friend!
          data['chatRoomId'] = ChatRoom.generateChatRoomId(userId, doc.id);
          
          friends.add(data);
        }
      }

      return friends;
    });
  }

  /// Sync friends list from existing friend-type chat rooms
  /// Call this to fix missing friends in the friends array
  Future<void> syncFriendsFromChatRooms(String userId) async {
    try {
      // Get all friend-type chat rooms for this user
      final chatRoomsQuery = await _firestore.collection('chats')
          .where(Filter.or(
            Filter('user1Id', isEqualTo: userId),
            Filter('user2Id', isEqualTo: userId),
          ))
          .where('roomType', isEqualTo: 'friend')
          .get();
      
      final friendIds = <String>[];
      
      for (final doc in chatRoomsQuery.docs) {
        final data = doc.data();
        final user1Id = data['user1Id'] as String?;
        final user2Id = data['user2Id'] as String?;
        
        if (user1Id == userId && user2Id != null) {
          friendIds.add(user2Id);
        } else if (user2Id == userId && user1Id != null) {
          friendIds.add(user1Id);
        }
      }
      
      if (friendIds.isNotEmpty) {
        // Update the user's friends array
        await _usersCollection.doc(userId).set({
          'friends': FieldValue.arrayUnion(friendIds),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error syncing friends: $e');
    }
  }

  /// Remove a friend (both users will be removed from each other's lists)
  Future<void> removeFriend(String userId, String friendId) async {
    await _usersCollection.doc(userId).update({
      'friends': FieldValue.arrayRemove([friendId]),
    });
    
    await _usersCollection.doc(friendId).update({
      'friends': FieldValue.arrayRemove([userId]),
    });
  }

  // ==================== STRANGERS LIST ====================

  /// Get strangers list (users matched but not yet friends)
  Future<List<Map<String, dynamic>>> getStrangersWithDetails(String userId) async {
    // Get stranger chat rooms
    final chatRooms = await _firestore.collection('chats')
        .where(Filter.or(
          Filter('user1Id', isEqualTo: userId),
          Filter('user2Id', isEqualTo: userId),
        ))
        .where('roomType', isEqualTo: ChatRoomType.stranger.name)
        .where('status', isEqualTo: ChatRoomStatus.active.name)
        .get();

    final strangers = <Map<String, dynamic>>[];

    for (final doc in chatRooms.docs) {
      final chatRoom = ChatRoom.fromJson(doc.data(), doc.id);
      
      // Skip expired chats
      if (chatRoom.isExpired) continue;

      final strangerId = chatRoom.getOtherUserId(userId);
      
      // Get stranger's details
      final strangerDoc = await _usersCollection.doc(strangerId).get();
      if (!strangerDoc.exists) continue;

      final strangerData = strangerDoc.data() as Map<String, dynamic>;
      strangerData['odId'] = strangerId;
      strangerData['chatRoomId'] = chatRoom.chatRoomId;
      strangerData['hasLiked'] = chatRoom.hasCurrentUserLiked(userId);
      strangerData['otherHasLiked'] = chatRoom.hasOtherUserLiked(userId);
      strangerData['matchedAt'] = chatRoom.createdAt;
      strangerData['expiresAt'] = chatRoom.expiresAt;
      strangerData['lastMessage'] = chatRoom.lastMessage;
      strangerData['lastMessageAt'] = chatRoom.lastMessageAt;
      strangerData['unreadCount'] = chatRoom.getUnreadCount(userId);

      strangers.add(strangerData);
    }

    // Sort by last message time (most recent first)
    strangers.sort((a, b) {
      final aTime = a['lastMessageAt'] as Timestamp?;
      final bTime = b['lastMessageAt'] as Timestamp?;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return strangers;
  }

  /// Stream strangers with their details for real-time updates
  Stream<List<Map<String, dynamic>>> streamStrangersWithDetails(String userId) {
    return _chatService.streamStrangerChatRooms(userId).asyncMap((chatRooms) async {
      final strangers = <Map<String, dynamic>>[];

      for (final chatRoom in chatRooms) {
        // Skip expired chats
        if (chatRoom.isExpired) continue;

        final strangerId = chatRoom.getOtherUserId(userId);
        
        // Get stranger's details
        final strangerDoc = await _usersCollection.doc(strangerId).get();
        if (!strangerDoc.exists) continue;

        final strangerData = strangerDoc.data() as Map<String, dynamic>;
        strangerData['odId'] = strangerId;
        strangerData['chatRoomId'] = chatRoom.chatRoomId;
        strangerData['hasLiked'] = chatRoom.hasCurrentUserLiked(userId);
        strangerData['otherHasLiked'] = chatRoom.hasOtherUserLiked(userId);
        strangerData['matchedAt'] = chatRoom.createdAt;
        strangerData['expiresAt'] = chatRoom.expiresAt;
        strangerData['lastMessage'] = chatRoom.lastMessage;
        strangerData['lastMessageAt'] = chatRoom.lastMessageAt;
        strangerData['unreadCount'] = chatRoom.getUnreadCount(userId);

        strangers.add(strangerData);
      }

      return strangers;
    });
  }

  // ==================== RELATIONSHIP STATUS ====================

  /// Get the relationship status between two users
  Future<RelationshipStatus> getRelationshipStatus(String userId, String otherUserId) async {
    // Check if they are friends
    final friendsList = await getFriendsList(userId);
    if (friendsList.contains(otherUserId)) {
      return RelationshipStatus.friend;
    }

    // Check if they have an active chat room
    final chatRoom = await _chatService.getChatRoomBetweenUsers(userId, otherUserId);
    if (chatRoom != null) {
      if (chatRoom.status == ChatRoomStatus.blocked) {
        return RelationshipStatus.blocked;
      }
      
      if (chatRoom.roomType == ChatRoomType.stranger) {
        if (chatRoom.canBecomeFriends) {
          return RelationshipStatus.friend;
        }
        if (chatRoom.hasCurrentUserLiked(userId) || chatRoom.hasOtherUserLiked(userId)) {
          return RelationshipStatus.pending;
        }
        return RelationshipStatus.stranger;
      }
    }

    return RelationshipStatus.none;
  }

  // ==================== BLOCKING ====================

  /// Block a user
  Future<void> blockUser(String userId, String blockedUserId) async {
    // Add to blocked list
    await _usersCollection.doc(userId).set({
      'blockedUsers': FieldValue.arrayUnion([blockedUserId]),
    }, SetOptions(merge: true));

    // Remove from friends if they were friends
    await removeFriend(userId, blockedUserId);

    // Block the chat room if exists
    final chatRoom = await _chatService.getChatRoomBetweenUsers(userId, blockedUserId);
    if (chatRoom != null) {
      await _chatService.blockUser(chatRoom.chatRoomId, userId);
    }
  }

  /// Unblock a user
  Future<void> unblockUser(String userId, String blockedUserId) async {
    await _usersCollection.doc(userId).update({
      'blockedUsers': FieldValue.arrayRemove([blockedUserId]),
    });
  }

  /// Check if a user is blocked
  Future<bool> isUserBlocked(String userId, String otherUserId) async {
    final userDoc = await _usersCollection.doc(userId).get();
    if (!userDoc.exists) return false;

    final data = userDoc.data() as Map<String, dynamic>?;
    final blockedUsers = data?['blockedUsers'] as List<dynamic>? ?? [];
    return blockedUsers.contains(otherUserId);
  }

  /// Get list of blocked users
  Future<List<String>> getBlockedUsers(String userId) async {
    final userDoc = await _usersCollection.doc(userId).get();
    if (!userDoc.exists) return [];

    final data = userDoc.data() as Map<String, dynamic>?;
    final blockedUsers = data?['blockedUsers'] as List<dynamic>? ?? [];
    return blockedUsers.map((e) => e.toString()).toList();
  }

  // ==================== CLEANUP ====================

  /// Clean up expired stranger relationships
  /// This should be called periodically
  Future<void> cleanupExpiredStrangers() async {
    await _chatService.cleanupExpiredStrangerChats();
  }
}
