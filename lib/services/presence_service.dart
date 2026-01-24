import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class for user presence information
class UserPresence {
  final bool isOnline;
  final Timestamp? lastSeen;
  final bool isTyping;

  UserPresence({
    required this.isOnline,
    this.lastSeen,
    this.isTyping = false,
  });

  factory UserPresence.fromJson(Map<String, dynamic> json) {
    return UserPresence(
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] as Timestamp?,
      isTyping: json['isTyping'] as bool? ?? false,
    );
  }

  /// Format last seen as a human-readable string
  String formatLastSeen() {
    if (isOnline) return 'Online';
    if (lastSeen == null) return 'Offline';

    final lastSeenDate = lastSeen!.toDate();
    final now = DateTime.now();
    final difference = now.difference(lastSeenDate);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastSeenDate.day}/${lastSeenDate.month}/${lastSeenDate.year}';
    }
  }
}

/// Service class for managing user presence (online status, typing, last seen)
///
/// Firebase Structure:
/// - users/{userId}/
///   - isOnline: boolean
///   - lastSeen: Timestamp
/// - chats/{chatRoomId}/
///   - typingUsers: Map<userId, Timestamp>
class PresenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Debounce timer for typing status
  Timer? _typingTimer;
  String? _currentTypingChatId;

  // ==================== ONLINE STATUS ====================

  /// Set user's online status
  /// Call this when app becomes active/inactive
  Future<void> setOnlineStatus(String userId, bool isOnline) async {
    try {
      final updates = <String, dynamic>{
        'isOnline': isOnline,
      };

      // Update lastSeen when going offline
      if (!isOnline) {
        updates['lastSeen'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      // If document doesn't exist, create it with merge
      await _firestore.collection('users').doc(userId).set({
        'isOnline': isOnline,
        if (!isOnline) 'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Update last seen timestamp
  Future<void> updateLastSeen(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating last seen: $e');
    }
  }

  /// Stream a user's presence (online status and last seen)
  Stream<UserPresence> streamUserPresence(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        return UserPresence(isOnline: false);
      }
      final data = doc.data() as Map<String, dynamic>;
      return UserPresence(
        isOnline: data['isOnline'] as bool? ?? false,
        lastSeen: data['lastSeen'] as Timestamp?,
      );
    });
  }

  // ==================== TYPING STATUS ====================

  /// Set typing status for current user in a chat room
  /// Uses debouncing to avoid too many writes
  Future<void> setTypingStatus(
      String chatRoomId, String userId, bool isTyping) async {
    // Cancel any existing timer
    _typingTimer?.cancel();

    if (isTyping) {
      // If starting to type
      if (_currentTypingChatId != chatRoomId) {
        // Clear typing from previous chat if different
        if (_currentTypingChatId != null) {
          await _clearTypingStatus(_currentTypingChatId!, userId);
        }
        _currentTypingChatId = chatRoomId;
      }

      // Set typing status
      await _firestore.collection('chats').doc(chatRoomId).update({
        'typingUsers.$userId': FieldValue.serverTimestamp(),
      }).catchError((e) {
        // If field doesn't exist, create it
        _firestore.collection('chats').doc(chatRoomId).set({
          'typingUsers': {userId: FieldValue.serverTimestamp()},
        }, SetOptions(merge: true));
      });

      // Auto-clear typing after 5 seconds of no activity
      _typingTimer = Timer(const Duration(seconds: 5), () {
        _clearTypingStatus(chatRoomId, userId);
      });
    } else {
      // Immediately clear typing status
      await _clearTypingStatus(chatRoomId, userId);
    }
  }

  /// Clear typing status for a user
  Future<void> _clearTypingStatus(String chatRoomId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatRoomId).update({
        'typingUsers.$userId': FieldValue.delete(),
      });
      if (_currentTypingChatId == chatRoomId) {
        _currentTypingChatId = null;
      }
    } catch (e) {
      // Ignore errors if field doesn't exist
    }
  }

  /// Clear typing status when leaving a chat or sending a message
  Future<void> clearTyping(String chatRoomId, String userId) async {
    _typingTimer?.cancel();
    await _clearTypingStatus(chatRoomId, userId);
  }

  /// Stream typing status for a chat room
  /// Returns a map of userId -> isTyping (true if timestamp is within last 6 seconds)
  Stream<Map<String, bool>> streamTypingStatus(String chatRoomId) {
    return _firestore
        .collection('chats')
        .doc(chatRoomId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return <String, bool>{};

      final data = doc.data() as Map<String, dynamic>;
      final typingUsers = data['typingUsers'] as Map<String, dynamic>? ?? {};

      final now = DateTime.now();
      final result = <String, bool>{};

      typingUsers.forEach((userId, timestamp) {
        if (timestamp is Timestamp) {
          final typingTime = timestamp.toDate();
          final difference = now.difference(typingTime);
          // Consider typing if within last 6 seconds
          result[userId] = difference.inSeconds < 6;
        }
      });

      return result;
    });
  }

  /// Check if a specific user is typing in a chat
  Stream<bool> streamIsUserTyping(String chatRoomId, String userId) {
    return streamTypingStatus(chatRoomId).map((typingMap) {
      return typingMap[userId] ?? false;
    });
  }

  // ==================== CLEANUP ====================

  /// Dispose resources
  void dispose() {
    _typingTimer?.cancel();
  }

  /// Mark user as offline (call when app closes)
  Future<void> goOffline(String userId) async {
    _typingTimer?.cancel();
    if (_currentTypingChatId != null) {
      await _clearTypingStatus(_currentTypingChatId!, userId);
    }
    await setOnlineStatus(userId, false);
  }
}
