import 'package:flutter/material.dart';
import 'package:veil_chat_application/models/message_model.dart';

class ChatText extends StatelessWidget {
  final String text;
  final bool isSender;
  final bool isDeleted;
  // Reply fields
  final String? replyToText;
  final String? replyToSenderName;
  final bool isReplyToMe;
  final MessageType? replyToType;
  final VoidCallback? onReplyTap;

  const ChatText({
    super.key,
    required this.text,
    required this.isSender,
    this.isDeleted = false,
    this.replyToText,
    this.replyToSenderName,
    this.isReplyToMe = false,
    this.replyToType,
    this.onReplyTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasReply = replyToText != null;
    
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: isSender
            ? theme.colorScheme.primary
            : theme.colorScheme.secondary,
        borderRadius: BorderRadius.all(Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            offset: Offset(0, 4),
            blurRadius: 10,
            spreadRadius: 0,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply preview section
          if (hasReply)
            GestureDetector(
              onTap: onReplyTap,
              child: Container(
                margin: EdgeInsets.only(left: 8, right: 8, top: 8),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(
                      color: isReplyToMe 
                          ? theme.colorScheme.primary 
                          : theme.colorScheme.tertiary,
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isReplyToMe ? 'You' : (replyToSenderName ?? 'User'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isReplyToMe 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.tertiary,
                        fontSize: 11,
                      ),
                    ),
                    SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (replyToType == MessageType.image)
                          Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.image,
                              size: 14,
                              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                            ),
                          ),
                        Flexible(
                          child: Text(
                            replyToText ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          // Main message text
          Padding(
            padding: EdgeInsets.all(14),
            child: isDeleted
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.block,
                        size: 14,
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'This message was deleted',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                        ),
                      ),
                    ],
                  )
                : Text(
                    text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}