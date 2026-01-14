import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum to represent the type of chat relationship
enum ChatRoomType {
  stranger, // Matched users who haven't added each other as friends yet
  friend,   // Users who have mutually liked each other
}

/// Enum to represent the status of a chat room
enum ChatRoomStatus {
  active,   // Chat is currently active
  expired,  // Stranger chat expired after 48 hours without mutual like
  blocked,  // One user blocked the other
}

/// Model class representing a chat room between two users
class ChatRoom {
  final String chatRoomId;
  final String user1Id;
  final String user2Id;
  final String? user1Name;
  final String? user2Name;
  final String? user1ProfilePic;
  final String? user2ProfilePic;
  final ChatRoomType roomType;
  final ChatRoomStatus status;
  final Timestamp createdAt;
  final Timestamp? lastMessageAt;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final bool user1HasLiked;  // User 1 pressed heart button
  final bool user2HasLiked;  // User 2 pressed heart button
  final int user1UnreadCount;
  final int user2UnreadCount;
  final Timestamp? expiresAt; // For stranger chats - 48 hours from creation

  ChatRoom({
    required this.chatRoomId,
    required this.user1Id,
    required this.user2Id,
    this.user1Name,
    this.user2Name,
    this.user1ProfilePic,
    this.user2ProfilePic,
    required this.roomType,
    required this.status,
    required this.createdAt,
    this.lastMessageAt,
    this.lastMessage,
    this.lastMessageSenderId,
    this.user1HasLiked = false,
    this.user2HasLiked = false,
    this.user1UnreadCount = 0,
    this.user2UnreadCount = 0,
    this.expiresAt,
  });

  /// Generate a unique chat room ID from two user IDs
  /// Format: first 6 chars of smaller UID + "_" + first 6 chars of larger UID
  /// This ensures the same ID is generated regardless of who initiates the chat
  static String generateChatRoomId(String uid1, String uid2) {
    // Sort UIDs to ensure consistent ID generation
    final sortedUids = [uid1, uid2]..sort();
    final firstPart = sortedUids[0].substring(0, sortedUids[0].length >= 6 ? 6 : sortedUids[0].length);
    final secondPart = sortedUids[1].substring(0, sortedUids[1].length >= 6 ? 6 : sortedUids[1].length);
    return '${firstPart}_$secondPart';
  }

  /// Check if the chat room has expired (for stranger chats)
  bool get isExpired {
    if (roomType == ChatRoomType.friend) return false;
    if (expiresAt == null) return false;
    return Timestamp.now().compareTo(expiresAt!) >= 0;
  }

  /// Check if both users have liked each other (eligible for friendship)
  bool get canBecomeFriends => user1HasLiked && user2HasLiked;

  /// Get the other user's ID based on current user
  String getOtherUserId(String currentUserId) {
    return currentUserId == user1Id ? user2Id : user1Id;
  }

  /// Get the other user's name based on current user
  String? getOtherUserName(String currentUserId) {
    return currentUserId == user1Id ? user2Name : user1Name;
  }

  /// Get the other user's profile pic based on current user
  String? getOtherUserProfilePic(String currentUserId) {
    return currentUserId == user1Id ? user2ProfilePic : user1ProfilePic;
  }

  /// Check if current user has liked
  bool hasCurrentUserLiked(String currentUserId) {
    return currentUserId == user1Id ? user1HasLiked : user2HasLiked;
  }

  /// Check if other user has liked
  bool hasOtherUserLiked(String currentUserId) {
    return currentUserId == user1Id ? user2HasLiked : user1HasLiked;
  }

  /// Get unread count for current user
  int getUnreadCount(String currentUserId) {
    return currentUserId == user1Id ? user1UnreadCount : user2UnreadCount;
  }

  /// Factory constructor to create a ChatRoom from Firestore document
  factory ChatRoom.fromJson(Map<String, dynamic> json, String docId) {
    return ChatRoom(
      chatRoomId: docId,
      user1Id: json['user1Id'] as String,
      user2Id: json['user2Id'] as String,
      user1Name: json['user1Name'] as String?,
      user2Name: json['user2Name'] as String?,
      user1ProfilePic: json['user1ProfilePic'] as String?,
      user2ProfilePic: json['user2ProfilePic'] as String?,
      roomType: ChatRoomType.values.firstWhere(
        (e) => e.name == json['roomType'],
        orElse: () => ChatRoomType.stranger,
      ),
      status: ChatRoomStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ChatRoomStatus.active,
      ),
      createdAt: json['createdAt'] as Timestamp? ?? Timestamp.now(),
      lastMessageAt: json['lastMessageAt'] as Timestamp?,
      lastMessage: json['lastMessage'] as String?,
      lastMessageSenderId: json['lastMessageSenderId'] as String?,
      user1HasLiked: json['user1HasLiked'] as bool? ?? false,
      user2HasLiked: json['user2HasLiked'] as bool? ?? false,
      user1UnreadCount: json['user1UnreadCount'] as int? ?? 0,
      user2UnreadCount: json['user2UnreadCount'] as int? ?? 0,
      expiresAt: json['expiresAt'] as Timestamp?,
    );
  }

  /// Convert ChatRoom to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'user1Name': user1Name,
      'user2Name': user2Name,
      'user1ProfilePic': user1ProfilePic,
      'user2ProfilePic': user2ProfilePic,
      'roomType': roomType.name,
      'status': status.name,
      'createdAt': createdAt,
      'lastMessageAt': lastMessageAt,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'user1HasLiked': user1HasLiked,
      'user2HasLiked': user2HasLiked,
      'user1UnreadCount': user1UnreadCount,
      'user2UnreadCount': user2UnreadCount,
      'expiresAt': expiresAt,
    };
  }

  /// Create a copy with updated fields
  ChatRoom copyWith({
    String? chatRoomId,
    String? user1Id,
    String? user2Id,
    String? user1Name,
    String? user2Name,
    String? user1ProfilePic,
    String? user2ProfilePic,
    ChatRoomType? roomType,
    ChatRoomStatus? status,
    Timestamp? createdAt,
    Timestamp? lastMessageAt,
    String? lastMessage,
    String? lastMessageSenderId,
    bool? user1HasLiked,
    bool? user2HasLiked,
    int? user1UnreadCount,
    int? user2UnreadCount,
    Timestamp? expiresAt,
  }) {
    return ChatRoom(
      chatRoomId: chatRoomId ?? this.chatRoomId,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      user1Name: user1Name ?? this.user1Name,
      user2Name: user2Name ?? this.user2Name,
      user1ProfilePic: user1ProfilePic ?? this.user1ProfilePic,
      user2ProfilePic: user2ProfilePic ?? this.user2ProfilePic,
      roomType: roomType ?? this.roomType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      user1HasLiked: user1HasLiked ?? this.user1HasLiked,
      user2HasLiked: user2HasLiked ?? this.user2HasLiked,
      user1UnreadCount: user1UnreadCount ?? this.user1UnreadCount,
      user2UnreadCount: user2UnreadCount ?? this.user2UnreadCount,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
