import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum to represent the type of message
enum MessageType {
  text, // Regular text message
  image, // Image message
  system, // System notification (e.g., "You are now friends!")
  like, // Like action notification
}

/// Enum to represent message delivery status
enum MessageStatus {
  sending, // Message is being sent
  sent, // Message sent to server
  delivered, // Message delivered to recipient's device
  read, // Message has been read by recipient
  failed, // Message failed to send
}

class Message {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String chatRoomId;
  final String? text;
  final String? imageUrl;
  final MessageType type;
  final MessageStatus status;
  final Timestamp createdAt;
  final Timestamp? readAt;
  final bool isDeleted;
  final Timestamp? deletedAt;
  final Map<String, dynamic>?
      metadata; // For additional data (e.g., image dimensions)

  // Reactions: Map of emoji -> list of user IDs who reacted
  // Example: { "❤️": ["uid1", "uid2"], "😂": ["uid3"] }
  final Map<String, List<String>>? reactions;

  // Reply fields
  final String? replyToMessageId;
  final String? replyToText;
  final String? replyToSenderId;
  final MessageType? replyToType; // To show image icon if replying to image

  Message({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.chatRoomId,
    this.text,
    this.imageUrl,
    this.type = MessageType.text,
    this.status = MessageStatus.sending,
    required this.createdAt,
    this.readAt,
    this.isDeleted = false,
    this.deletedAt,
    this.metadata,
    this.reactions,
    this.replyToMessageId,
    this.replyToText,
    this.replyToSenderId,
    this.replyToType,
  });

  /// Get total reaction count
  int get totalReactionCount {
    if (reactions == null) return 0;
    return reactions!.values.fold(0, (sum, list) => sum + list.length);
  }

  /// Check if a user has reacted with a specific emoji
  bool hasUserReacted(String userId, String emoji) {
    if (reactions == null) return false;
    return reactions![emoji]?.contains(userId) ?? false;
  }

  /// Get the emoji a user reacted with (returns first one if multiple)
  String? getUserReaction(String userId) {
    if (reactions == null) return null;
    for (final entry in reactions!.entries) {
      if (entry.value.contains(userId)) {
        return entry.key;
      }
    }
    return null;
  }

  /// Generate a unique message ID using timestamp and sender ID
  static String generateMessageId(String senderId) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return '${timestamp}_${senderId.substring(0, senderId.length >= 6 ? 6 : senderId.length)}';
  }

  /// Check if the message is from the current user
  bool isSentByMe(String currentUserId) => senderId == currentUserId;

  /// Get display text for system messages
  String getDisplayText() {
    if (isDeleted) return 'This message was deleted';
    if (type == MessageType.system) return text ?? '';
    if (type == MessageType.like) return '❤️ Liked!';
    if (type == MessageType.image) return '📷 Image';
    return text ?? '';
  }

  /// Factory constructor to create a Message from Firestore document
  factory Message.fromJson(Map<String, dynamic> json, String docId) {
    // Handle Timestamp conversion for createdAt
    Timestamp createdAtTimestamp;
    final createdAtData = json['createdAt'];
    if (createdAtData is Timestamp) {
      createdAtTimestamp = createdAtData;
    } else if (createdAtData is String) {
      createdAtTimestamp = Timestamp.fromDate(DateTime.parse(createdAtData));
    } else {
      createdAtTimestamp = Timestamp.now();
    }

    // Handle Timestamp conversion for readAt
    Timestamp? readAtTimestamp;
    final readAtData = json['readAt'];
    if (readAtData is Timestamp) {
      readAtTimestamp = readAtData;
    } else if (readAtData is String) {
      readAtTimestamp = Timestamp.fromDate(DateTime.parse(readAtData));
    }

    // Handle Timestamp conversion for deletedAt
    Timestamp? deletedAtTimestamp;
    final deletedAtData = json['deletedAt'];
    if (deletedAtData is Timestamp) {
      deletedAtTimestamp = deletedAtData;
    } else if (deletedAtData is String) {
      deletedAtTimestamp = Timestamp.fromDate(DateTime.parse(deletedAtData));
    }

    return Message(
      messageId: docId,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      chatRoomId: json['chatRoomId'] as String? ?? '',
      text: json['text'] as String?,
      imageUrl: json['imageUrl'] as String? ?? json['image'] as String?,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      createdAt: createdAtTimestamp,
      readAt: readAtTimestamp,
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: deletedAtTimestamp,
      metadata: json['metadata'] as Map<String, dynamic>?,
      // Parse reactions map
      reactions: json['reactions'] != null
          ? (json['reactions'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                key,
                (value as List<dynamic>).map((e) => e as String).toList(),
              ),
            )
          : null,
      // Reply fields
      replyToMessageId: json['replyToMessageId'] as String?,
      replyToText: json['replyToText'] as String?,
      replyToSenderId: json['replyToSenderId'] as String?,
      replyToType: json['replyToType'] != null
          ? MessageType.values.firstWhere(
              (e) => e.name == json['replyToType'],
              orElse: () => MessageType.text,
            )
          : null,
    );
  }

  /// Convert Message to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'chatRoomId': chatRoomId,
      'text': text,
      'imageUrl': imageUrl,
      'type': type.name,
      'status': status.name,
      'createdAt': createdAt,
      'readAt': readAt,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt,
      'metadata': metadata,
      'reactions': reactions,
      // Reply fields
      'replyToMessageId': replyToMessageId,
      'replyToText': replyToText,
      'replyToSenderId': replyToSenderId,
      'replyToType': replyToType?.name,
    };
  }

  /// Create a copy with updated fields
  Message copyWith({
    String? messageId,
    String? senderId,
    String? receiverId,
    String? chatRoomId,
    String? text,
    String? imageUrl,
    MessageType? type,
    MessageStatus? status,
    Timestamp? createdAt,
    Timestamp? readAt,
    bool? isDeleted,
    Timestamp? deletedAt,
    Map<String, dynamic>? metadata,
    Map<String, List<String>>? reactions,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderId,
    MessageType? replyToType,
  }) {
    return Message(
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      metadata: metadata ?? this.metadata,
      reactions: reactions ?? this.reactions,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToText: replyToText ?? this.replyToText,
      replyToSenderId: replyToSenderId ?? this.replyToSenderId,
      replyToType: replyToType ?? this.replyToType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.messageId == messageId;
  }

  @override
  int get hashCode => messageId.hashCode;
}
