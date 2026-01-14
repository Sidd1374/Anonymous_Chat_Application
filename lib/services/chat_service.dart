import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veil_chat_application/models/message_model.dart';
import 'package:veil_chat_application/models/chat_room_model.dart';

/// Service class for handling real-time chat functionality with Firebase Firestore
/// 
/// Firebase Structure:
/// - chats/{chatRoomId}/
///   - userData (fields: user IDs, names, etc.)
///   - messages/{messageId} (message documents)
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection references
  CollectionReference get _chatsCollection => _firestore.collection('chats');
  
  /// Get messages collection reference for a specific chat room
  CollectionReference _messagesCollection(String chatRoomId) {
    return _chatsCollection.doc(chatRoomId).collection('messages');
  }

  // ==================== CHAT ROOM OPERATIONS ====================

  /// Create a new chat room between two users (for stranger matching)
  /// Returns the created ChatRoom
  Future<ChatRoom> createChatRoom({
    required String user1Id,
    required String user2Id,
    String? user1Name,
    String? user2Name,
    String? user1ProfilePic,
    String? user2ProfilePic,
    ChatRoomType roomType = ChatRoomType.stranger,
  }) async {
    // Generate unique chat room ID
    final chatRoomId = ChatRoom.generateChatRoomId(user1Id, user2Id);
    
    // Check if chat room already exists
    final existingRoom = await getChatRoom(chatRoomId);
    if (existingRoom != null) {
      return existingRoom;
    }

    // Calculate expiry time (48 hours from now for stranger chats)
    final Timestamp? expiresAt = roomType == ChatRoomType.stranger
        ? Timestamp.fromDate(DateTime.now().add(const Duration(hours: 48)))
        : null;

    final chatRoom = ChatRoom(
      chatRoomId: chatRoomId,
      user1Id: user1Id,
      user2Id: user2Id,
      user1Name: user1Name,
      user2Name: user2Name,
      user1ProfilePic: user1ProfilePic,
      user2ProfilePic: user2ProfilePic,
      roomType: roomType,
      status: ChatRoomStatus.active,
      createdAt: Timestamp.now(),
      expiresAt: expiresAt,
    );

    // Create the chat room document
    await _chatsCollection.doc(chatRoomId).set(chatRoom.toJson());

    // Add chat room reference to both users' documents
    await _addChatRoomToUser(user1Id, chatRoomId, roomType);
    await _addChatRoomToUser(user2Id, chatRoomId, roomType);

    return chatRoom;
  }

  /// Get a specific chat room by ID
  Future<ChatRoom?> getChatRoom(String chatRoomId) async {
    try {
      final doc = await _chatsCollection.doc(chatRoomId).get();
      if (!doc.exists) return null;
      return ChatRoom.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      print('Error getting chat room: $e');
      return null;
    }
  }

  /// Get chat room between two specific users
  Future<ChatRoom?> getChatRoomBetweenUsers(String userId1, String userId2) async {
    final chatRoomId = ChatRoom.generateChatRoomId(userId1, userId2);
    return getChatRoom(chatRoomId);
  }

  /// Stream a specific chat room for real-time updates
  Stream<ChatRoom?> streamChatRoom(String chatRoomId) {
    return _chatsCollection.doc(chatRoomId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ChatRoom.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  /// Add chat room reference to user's document
  Future<void> _addChatRoomToUser(String userId, String chatRoomId, ChatRoomType type) async {
    final field = type == ChatRoomType.stranger ? 'strangerChats' : 'friendChats';
    await _firestore.collection('users').doc(userId).update({
      field: FieldValue.arrayUnion([chatRoomId]),
    }).catchError((e) {
      // If field doesn't exist, set it
      return _firestore.collection('users').doc(userId).set({
        field: [chatRoomId],
      }, SetOptions(merge: true));
    });
  }

  /// Remove chat room reference from user's document
  Future<void> _removeChatRoomFromUser(String userId, String chatRoomId, ChatRoomType type) async {
    final field = type == ChatRoomType.stranger ? 'strangerChats' : 'friendChats';
    await _firestore.collection('users').doc(userId).update({
      field: FieldValue.arrayRemove([chatRoomId]),
    });
  }

  // ==================== MESSAGE OPERATIONS ====================

  /// Send a text message
  Future<Message> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String text,
    MessageType type = MessageType.text,
  }) async {
    final messageId = Message.generateMessageId(senderId);
    
    final message = Message(
      messageId: messageId,
      senderId: senderId,
      receiverId: receiverId,
      chatRoomId: chatRoomId,
      text: text,
      type: type,
      status: MessageStatus.sent,
      createdAt: Timestamp.now(),
    );

    // Add message to the messages subcollection
    await _messagesCollection(chatRoomId).doc(messageId).set(message.toJson());

    // Update chat room with last message info
    await _updateLastMessage(chatRoomId, message, receiverId);

    return message;
  }

  /// Send an image message
  Future<Message> sendImageMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String imageUrl,
    Map<String, dynamic>? metadata,
  }) async {
    final messageId = Message.generateMessageId(senderId);
    
    final message = Message(
      messageId: messageId,
      senderId: senderId,
      receiverId: receiverId,
      chatRoomId: chatRoomId,
      imageUrl: imageUrl,
      type: MessageType.image,
      status: MessageStatus.sent,
      createdAt: Timestamp.now(),
      metadata: metadata,
    );

    await _messagesCollection(chatRoomId).doc(messageId).set(message.toJson());
    await _updateLastMessage(chatRoomId, message, receiverId);

    return message;
  }

  /// Send a system message (e.g., "You are now friends!")
  Future<Message> sendSystemMessage({
    required String chatRoomId,
    required String text,
    required String user1Id,
    required String user2Id,
  }) async {
    final messageId = Message.generateMessageId('system');
    
    final message = Message(
      messageId: messageId,
      senderId: 'system',
      receiverId: 'all',
      chatRoomId: chatRoomId,
      text: text,
      type: MessageType.system,
      status: MessageStatus.sent,
      createdAt: Timestamp.now(),
    );

    await _messagesCollection(chatRoomId).doc(messageId).set(message.toJson());
    
    // Update last message without incrementing unread count for system messages
    await _chatsCollection.doc(chatRoomId).update({
      'lastMessage': text,
      'lastMessageAt': Timestamp.now(),
      'lastMessageSenderId': 'system',
    });

    return message;
  }

  /// Update chat room with last message info and increment unread count
  Future<void> _updateLastMessage(String chatRoomId, Message message, String receiverId) async {
    final chatRoom = await getChatRoom(chatRoomId);
    if (chatRoom == null) return;

    final updates = <String, dynamic>{
      'lastMessage': message.type == MessageType.image ? '📷 Image' : message.text,
      'lastMessageAt': message.createdAt,
      'lastMessageSenderId': message.senderId,
    };

    // Increment unread count for the receiver
    if (receiverId == chatRoom.user1Id) {
      updates['user1UnreadCount'] = FieldValue.increment(1);
    } else {
      updates['user2UnreadCount'] = FieldValue.increment(1);
    }

    await _chatsCollection.doc(chatRoomId).update(updates);
  }

  /// Stream messages for a chat room (real-time)
  /// Messages are ordered by createdAt timestamp
  Stream<List<Message>> streamMessages(String chatRoomId, {int limit = 50}) {
    return _messagesCollection(chatRoomId)
        .orderBy('createdAt', descending: false)
        .limitToLast(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Message.fromJson(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();
        });
  }

  /// Get paginated messages (for loading older messages)
  Future<List<Message>> getMessages(
    String chatRoomId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _messagesCollection(chatRoomId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => Message.fromJson(doc.data() as Map<String, dynamic>, doc.id))
        .toList()
        .reversed
        .toList(); // Return in chronological order
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String chatRoomId, String currentUserId) async {
    final chatRoom = await getChatRoom(chatRoomId);
    if (chatRoom == null) return;

    // Reset unread count for current user
    final updates = <String, dynamic>{};
    if (currentUserId == chatRoom.user1Id) {
      updates['user1UnreadCount'] = 0;
    } else {
      updates['user2UnreadCount'] = 0;
    }
    await _chatsCollection.doc(chatRoomId).update(updates);

    // Update message statuses to read (batch update for efficiency)
    final unreadMessages = await _messagesCollection(chatRoomId)
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isNotEqualTo: MessageStatus.read.name)
        .get();

    final batch = _firestore.batch();
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {
        'status': MessageStatus.read.name,
        'readAt': Timestamp.now(),
      });
    }
    await batch.commit();
  }

  /// Delete a message (soft delete)
  Future<void> deleteMessage(String chatRoomId, String messageId) async {
    await _messagesCollection(chatRoomId).doc(messageId).update({
      'isDeleted': true,
      'text': null,
      'imageUrl': null,
    });
  }

  // ==================== LIKE/HEART FUNCTIONALITY ====================

  /// Toggle like status for a user in a chat room
  /// Returns true if both users have now liked (ready to become friends)
  Future<bool> toggleLike(String chatRoomId, String currentUserId) async {
    final chatRoom = await getChatRoom(chatRoomId);
    if (chatRoom == null) return false;

    final isUser1 = currentUserId == chatRoom.user1Id;
    final currentLikeField = isUser1 ? 'user1HasLiked' : 'user2HasLiked';
    final currentLikeStatus = isUser1 ? chatRoom.user1HasLiked : chatRoom.user2HasLiked;
    final otherLikeStatus = isUser1 ? chatRoom.user2HasLiked : chatRoom.user1HasLiked;

    // Toggle the like status
    final newLikeStatus = !currentLikeStatus;
    await _chatsCollection.doc(chatRoomId).update({
      currentLikeField: newLikeStatus,
    });

    // Send a like notification message
    if (newLikeStatus) {
      await sendSystemMessage(
        chatRoomId: chatRoomId,
        text: '❤️ User liked this chat!',
        user1Id: chatRoom.user1Id,
        user2Id: chatRoom.user2Id,
      );
    }

    // Check if both users have liked
    if (newLikeStatus && otherLikeStatus) {
      // Both users have liked - upgrade to friends!
      await _upgradeToFriends(chatRoomId);
      return true;
    }

    return false;
  }

  /// Check if current user has liked
  Future<bool> hasUserLiked(String chatRoomId, String currentUserId) async {
    final chatRoom = await getChatRoom(chatRoomId);
    if (chatRoom == null) return false;
    return chatRoom.hasCurrentUserLiked(currentUserId);
  }

  /// Upgrade a stranger chat to a friend chat
  Future<void> _upgradeToFriends(String chatRoomId) async {
    final chatRoom = await getChatRoom(chatRoomId);
    if (chatRoom == null) return;

    // Update chat room type and remove expiry
    await _chatsCollection.doc(chatRoomId).update({
      'roomType': ChatRoomType.friend.name,
      'expiresAt': null,
    });

    // Move chat room reference from strangerChats to friendChats for both users
    await _removeChatRoomFromUser(chatRoom.user1Id, chatRoomId, ChatRoomType.stranger);
    await _removeChatRoomFromUser(chatRoom.user2Id, chatRoomId, ChatRoomType.stranger);
    await _addChatRoomToUser(chatRoom.user1Id, chatRoomId, ChatRoomType.friend);
    await _addChatRoomToUser(chatRoom.user2Id, chatRoomId, ChatRoomType.friend);

    // Add each user to the other's friends list
    await _addToFriendsList(chatRoom.user1Id, chatRoom.user2Id);
    await _addToFriendsList(chatRoom.user2Id, chatRoom.user1Id);

    // Send a congratulatory system message
    await sendSystemMessage(
      chatRoomId: chatRoomId,
      text: '🎉 You are now friends! Your chat history is now permanent.',
      user1Id: chatRoom.user1Id,
      user2Id: chatRoom.user2Id,
    );
  }

  /// Add a user to another user's friends list
  Future<void> _addToFriendsList(String userId, String friendId) async {
    await _firestore.collection('users').doc(userId).update({
      'friends': FieldValue.arrayUnion([friendId]),
    }).catchError((e) {
      return _firestore.collection('users').doc(userId).set({
        'friends': [friendId],
      }, SetOptions(merge: true));
    });
  }

  // ==================== CHAT ROOM LIST OPERATIONS ====================

  /// Stream all active chat rooms for a user (both strangers and friends)
  Stream<List<ChatRoom>> streamUserChatRooms(String userId) {
    print('Streaming all chat rooms for user: $userId');
    return _chatsCollection
        .where(Filter.or(
          Filter('user1Id', isEqualTo: userId),
          Filter('user2Id', isEqualTo: userId),
        ))
        .where('status', isEqualTo: ChatRoomStatus.active.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          print('Found ${snapshot.docs.length} total chat rooms');
          return snapshot.docs.map((doc) {
            return ChatRoom.fromJson(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();
        });
  }

  /// Stream only friend chat rooms
  Stream<List<ChatRoom>> streamFriendChatRooms(String userId) {
    print('Streaming friend chat rooms for user: $userId');
    return _chatsCollection
        .where(Filter.or(
          Filter('user1Id', isEqualTo: userId),
          Filter('user2Id', isEqualTo: userId),
        ))
        .where('roomType', isEqualTo: ChatRoomType.friend.name)
        .where('status', isEqualTo: ChatRoomStatus.active.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          print('Found ${snapshot.docs.length} friend chat rooms');
          return snapshot.docs.map((doc) {
            return ChatRoom.fromJson(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();
        });
  }

  /// Stream only stranger chat rooms (history/recent matches)
  /// Uses two separate queries to avoid complex OR filter index issues
  Stream<List<ChatRoom>> streamStrangerChatRooms(String userId) {
    print('Streaming stranger chat rooms for user: $userId');
    
    // Query where user is user1
    final query1 = _chatsCollection
        .where('user1Id', isEqualTo: userId)
        .where('roomType', isEqualTo: ChatRoomType.stranger.name)
        .where('status', isEqualTo: ChatRoomStatus.active.name)
        .snapshots();

    // Query where user is user2
    final query2 = _chatsCollection
        .where('user2Id', isEqualTo: userId)
        .where('roomType', isEqualTo: ChatRoomType.stranger.name)
        .where('status', isEqualTo: ChatRoomStatus.active.name)
        .snapshots();

    // Combine both streams
    return query1.asyncMap((snapshot1) async {
      final snapshot2 = await _chatsCollection
          .where('user2Id', isEqualTo: userId)
          .where('roomType', isEqualTo: ChatRoomType.stranger.name)
          .where('status', isEqualTo: ChatRoomStatus.active.name)
          .get();

      final allDocs = <String, dynamic>{};
      
      // Add docs from query1
      for (final doc in snapshot1.docs) {
        allDocs[doc.id] = doc.data();
      }
      
      // Add docs from query2 (avoiding duplicates)
      for (final doc in snapshot2.docs) {
        allDocs[doc.id] = doc.data();
      }

      print('Found ${allDocs.length} stranger chat rooms (user1: ${snapshot1.docs.length}, user2: ${snapshot2.docs.length})');
      
      final chatRooms = allDocs.entries.map((entry) {
        print('Chat room: ${entry.key}');
        return ChatRoom.fromJson(entry.value as Map<String, dynamic>, entry.key);
      }).toList();

      // Sort by createdAt descending
      chatRooms.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return chatRooms;
    });
  }

  /// Get total unread message count for a user across all chats
  Stream<int> streamTotalUnreadCount(String userId) {
    return streamUserChatRooms(userId).map((chatRooms) {
      return chatRooms.fold<int>(0, (total, room) {
        return total + room.getUnreadCount(userId);
      });
    });
  }

  // ==================== CLEANUP OPERATIONS ====================

  /// Check and expire stranger chats that have passed 48 hours
  /// This should be called periodically (e.g., from a Cloud Function or app startup)
  Future<void> cleanupExpiredStrangerChats() async {
    final now = Timestamp.now();
    
    final expiredChats = await _chatsCollection
        .where('roomType', isEqualTo: ChatRoomType.stranger.name)
        .where('status', isEqualTo: ChatRoomStatus.active.name)
        .where('expiresAt', isLessThan: now)
        .get();

    final batch = _firestore.batch();
    for (final doc in expiredChats.docs) {
      batch.update(doc.reference, {
        'status': ChatRoomStatus.expired.name,
      });
    }
    await batch.commit();
  }

  /// Block a user in a chat
  Future<void> blockUser(String chatRoomId, String blockerUserId) async {
    await _chatsCollection.doc(chatRoomId).update({
      'status': ChatRoomStatus.blocked.name,
      'blockedBy': blockerUserId,
      'blockedAt': Timestamp.now(),
    });
  }

  /// Delete a chat room (for cleanup purposes)
  Future<void> deleteChatRoom(String chatRoomId) async {
    // Delete all messages first
    final messages = await _messagesCollection(chatRoomId).get();
    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // Delete the chat room document
    await _chatsCollection.doc(chatRoomId).delete();
  }
}
