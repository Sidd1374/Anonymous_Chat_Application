import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veil_chat_application/models/chat_room_model.dart';

/// Helper class to set up test chat data in Firebase
/// Use this for testing purposes only - remove in production
class TestChatSetup {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a test chat room between two users
  /// 
  /// Usage:
  /// ```dart
  /// final testSetup = TestChatSetup();
  /// await testSetup.createTestChatRoom(
  ///   user1Id: 'paste_user1_uid_here',
  ///   user2Id: 'paste_user2_uid_here',
  ///   user1Name: 'User 1 Name',
  ///   user2Name: 'User 2 Name',
  /// );
  /// ```
  Future<String> createTestChatRoom({
    required String user1Id,
    required String user2Id,
    String? user1Name,
    String? user2Name,
    String? user1ProfilePic,
    String? user2ProfilePic,
    bool asStranger = true,
  }) async {
    // Generate chat room ID (sorted to ensure consistency)
    final chatRoomId = ChatRoom.generateChatRoomId(user1Id, user2Id);
    
    print('Creating chat room with ID: $chatRoomId');

    // Calculate expiry (48 hours from now) for stranger chats
    final expiresAt = asStranger 
        ? Timestamp.fromDate(DateTime.now().add(const Duration(hours: 48)))
        : null;

    // Create chat room document
    final chatRoomData = {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'user1Name': user1Name ?? 'Test User 1',
      'user2Name': user2Name ?? 'Test User 2',
      'user1ProfilePic': user1ProfilePic,
      'user2ProfilePic': user2ProfilePic,
      'roomType': asStranger ? 'stranger' : 'friend',
      'status': 'active',
      'createdAt': Timestamp.now(),
      'lastMessageAt': null,
      'lastMessage': null,
      'lastMessageSenderId': null,
      'user1HasLiked': false,
      'user2HasLiked': false,
      'user1UnreadCount': 0,
      'user2UnreadCount': 0,
      'expiresAt': expiresAt,
    };

    await _firestore.collection('chats').doc(chatRoomId).set(chatRoomData);
    print('Chat room created successfully!');

    // Add chat room reference to user 1
    await _firestore.collection('users').doc(user1Id).set({
      'strangerChats': FieldValue.arrayUnion([chatRoomId]),
    }, SetOptions(merge: true));
    print('Added chat room to user1');

    // Add chat room reference to user 2
    await _firestore.collection('users').doc(user2Id).set({
      'strangerChats': FieldValue.arrayUnion([chatRoomId]),
    }, SetOptions(merge: true));
    print('Added chat room to user2');

    print('✅ Test chat room setup complete!');
    print('Chat Room ID: $chatRoomId');
    
    return chatRoomId;
  }

  /// Prints the chat room ID that would be generated for two users
  /// Useful to check the ID before creating
  static String getChatRoomId(String user1Id, String user2Id) {
    final chatRoomId = ChatRoom.generateChatRoomId(user1Id, user2Id);
    print('Chat room ID for these users: $chatRoomId');
    return chatRoomId;
  }

  /// Deletes a test chat room and removes references
  Future<void> deleteTestChatRoom(String chatRoomId) async {
    // Get chat room to find user IDs
    final chatDoc = await _firestore.collection('chats').doc(chatRoomId).get();
    
    if (chatDoc.exists) {
      final data = chatDoc.data()!;
      final user1Id = data['user1Id'] as String;
      final user2Id = data['user2Id'] as String;
      final roomType = data['roomType'] as String;
      
      final field = roomType == 'stranger' ? 'strangerChats' : 'friendChats';

      // Remove from user1
      await _firestore.collection('users').doc(user1Id).update({
        field: FieldValue.arrayRemove([chatRoomId]),
      });

      // Remove from user2
      await _firestore.collection('users').doc(user2Id).update({
        field: FieldValue.arrayRemove([chatRoomId]),
      });

      // Delete messages subcollection
      final messages = await _firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .get();
      
      for (final msg in messages.docs) {
        await msg.reference.delete();
      }

      // Delete chat room
      await _firestore.collection('chats').doc(chatRoomId).delete();
      
      print('✅ Chat room $chatRoomId deleted successfully!');
    } else {
      print('❌ Chat room not found');
    }
  }

  /// Lists all chat rooms for debugging
  Future<void> listAllChatRooms() async {
    final chats = await _firestore.collection('chats').get();
    
    print('\n=== All Chat Rooms ===');
    for (final doc in chats.docs) {
      final data = doc.data();
      print('ID: ${doc.id}');
      print('  User1: ${data['user1Name']} (${data['user1Id']})');
      print('  User2: ${data['user2Name']} (${data['user2Id']})');
      print('  Type: ${data['roomType']}');
      print('  Status: ${data['status']}');
      print('---');
    }
  }
}
