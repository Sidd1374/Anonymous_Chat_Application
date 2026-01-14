import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veil_chat_application/services/chat_service.dart';
import 'package:veil_chat_application/services/relationship_service.dart';

/// Enum to represent the matching status
enum MatchingStatus {
  searching,  // Currently looking for a match
  matched,    // Found a match
  cancelled,  // User cancelled the search
  timeout,    // Search timed out
  error,      // An error occurred
}

/// Model for a user in the matching queue
class MatchingQueueEntry {
  final String odId;
  final String? name;
  final String? profilePicUrl;
  final String? gender;
  final int? age;
  final int? verificationLevel;
  final String? preferredGender;
  final int? preferredMinAge;
  final int? preferredMaxAge;
  final bool? preferVerifiedOnly;
  final Timestamp queuedAt;
  final Timestamp expiresAt;

  MatchingQueueEntry({
    required this.odId,
    this.name,
    this.profilePicUrl,
    this.gender,
    this.age,
    this.verificationLevel,
    this.preferredGender,
    this.preferredMinAge,
    this.preferredMaxAge,
    this.preferVerifiedOnly,
    required this.queuedAt,
    required this.expiresAt,
  });

  factory MatchingQueueEntry.fromJson(Map<String, dynamic> json, String docId) {
    return MatchingQueueEntry(
      odId: docId,
      name: json['name'] as String?,
      profilePicUrl: json['profilePicUrl'] as String?,
      gender: json['gender'] as String?,
      age: json['age'] as int?,
      verificationLevel: json['verificationLevel'] as int?,
      preferredGender: json['preferredGender'] as String?,
      preferredMinAge: json['preferredMinAge'] as int?,
      preferredMaxAge: json['preferredMaxAge'] as int?,
      preferVerifiedOnly: json['preferVerifiedOnly'] as bool?,
      queuedAt: json['queuedAt'] as Timestamp? ?? Timestamp.now(),
      expiresAt: json['expiresAt'] as Timestamp? ?? Timestamp.fromDate(
        DateTime.now().add(const Duration(minutes: 5)),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'profilePicUrl': profilePicUrl,
      'gender': gender,
      'age': age,
      'verificationLevel': verificationLevel,
      'preferredGender': preferredGender,
      'preferredMinAge': preferredMinAge,
      'preferredMaxAge': preferredMaxAge,
      'preferVerifiedOnly': preferVerifiedOnly,
      'queuedAt': queuedAt,
      'expiresAt': expiresAt,
    };
  }

  /// Check if this entry is compatible with another entry based on preferences
  bool isCompatibleWith(MatchingQueueEntry other) {
    // Don't match with self
    if (odId == other.odId) return false;

    // Check gender preference
    if (preferredGender != null && preferredGender != 'Any') {
      if (other.gender != preferredGender) return false;
    }
    if (other.preferredGender != null && other.preferredGender != 'Any') {
      if (gender != other.preferredGender) return false;
    }

    // Check age preferences
    if (preferredMinAge != null && other.age != null) {
      if (other.age! < preferredMinAge!) return false;
    }
    if (preferredMaxAge != null && other.age != null) {
      if (other.age! > preferredMaxAge!) return false;
    }
    if (other.preferredMinAge != null && age != null) {
      if (age! < other.preferredMinAge!) return false;
    }
    if (other.preferredMaxAge != null && age != null) {
      if (age! > other.preferredMaxAge!) return false;
    }

    // Check verification preference
    if (preferVerifiedOnly == true) {
      if (other.verificationLevel == null || other.verificationLevel! < 2) {
        return false;
      }
    }
    if (other.preferVerifiedOnly == true) {
      if (verificationLevel == null || verificationLevel! < 2) {
        return false;
      }
    }

    return true;
  }
}

/// Result of a matching operation
class MatchResult {
  final MatchingStatus status;
  final String? chatRoomId;
  final String? matchedUserId;
  final String? matchedUserName;
  final String? matchedUserProfilePic;
  final String? errorMessage;

  MatchResult({
    required this.status,
    this.chatRoomId,
    this.matchedUserId,
    this.matchedUserName,
    this.matchedUserProfilePic,
    this.errorMessage,
  });
}

/// Service for handling user matching (finding strangers to chat with)
class MatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatService _chatService = ChatService();
  final RelationshipService _relationshipService = RelationshipService();

  CollectionReference get _matchingQueue => _firestore.collection('matching_queue');

  // Search timeout duration
  static const Duration searchTimeout = Duration(minutes: 5);

  /// Join the matching queue and wait for a match
  /// Returns a stream that emits the matching result when found
  Stream<MatchResult> joinMatchingQueue({
    required String userId,
    String? userName,
    String? userProfilePic,
    String? userGender,
    int? userAge,
    int? userVerificationLevel,
    String? preferredGender,
    int? preferredMinAge,
    int? preferredMaxAge,
    bool? preferVerifiedOnly,
  }) async* {
    try {
      // First, check if there are any compatible users already in the queue
      final existingMatch = await _findExistingMatch(
        userId: userId,
        userGender: userGender,
        userAge: userAge,
        userVerificationLevel: userVerificationLevel,
        preferredGender: preferredGender,
        preferredMinAge: preferredMinAge,
        preferredMaxAge: preferredMaxAge,
        preferVerifiedOnly: preferVerifiedOnly,
      );

      if (existingMatch != null) {
        // Found a match! Create chat room and return
        yield* _createMatchAndCleanup(
          user1Id: userId,
          user1Name: userName,
          user1ProfilePic: userProfilePic,
          user2Entry: existingMatch,
        );
        return;
      }

      // No immediate match found, add to queue
      final queueEntry = MatchingQueueEntry(
        odId: userId,
        name: userName,
        profilePicUrl: userProfilePic,
        gender: userGender,
        age: userAge,
        verificationLevel: userVerificationLevel,
        preferredGender: preferredGender,
        preferredMinAge: preferredMinAge,
        preferredMaxAge: preferredMaxAge,
        preferVerifiedOnly: preferVerifiedOnly,
        queuedAt: Timestamp.now(),
        expiresAt: Timestamp.fromDate(DateTime.now().add(searchTimeout)),
      );

      await _matchingQueue.doc(userId).set(queueEntry.toJson());

      // Listen for matches
      yield MatchResult(status: MatchingStatus.searching);

      // Set up a listener for when we get matched
      final completer = Completer<MatchResult>();
      final subscription = _firestore
          .collection('matches')
          .doc(userId)
          .snapshots()
          .listen((snapshot) async {
        if (snapshot.exists && !completer.isCompleted) {
          final data = snapshot.data()!;
          final chatRoomId = data['chatRoomId'] as String?;
          final matchedUserId = data['matchedUserId'] as String?;
          final matchedUserName = data['matchedUserName'] as String?;
          final matchedUserProfilePic = data['matchedUserProfilePic'] as String?;

          // Clean up
          await _matchingQueue.doc(userId).delete();
          await _firestore.collection('matches').doc(userId).delete();

          completer.complete(MatchResult(
            status: MatchingStatus.matched,
            chatRoomId: chatRoomId,
            matchedUserId: matchedUserId,
            matchedUserName: matchedUserName,
            matchedUserProfilePic: matchedUserProfilePic,
          ));
        }
      });

      // Set up timeout
      Future.delayed(searchTimeout, () async {
        if (!completer.isCompleted) {
          await subscription.cancel();
          await _matchingQueue.doc(userId).delete();
          completer.complete(MatchResult(status: MatchingStatus.timeout));
        }
      });

      final result = await completer.future;
      await subscription.cancel();
      yield result;

    } catch (e) {
      print('Error in matching queue: $e');
      yield MatchResult(
        status: MatchingStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Find an existing compatible match in the queue
  Future<MatchingQueueEntry?> _findExistingMatch({
    required String userId,
    String? userGender,
    int? userAge,
    int? userVerificationLevel,
    String? preferredGender,
    int? preferredMinAge,
    int? preferredMaxAge,
    bool? preferVerifiedOnly,
  }) async {
    // Get users who have blocked or been blocked by current user
    final blockedUsers = await _relationshipService.getBlockedUsers(userId);
    
    // Get users already connected (friends or active stranger chats)
    final existingConnections = <String>[];
    final friendsList = await _relationshipService.getFriendsList(userId);
    existingConnections.addAll(friendsList);

    // Get current queue entries
    final now = Timestamp.now();
    final queueSnapshot = await _matchingQueue
        .where('expiresAt', isGreaterThan: now)
        .get();

    final currentUserEntry = MatchingQueueEntry(
      odId: userId,
      gender: userGender,
      age: userAge,
      verificationLevel: userVerificationLevel,
      preferredGender: preferredGender,
      preferredMinAge: preferredMinAge,
      preferredMaxAge: preferredMaxAge,
      preferVerifiedOnly: preferVerifiedOnly,
      queuedAt: now,
      expiresAt: Timestamp.fromDate(DateTime.now().add(searchTimeout)),
    );

    // Find compatible matches
    final compatibleMatches = <MatchingQueueEntry>[];
    
    for (final doc in queueSnapshot.docs) {
      final entry = MatchingQueueEntry.fromJson(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );

      // Skip blocked users
      if (blockedUsers.contains(entry.odId)) continue;

      // Skip existing connections
      if (existingConnections.contains(entry.odId)) continue;

      // Check compatibility
      if (currentUserEntry.isCompatibleWith(entry)) {
        compatibleMatches.add(entry);
      }
    }

    if (compatibleMatches.isEmpty) return null;

    // Return a random compatible match (or could prioritize by queue time)
    return compatibleMatches[Random().nextInt(compatibleMatches.length)];
  }

  /// Create a match between two users and clean up the queue
  Stream<MatchResult> _createMatchAndCleanup({
    required String user1Id,
    String? user1Name,
    String? user1ProfilePic,
    required MatchingQueueEntry user2Entry,
  }) async* {
    try {
      // Create chat room
      final chatRoomId = await _relationshipService.matchWithStranger(
        currentUserId: user1Id,
        strangerId: user2Entry.odId,
        currentUserName: user1Name,
        strangerName: user2Entry.name,
        currentUserProfilePic: user1ProfilePic,
        strangerProfilePic: user2Entry.profilePicUrl,
      );

      // Notify the other user about the match
      await _firestore.collection('matches').doc(user2Entry.odId).set({
        'chatRoomId': chatRoomId,
        'matchedUserId': user1Id,
        'matchedUserName': user1Name,
        'matchedUserProfilePic': user1ProfilePic,
        'matchedAt': Timestamp.now(),
      });

      // Remove both users from the queue
      await _matchingQueue.doc(user1Id).delete();
      await _matchingQueue.doc(user2Entry.odId).delete();

      // Send initial system message
      await _chatService.sendSystemMessage(
        chatRoomId: chatRoomId,
        text: '🎉 You\'ve been matched! Say hello!',
        user1Id: user1Id,
        user2Id: user2Entry.odId,
      );

      yield MatchResult(
        status: MatchingStatus.matched,
        chatRoomId: chatRoomId,
        matchedUserId: user2Entry.odId,
        matchedUserName: user2Entry.name,
        matchedUserProfilePic: user2Entry.profilePicUrl,
      );
    } catch (e) {
      print('Error creating match: $e');
      yield MatchResult(
        status: MatchingStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Cancel an ongoing search
  Future<void> cancelSearch(String userId) async {
    try {
      await _matchingQueue.doc(userId).delete();
    } catch (e) {
      print('Error cancelling search: $e');
    }
  }

  /// Check if user is currently in the matching queue
  Future<bool> isInQueue(String userId) async {
    final doc = await _matchingQueue.doc(userId).get();
    return doc.exists;
  }

  /// Clean up expired queue entries (should be run periodically)
  Future<void> cleanupExpiredEntries() async {
    final now = Timestamp.now();
    final expiredEntries = await _matchingQueue
        .where('expiresAt', isLessThan: now)
        .get();

    final batch = _firestore.batch();
    for (final doc in expiredEntries.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
