import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UserCard extends StatelessWidget {
  final String name;
  final String imagePath;
  final bool isLevel2Verified;
  final bool isOnline;
  final String? lastSeen;
  final String? lastMessage;
  final int unreadCount;
  final VoidCallback? onPressed;

  const UserCard({
    super.key,
    required this.name,
    required this.imagePath,
    this.isLevel2Verified = false,
    this.isOnline = false,
    this.lastSeen,
    this.lastMessage,
    this.unreadCount = 0,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 180,
        height: 230,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: Theme.of(context).colorScheme.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          shadows: [
            BoxShadow(
              color: Theme.of(context).colorScheme.secondary,
              blurRadius: 10,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            )
          ],
        ),
        child: Stack(
          children: [
            // Profile Image with Online Indicator
            Positioned(
              left: 40,
              top: 20,
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: ShapeDecoration(
                      image: DecorationImage(
                        image: imagePath.startsWith('http')
                            ? CachedNetworkImageProvider(imagePath)
                            : AssetImage(imagePath) as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                      shape: OvalBorder(
                        side: BorderSide(
                          width: 2,
                          color: isOnline
                              ? const Color(0xFF4CAF50)
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  // Online status indicator
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: isOnline
                            ? const Color(0xFF4CAF50)
                            : Colors.grey.shade500,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.secondary,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Name
            Positioned(
              left: 10,
              top: 126,
              right: 10,
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color ??
                      const Color(0xFF282725),
                  fontSize: 15,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Last Seen / Online Status
            Positioned(
              left: 10,
              top: 146,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isOnline ? Icons.circle : Icons.access_time,
                    size: 10,
                    color: isOnline
                        ? const Color(0xFF4CAF50)
                        : theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      isOnline ? 'Online' : (lastSeen ?? 'Offline'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isOnline
                            ? const Color(0xFF4CAF50)
                            : theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.6),
                        fontSize: 11,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Last Message or Unread Count
            Positioned(
              left: 12,
              top: 168,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: unreadCount > 0
                      ? theme.colorScheme.primary.withOpacity(0.15)
                      : theme.colorScheme.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  unreadCount > 0
                      ? (unreadCount > 10
                          ? '10+ new messages'
                          : '$unreadCount new message${unreadCount > 1 ? 's' : ''}')
                      : (lastMessage ?? 'No messages yet'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: unreadCount > 0
                        ? theme.colorScheme.primary
                        : (lastMessage != null
                            ? theme.textTheme.bodyMedium?.color
                            : theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.5)),
                    fontSize: 11,
                    fontFamily: 'Inter',
                    fontWeight:
                        unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                    fontStyle: lastMessage == null && unreadCount == 0
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Level 2 Verification Logo (SVG) on top right
            if (isLevel2Verified)
              Positioned(
                right: 10,
                top: 10,
                child: SvgPicture.asset(
                  'assets/icons/icon_verified.svg',
                  width: 25,
                  height: 25,
                ),
              ),
            // Unread Message Badge
            if (unreadCount > 0)
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
