import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Enum to represent the matching status
enum MatchingStatus {
  searching, // Currently looking for a match
  matched, // Found a match
  cancelled, // User cancelled the search
  timeout, // Search timed out
  error, // An error occurred
}

/// Result of a matching operation
class MatchResult {
  final MatchingStatus status;
  final String? chatRoomId;
  final String? matchedUserId;
  final String? matchedUserName;
  final String? matchedUserProfilePic;
  final String? errorMessage;
  final double? compatibilityScore;

  MatchResult({
    required this.status,
    this.chatRoomId,
    this.matchedUserId,
    this.matchedUserName,
    this.matchedUserProfilePic,
    this.errorMessage,
    this.compatibilityScore,
  });
}

/// Service for handling user matching using Firebase Cloud Functions
class MatchingService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Find a match using Global Cloud Selection
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
    List<String>? interests,
    List<String>? dealBreakers,
    double? userLatitude,
    double? userLongitude,
  }) async* {
    try {
      yield MatchResult(status: MatchingStatus.searching);

      // Call the Cloud Function
      final result = await _functions.httpsCallable('findGlobalMatch').call({
        'preferredGender': preferredGender,
        'preferredMinAge': preferredMinAge,
        'preferredMaxAge': preferredMaxAge,
        'preferVerifiedOnly': preferVerifiedOnly,
        'interests': interests,
        'dealBreakers': dealBreakers,
        'latitude': userLatitude,
        'longitude': userLongitude,
      });

      final data = result.data as Map<String, dynamic>;

      if (data['status'] == 'matched') {
        yield MatchResult(
          status: MatchingStatus.matched,
          chatRoomId: data['chatRoomId'],
          matchedUserId: data['matchedUserId'],
          matchedUserName: data['matchedUserName'],
          matchedUserProfilePic: data['matchedUserProfilePic'],
          compatibilityScore: (data['compatibilityScore'] as num?)?.toDouble(),
        );
      } else if (data['status'] == 'no_match_found') {
        // If no match found immediately, we can return timeout
        // or just wait and retry if we want a "searching" experience.
        // For now, we'll signal timeout so the UI can decide to retry.
        yield MatchResult(status: MatchingStatus.timeout);
      } else if (data['status'] == 'error') {
        yield MatchResult(
          status: MatchingStatus.error,
          errorMessage: data['message'] ?? "Server-side error occurred.",
        );
      } else {
        yield MatchResult(
          status: MatchingStatus.error,
          errorMessage: "Unknown response from server.",
        );
      }
    } catch (e) {
      print('Error in global matching: $e');
      yield MatchResult(
        status: MatchingStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Cancel logic is no longer needed for cloud functions (they are one-shot)
  /// but we keep the method for compatibility with existing UI calls.
  Future<void> cancelSearch(String userId) async {
    // No-op for global search
  }
}
