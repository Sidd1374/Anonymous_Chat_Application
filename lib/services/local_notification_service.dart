import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:veil_chat_application/models/notification_model.dart';
import 'package:http/http.dart' as http;

/// Callback for handling notification taps
/// Must be a top-level function for background handling
@pragma('vm:entry-point')
void onDidReceiveNotificationResponse(NotificationResponse response) {
  print('🔔 Local notification tapped: ${response.payload}');
  // Navigation will be handled by the NotificationService stream
}

/// Background notification action handler
@pragma('vm:entry-point')
void onDidReceiveBackgroundNotificationResponse(NotificationResponse response) {
  print('🔔 Background local notification action: ${response.payload}');
}

/// Service for displaying local notifications when app is in foreground
/// 
/// FCM automatically shows notifications when app is in background/terminated,
/// but we need to use local notifications for foreground display.
class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Android notification channel IDs
  static const String _messageChannelId = 'veil_messages';
  static const String _matchChannelId = 'veil_matches';
  static const String _generalChannelId = 'veil_general';

  /// Notification IDs
  int _notificationId = 0;
  int get _nextNotificationId => _notificationId++;

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the local notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔔 Initializing LocalNotificationService...');

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      // Combined initialization settings
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize the plugin
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: onDidReceiveBackgroundNotificationResponse,
      );

      // Create notification channels for Android 8.0+
      if (Platform.isAndroid) {
        await _createNotificationChannels();
      }

      _isInitialized = true;
      print('🔔 LocalNotificationService initialized successfully');
    } catch (e) {
      print('❌ Error initializing LocalNotificationService: $e');
    }
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Messages channel - High importance for chat messages
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _messageChannelId,
        'Messages',
        description: 'Notifications for new chat messages',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );

    // Matches channel - High importance for new matches
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _matchChannelId,
        'Matches',
        description: 'Notifications for new matches and friends',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );

    // General channel - Default importance for other notifications
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _generalChannelId,
        'General',
        description: 'General app notifications',
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );

    print('🔔 Android notification channels created');
  }

  /// Get the appropriate channel ID based on notification type
  String _getChannelId(NotificationType type) {
    switch (type) {
      case NotificationType.newMessage:
        return _messageChannelId;
      case NotificationType.newMatch:
      case NotificationType.mutualLike:
        return _matchChannelId;
      default:
        return _generalChannelId;
    }
  }

  /// Get the appropriate channel name based on notification type
  String _getChannelName(NotificationType type) {
    switch (type) {
      case NotificationType.newMessage:
        return 'Messages';
      case NotificationType.newMatch:
      case NotificationType.mutualLike:
        return 'Matches';
      default:
        return 'General';
    }
  }

  /// Show a notification
  Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
    String? imageUrl,
    NotificationType type = NotificationType.systemAnnouncement,
  }) async {
    if (!_isInitialized) {
      print('⚠️ LocalNotificationService not initialized');
      return;
    }

    try {
      final channelId = _getChannelId(type);
      final channelName = _getChannelName(type);
      
      // Download image if URL is provided
      ByteArrayAndroidBitmap? largeIconBitmap;
      BigPictureStyleInformation? bigPictureStyle;
      
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final imageBytes = await _downloadImage(imageUrl);
          if (imageBytes != null) {
            largeIconBitmap = ByteArrayAndroidBitmap(imageBytes);
            bigPictureStyle = BigPictureStyleInformation(
              ByteArrayAndroidBitmap(imageBytes),
              largeIcon: ByteArrayAndroidBitmap(imageBytes),
              contentTitle: title,
              summaryText: body,
              hideExpandedLargeIcon: false,
            );
          }
        } catch (e) {
          print('⚠️ Failed to download notification image: $e');
        }
      }
      
      // Android notification details
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        // Large icon for sender's profile pic
        largeIcon: largeIconBitmap ?? const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        // Style for big picture or text
        styleInformation: bigPictureStyle ?? 
            (type == NotificationType.newMessage ? BigTextStyleInformation(body) : null),
      );

      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Combined notification details
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Convert payload to JSON string
      final payloadString = payload != null ? jsonEncode(payload) : null;

      // Show the notification
      await _notificationsPlugin.show(
        _nextNotificationId,
        title,
        body,
        notificationDetails,
        payload: payloadString,
      );

      print('🔔 Local notification shown: $title');
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }

  /// Download image from URL and return bytes
  Future<Uint8List?> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 5),
      );
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      print('⚠️ Error downloading image: $e');
    }
    return null;
  }

  /// Show a grouped notification (for multiple messages)
  Future<void> showGroupedNotification({
    required String title,
    required String body,
    required String groupKey,
    required int count,
    Map<String, dynamic>? payload,
  }) async {
    if (!_isInitialized) return;

    try {
      // Summary notification for the group
      final summaryAndroidDetails = AndroidNotificationDetails(
        _messageChannelId,
        'Messages',
        importance: Importance.high,
        priority: Priority.high,
        groupKey: groupKey,
        setAsGroupSummary: true,
        styleInformation: InboxStyleInformation(
          [body],
          contentTitle: title,
          summaryText: '$count messages',
        ),
      );

      await _notificationsPlugin.show(
        groupKey.hashCode,
        title,
        '$count new messages',
        NotificationDetails(android: summaryAndroidDetails),
        payload: payload != null ? jsonEncode(payload) : null,
      );
    } catch (e) {
      print('❌ Error showing grouped notification: $e');
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Cancel notifications for a specific chat room
  Future<void> cancelChatNotifications(String chatRoomId) async {
    // Using chatRoomId hash as notification ID group
    await _notificationsPlugin.cancel(chatRoomId.hashCode);
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  /// Check if notifications are enabled at the system level
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  /// Request notification permissions (for Android 13+)
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }
}
