import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart' as app_user;

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUser(app_user.User user) {
    return _db.collection('users').doc(user.uid).set(user.toJson());
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) {
    return _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) {
    return _db.collection('users').doc(uid).get();
  }

  // ==================== FCM TOKEN MANAGEMENT ====================

  /// Add FCM token to user's document (for push notifications)
  Future<void> addFcmToken(String uid, String token, {String? platform, String? deviceInfo}) {
    return _db.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'fcmDevices': FieldValue.arrayUnion([
        {
          'token': token,
          'platform': platform ?? 'unknown',
          'deviceInfo': deviceInfo ?? 'Unknown Device',
          'updatedAt': FieldValue.serverTimestamp(),
        }
      ]),
    }, SetOptions(merge: true));
  }

  /// Remove FCM token from user's document (on logout or token refresh)
  Future<void> removeFcmToken(String uid, String token) {
    return _db.collection('users').doc(uid).update({
      'fcmTokens': FieldValue.arrayRemove([token]),
    });
  }

  /// Update notification preferences for user
  Future<void> updateNotificationPreferences(String uid, {
    bool? messagesEnabled,
    bool? matchesEnabled,
    bool? promotionalEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    final Map<String, dynamic> prefs = {};
    if (messagesEnabled != null) prefs['messages'] = messagesEnabled;
    if (matchesEnabled != null) prefs['matches'] = matchesEnabled;
    if (promotionalEnabled != null) prefs['promotional'] = promotionalEnabled;
    if (soundEnabled != null) prefs['sound'] = soundEnabled;
    if (vibrationEnabled != null) prefs['vibration'] = vibrationEnabled;

    return _db.collection('users').doc(uid).set({
      'notificationPreferences': prefs,
    }, SetOptions(merge: true));
  }

  /// Get user's notification preferences
  Future<Map<String, dynamic>?> getNotificationPreferences(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['notificationPreferences'] as Map<String, dynamic>?;
  }
}

