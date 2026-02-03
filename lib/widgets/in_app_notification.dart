import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Global notification manager that can be accessed from anywhere
class InAppNotification {
  static final InAppNotification _instance = InAppNotification._internal();
  factory InAppNotification() => _instance;
  InAppNotification._internal();

  /// Initialize with the overlay from MaterialApp builder
  static TransitionBuilder init() {
    return (context, child) {
      return _NotificationOverlayWrapper(child: child);
    };
  }

  /// Show notification
  static void show({
    required String title,
    required String body,
    String? imageUrl,
    String? type,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 5),
  }) {
    _NotificationOverlayWrapper._showNotification(
      title: title,
      body: body,
      imageUrl: imageUrl,
      type: type,
      onTap: onTap,
      duration: duration,
    );
  }

  /// Dismiss current notification
  static void dismiss() {
    _NotificationOverlayWrapper._dismissNotification();
  }
}

class _NotificationOverlayWrapper extends StatefulWidget {
  final Widget? child;
  
  const _NotificationOverlayWrapper({this.child});

  static _NotificationOverlayWrapperState? _state;

  static void _showNotification({
    required String title,
    required String body,
    String? imageUrl,
    String? type,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 5),
  }) {
    // Safety check: ensure state is available before showing
    if (_state == null) {
      print('⚠️ InAppNotification: State not available, notification skipped');
      return;
    }
    _state?.showNotification(
      title: title,
      body: body,
      imageUrl: imageUrl,
      type: type,
      onTap: onTap,
      duration: duration,
    );
  }

  static void _dismissNotification() {
    _state?.dismissNotification();
  }

  @override
  State<_NotificationOverlayWrapper> createState() => _NotificationOverlayWrapperState();
}

class _NotificationOverlayWrapperState extends State<_NotificationOverlayWrapper> {
  Timer? _dismissTimer;
  bool _isShowingNotification = false;
  
  // Notification data
  String _title = '';
  String _body = '';
  String? _imageUrl;
  String? _type;
  VoidCallback? _onTap;

  @override
  void initState() {
    super.initState();
    _NotificationOverlayWrapper._state = this;
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _NotificationOverlayWrapper._state = null;
    super.dispose();
  }

  void showNotification({
    required String title,
    required String body,
    String? imageUrl,
    String? type,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 5),
  }) {
    setState(() {
      _title = title;
      _body = body;
      _imageUrl = imageUrl;
      _type = type;
      _onTap = onTap;
      _isShowingNotification = true;
    });

    _dismissTimer?.cancel();
    _dismissTimer = Timer(duration, dismissNotification);
  }

  void dismissNotification() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (mounted) {
      setState(() {
        _isShowingNotification = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        children: [
          // Main app content
          if (widget.child != null) widget.child!,
          
          // Notification overlay
          if (_isShowingNotification)
            _NotificationCard(
              title: _title,
              body: _body,
              imageUrl: _imageUrl,
              type: _type,
              onTap: () {
                dismissNotification();
                _onTap?.call();
              },
              onDismiss: dismissNotification,
            ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatefulWidget {
  final String title;
  final String body;
  final String? imageUrl;
  final String? type;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const _NotificationCard({
    required this.title,
    required this.body,
    this.imageUrl,
    this.type,
    this.onTap,
    this.onDismiss,
  });

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getIcon() {
    switch (widget.type) {
      case 'new_message':
        return Icons.chat_bubble_rounded;
      case 'new_match':
      case 'mutual_like':
        return Icons.favorite_rounded;
      case 'promotional':
        return Icons.local_offer_rounded;
      case 'chat_expiry_warning':
        return Icons.hourglass_bottom_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColor() {
    switch (widget.type) {
      case 'new_message':
        return const Color(0xFF007AFF);
      case 'new_match':
      case 'mutual_like':
        return const Color(0xFFFF2D55);
      case 'promotional':
        return const Color(0xFFFF9500);
      case 'chat_expiry_warning':
        return const Color(0xFFFFCC00);
      default:
        return const Color(0xFF5856D6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: topPadding + 8,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: widget.onTap,
            onVerticalDragEnd: (details) {
              if (details.velocity.pixelsPerSecond.dy < -50) {
                widget.onDismiss?.call();
              }
            },
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        // Icon container with gradient
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _getColor(),
                                _getColor().withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _getColor().withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _getIcon(),
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // App name row
                              Row(
                                children: [
                                  Text(
                                    'VEIL CHAT',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[500],
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '•',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'now',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Title
                              Text(
                                widget.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              // Body
                              Text(
                                widget.body,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark 
                                      ? Colors.grey[400] 
                                      : Colors.grey[600],
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Image thumbnail (if available)
                        if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: widget.imageUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              errorWidget: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
