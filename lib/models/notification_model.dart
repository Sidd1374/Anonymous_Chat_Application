import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum representing different types of notifications
enum NotificationType {
  newMessage,      // New chat message received
  newMatch,        // Matched with a stranger
  mutualLike,      // Both users liked each other (new friend)
  chatExpiring,    // Stranger chat about to expire
  promotional,     // Promotional message from developers
  systemAnnouncement, // System updates, maintenance, etc.
}

/// Extension to convert NotificationType to/from string
extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.newMessage:
        return 'new_message';
      case NotificationType.newMatch:
        return 'new_match';
      case NotificationType.mutualLike:
        return 'mutual_like';
      case NotificationType.chatExpiring:
        return 'chat_expiring';
      case NotificationType.promotional:
        return 'promotional';
      case NotificationType.systemAnnouncement:
        return 'system_announcement';
    }
  }

  static NotificationType fromString(String value) {
    switch (value) {
      case 'new_message':
        return NotificationType.newMessage;
      case 'new_match':
        return NotificationType.newMatch;
      case 'mutual_like':
        return NotificationType.mutualLike;
      case 'chat_expiring':
        return NotificationType.chatExpiring;
      case 'promotional':
        return NotificationType.promotional;
      case 'system_announcement':
        return NotificationType.systemAnnouncement;
      default:
        return NotificationType.systemAnnouncement;
    }
  }
}

/// Model class representing a push notification
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic> data;
  final Timestamp createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.data,
    required this.createdAt,
    this.isRead = false,
  });

  /// Factory constructor to create from Firestore document
  factory AppNotification.fromJson(Map<String, dynamic> json, String docId) {
    return AppNotification(
      id: docId,
      type: NotificationTypeExtension.fromString(json['type'] as String? ?? 'system_announcement'),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      createdAt: json['createdAt'] as Timestamp? ?? Timestamp.now(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'data': data,
      'createdAt': createdAt,
      'isRead': isRead,
    };
  }

  /// Create a copy with updated fields
  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? body,
    String? imageUrl,
    Map<String, dynamic>? data,
    Timestamp? createdAt,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  /// Get notification icon based on type
  String get iconEmoji {
    switch (type) {
      case NotificationType.newMessage:
        return '💬';
      case NotificationType.newMatch:
        return '🎭';
      case NotificationType.mutualLike:
        return '❤️';
      case NotificationType.chatExpiring:
        return '⏰';
      case NotificationType.promotional:
        return '🎉';
      case NotificationType.systemAnnouncement:
        return '📢';
    }
  }

  /// Get time ago string for display
  String get timeAgo {
    final now = DateTime.now();
    final notifTime = createdAt.toDate();
    final difference = now.difference(notifTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${notifTime.day}/${notifTime.month}/${notifTime.year}';
    }
  }
}

/// Payload data structure for different notification types
class NotificationPayload {
  /// Create payload for new message notification
  static Map<String, dynamic> newMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required int unreadCount,
    String? senderProfilePic,
  }) {
    return {
      'type': NotificationType.newMessage.value,
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderName': senderName,
      'unreadCount': unreadCount.toString(),
      'senderProfilePic': senderProfilePic ?? '',
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
    };
  }

  /// Create payload for new match notification
  static Map<String, dynamic> newMatch({
    required String chatRoomId,
    required String matchedUserId,
    required String matchedUserName,
    String? matchedUserProfilePic,
    double? compatibilityScore,
  }) {
    return {
      'type': NotificationType.newMatch.value,
      'chatRoomId': chatRoomId,
      'matchedUserId': matchedUserId,
      'matchedUserName': matchedUserName,
      'matchedUserProfilePic': matchedUserProfilePic ?? '',
      'compatibilityScore': compatibilityScore?.toString() ?? '0',
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
    };
  }

  /// Create payload for mutual like notification
  static Map<String, dynamic> mutualLike({
    required String chatRoomId,
    required String friendId,
    required String friendName,
    String? friendProfilePic,
  }) {
    return {
      'type': NotificationType.mutualLike.value,
      'chatRoomId': chatRoomId,
      'friendId': friendId,
      'friendName': friendName,
      'friendProfilePic': friendProfilePic ?? '',
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
    };
  }

  /// Create payload for chat expiring notification
  static Map<String, dynamic> chatExpiring({
    required String chatRoomId,
    required String otherUserName,
    required int hoursRemaining,
  }) {
    return {
      'type': NotificationType.chatExpiring.value,
      'chatRoomId': chatRoomId,
      'otherUserName': otherUserName,
      'hoursRemaining': hoursRemaining.toString(),
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
    };
  }

  /// Create payload for promotional notification
  static Map<String, dynamic> promotional({
    String? actionUrl,
    String? actionType,
  }) {
    return {
      'type': NotificationType.promotional.value,
      'actionUrl': actionUrl ?? '',
      'actionType': actionType ?? '',
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
    };
  }

  /// Create payload for system announcement
  static Map<String, dynamic> systemAnnouncement({
    String? actionUrl,
  }) {
    return {
      'type': NotificationType.systemAnnouncement.value,
      'actionUrl': actionUrl ?? '',
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
    };
  }
}
