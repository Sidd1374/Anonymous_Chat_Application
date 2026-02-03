import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veil_chat_application/models/notification_model.dart';
import 'package:veil_chat_application/services/local_notification_service.dart';

/// Background message handler - MUST be a top-level function
/// This is called when the app is in the background or terminated
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Note: We don't need to show notification here as FCM automatically
  // displays the notification when app is in background
  print('📬 Background message received: ${message.messageId}');
  print('   Title: ${message.notification?.title}');
  print('   Body: ${message.notification?.body}');
  print('   Data: ${message.data}');
}

/// Main notification service for handling Firebase Cloud Messaging
/// 
/// This service handles:
/// - FCM token management (get, refresh, store)
/// - Permission requests
/// - Foreground/Background message handling
/// - Navigation on notification tap
/// - Notification history storage
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalNotificationService _localNotificationService = LocalNotificationService();

  // Stream controllers for notification events
  final StreamController<RemoteMessage> _onMessageController = 
      StreamController<RemoteMessage>.broadcast();
  final StreamController<RemoteMessage> _onMessageOpenedAppController = 
      StreamController<RemoteMessage>.broadcast();

  /// Stream of messages received while app is in foreground
  Stream<RemoteMessage> get onMessage => _onMessageController.stream;

  /// Stream of messages that opened the app (tapped notification)
  Stream<RemoteMessage> get onMessageOpenedApp => _onMessageOpenedAppController.stream;

  String? _currentUserId;
  String? _fcmToken;
  bool _isInitialized = false;
  
  // Stream subscriptions to prevent memory leaks
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedAppSubscription;

  /// Get the current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if notifications are initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the notification service
  /// Call this early in app startup, after Firebase.initializeApp()
  Future<void> initialize({String? userId}) async {
    if (_isInitialized) {
      print('🔔 NotificationService already initialized');
      return;
    }

    try {
      print('🔔 Initializing NotificationService...');

      // Initialize local notifications for foreground display
      await _localNotificationService.initialize();

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Request permission
      await requestPermission();

      // Get and store FCM token
      if (userId != null) {
        _currentUserId = userId;
        await _getAndStoreToken();
      }

      // Set up foreground message handler
      _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Set up notification tap handler (app in background)
      _messageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        print('🔔 App opened from terminated state via notification');
        _handleNotificationTap(initialMessage);
      }

      // Set up token refresh listener
      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(_handleTokenRefresh);

      // Configure foreground notification presentation (iOS)
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _isInitialized = true;
      print('🔔 NotificationService initialized successfully');
    } catch (e) {
      print('❌ Error initializing NotificationService: $e');
    }
  }

  /// Request notification permission from the user
  Future<bool> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final isAuthorized = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      print('🔔 Notification permission: ${settings.authorizationStatus}');
      
      // Save permission status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', isAuthorized);

      return isAuthorized;
    } catch (e) {
      print('❌ Error requesting notification permission: $e');
      return false;
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Set the current user ID and update FCM token
  Future<void> setUserId(String userId) async {
    _currentUserId = userId;
    await _getAndStoreToken();
  }

  /// Clear user ID on logout
  Future<void> clearUserId() async {
    if (_currentUserId != null && _fcmToken != null) {
      // Remove FCM token from user document
      try {
        await _firestore.collection('users').doc(_currentUserId).update({
          'fcmTokens': FieldValue.arrayRemove([_fcmToken]),
        });
        print('🔔 FCM token removed from user document');
      } catch (e) {
        print('❌ Error removing FCM token: $e');
      }
    }
    _currentUserId = null;
  }

  /// Get FCM token and store it in Firestore
  Future<String?> _getAndStoreToken() async {
    try {
      // Get the token
      String? token;
      
      if (kIsWeb) {
        // For web, you need a VAPID key from Firebase Console
        // token = await _messaging.getToken(vapidKey: 'YOUR_VAPID_KEY');
        token = await _messaging.getToken();
      } else {
        token = await _messaging.getToken();
      }

      if (token == null) {
        print('❌ Failed to get FCM token');
        return null;
      }

      _fcmToken = token;
      print('🔔 FCM Token: ${token.substring(0, 20)}...');

      // Store token in Firestore if user is logged in
      if (_currentUserId != null) {
        await _storeTokenInFirestore(token);
      }

      // Also save locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);

      return token;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Store FCM token in Firestore user document
  Future<void> _storeTokenInFirestore(String token) async {
    if (_currentUserId == null) return;

    try {
      // Get device info for multi-device support
      final deviceInfo = await _getDeviceInfo();

      // Store token in fcmTokens array
      await _firestore.collection('users').doc(_currentUserId).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));

      // Store device info separately (can't use serverTimestamp in arrayUnion)
      await _firestore.collection('users').doc(_currentUserId).collection('devices').doc(token.hashCode.toString()).set({
        'token': token,
        'platform': Platform.operatingSystem,
        'deviceInfo': deviceInfo,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('🔔 FCM token stored in Firestore');
    } catch (e) {
      print('❌ Error storing FCM token: $e');
    }
  }

  /// Get basic device info
  Future<String> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        return 'Android Device';
      } else if (Platform.isIOS) {
        return 'iOS Device';
      } else {
        return 'Unknown Device';
      }
    } catch (e) {
      return 'Unknown Device';
    }
  }

  /// Handle token refresh
  void _handleTokenRefresh(String newToken) async {
    print('🔔 FCM token refreshed');
    
    // Remove old token if exists
    if (_currentUserId != null && _fcmToken != null && _fcmToken != newToken) {
      try {
        await _firestore.collection('users').doc(_currentUserId).update({
          'fcmTokens': FieldValue.arrayRemove([_fcmToken]),
        });
      } catch (e) {
        print('❌ Error removing old FCM token: $e');
      }
    }

    // Store new token
    _fcmToken = newToken;
    if (_currentUserId != null) {
      await _storeTokenInFirestore(newToken);
    }

    // Save locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', newToken);
  }

  /// Handle foreground messages
  /// NOTE: We don't show local notification here - the stream listener in main.dart
  /// will show an in-app overlay instead for better UX
  void _handleForegroundMessage(RemoteMessage message) {
    print('🔔 Foreground message received:');
    print('   Title: ${message.notification?.title}');
    print('   Body: ${message.notification?.body}');
    print('   Data: ${message.data}');

    // Get image URL from various sources
    String? imageUrl = message.notification?.android?.imageUrl ??
        message.notification?.apple?.imageUrl ??
        message.data['imageUrl'] ??
        message.data['image'];
    
    print('   Image URL: $imageUrl');

    // Emit to stream for in-app overlay handling (handled in main.dart)
    // DO NOT show local notification here - we want in-app overlay when app is open
    _onMessageController.add(message);

    // Store notification in history (optional)
    _storeNotificationHistory(message);
  }

  /// Handle notification tap (when app opens from notification)
  void _handleNotificationTap(RemoteMessage message) {
    print('🔔 Notification tapped:');
    print('   Data: ${message.data}');

    // Emit to stream for navigation handling
    _onMessageOpenedAppController.add(message);

    // Mark notification as read in history
    _markNotificationAsRead(message.messageId ?? '');
  }

  /// Store notification in Firestore history
  Future<void> _storeNotificationHistory(RemoteMessage message) async {
    if (_currentUserId == null) return;

    try {
      final notification = AppNotification(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        type: NotificationTypeExtension.fromString(message.data['type'] ?? 'system_announcement'),
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
        imageUrl: message.notification?.android?.imageUrl,
        data: message.data,
        createdAt: Timestamp.now(),
        isRead: false,
      );

      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toJson());
    } catch (e) {
      print('❌ Error storing notification history: $e');
    }
  }

  /// Mark notification as read
  Future<void> _markNotificationAsRead(String notificationId) async {
    if (_currentUserId == null || notificationId.isEmpty) return;

    try {
      final docRef = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('notifications')
          .doc(notificationId);
      
      // Check if document exists before updating
      final doc = await docRef.get();
      if (doc.exists) {
        await docRef.update({'isRead': true});
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// Get notification history for current user
  Stream<List<AppNotification>> getNotificationHistory({int limit = 50}) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Get unread notification count
  Stream<int> getUnreadCount() {
    if (_currentUserId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_currentUserId == null) return;

    try {
      final batch = _firestore.batch();
      final unread = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  /// Clear all notification history
  Future<void> clearNotificationHistory() async {
    if (_currentUserId == null) return;

    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('notifications')
          .get();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('❌ Error clearing notification history: $e');
    }
  }

  /// Subscribe to a topic (for broadcast notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('🔔 Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('🔔 Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic: $e');
    }
  }

  /// Update user segment subscriptions based on user data
  /// Call this after user profile updates or on login
  Future<void> updateUserSegments({
    required String userId,
    bool isPremium = false,
    String? gender,
    int? age,
    bool isVerified = false,
    String? country,
  }) async {
    try {
      // Always subscribe to all_users
      await subscribeToTopic('all_users');

      // Premium vs Free users
      if (isPremium) {
        await subscribeToTopic('premium_users');
        await unsubscribeFromTopic('free_users');
      } else {
        await subscribeToTopic('free_users');
        await unsubscribeFromTopic('premium_users');
      }

      // Gender-based topics
      if (gender != null) {
        final genderTopic = 'gender_${gender.toLowerCase()}';
        await subscribeToTopic(genderTopic);
      }

      // Age group topics
      if (age != null) {
        String ageGroup;
        if (age < 18) {
          ageGroup = 'age_under_18';
        } else if (age <= 25) {
          ageGroup = 'age_18_25';
        } else if (age <= 35) {
          ageGroup = 'age_26_35';
        } else if (age <= 50) {
          ageGroup = 'age_36_50';
        } else {
          ageGroup = 'age_over_50';
        }
        await subscribeToTopic(ageGroup);
      }

      // Verified users
      if (isVerified) {
        await subscribeToTopic('verified_users');
      }

      // Country/Region based
      if (country != null && country.isNotEmpty) {
        await subscribeToTopic('region_${country.toLowerCase()}');
      }

      // Store segments in Firestore for server-side targeting
      await _firestore.collection('users').doc(userId).set({
        'notificationSegments': {
          'isPremium': isPremium,
          'gender': gender,
          'ageGroup': age != null ? _getAgeGroup(age) : null,
          'isVerified': isVerified,
          'country': country,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      print('🔔 User segments updated for $userId');
    } catch (e) {
      print('❌ Error updating user segments: $e');
    }
  }

  /// Get age group string from age
  String _getAgeGroup(int age) {
    if (age < 18) return 'under_18';
    if (age <= 25) return '18_25';
    if (age <= 35) return '26_35';
    if (age <= 50) return '36_50';
    return 'over_50';
  }

  /// Dispose resources
  void dispose() {
    // Cancel all stream subscriptions to prevent memory leaks
    _tokenRefreshSubscription?.cancel();
    _foregroundMessageSubscription?.cancel();
    _messageOpenedAppSubscription?.cancel();
    
    // Close stream controllers
    _onMessageController.close();
    _onMessageOpenedAppController.close();
  }
}
