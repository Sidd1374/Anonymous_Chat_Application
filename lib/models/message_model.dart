import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum to represent the type of message
enum MessageType {
  text,     // Regular text message
  image,    // Image message
  system,   // System notification (e.g., "You are now friends!")
  like,     // Like action notification
}

/// Enum to represent message delivery status
enum MessageStatus {
  sending,   // Message is being sent
  sent,      // Message sent to server
  delivered, // Message delivered to recipient's device
  read,      // Message has been read by recipient
  failed,    // Message failed to send
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
  final Map<String, dynamic>? metadata; // For additional data (e.g., image dimensions)

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
    this.metadata,
  });

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
      metadata: json['metadata'] as Map<String, dynamic>?,
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
      'metadata': metadata,
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
    Map<String, dynamic>? metadata,
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
      metadata: metadata ?? this.metadata,
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
