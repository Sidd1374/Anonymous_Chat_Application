import 'package:flutter/material.dart';
import 'package:veil_chat_application/services/chat_service.dart';

/// Floating reaction picker widget for messages
/// Shows a row of emoji buttons that can be selected
class ReactionPicker extends StatelessWidget {
  final Function(String emoji) onReactionSelected;
  final String? currentUserReaction;
  final VoidCallback? onClose;

  const ReactionPicker({
    super.key,
    required this.onReactionSelected,
    this.currentUserReaction,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...ChatService.availableReactions.map((emoji) {
            final isSelected = currentUserReaction == emoji;
            return GestureDetector(
              onTap: () {
                onReactionSelected(emoji);
                onClose?.call();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  emoji,
                  style: TextStyle(
                    fontSize: isSelected ? 28 : 24,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Widget to display reactions on a message
/// Shows reaction emojis with count in a row
class MessageReactions extends StatelessWidget {
  final Map<String, List<String>>? reactions;
  final String currentUserId;
  final Function(String emoji) onReactionTap;

  const MessageReactions({
    super.key,
    required this.reactions,
    required this.currentUserId,
    required this.onReactionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions == null || reactions!.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: reactions!.entries.map((entry) {
        final emoji = entry.key;
        final userIds = entry.value;
        final count = userIds.length;
        final hasUserReacted = userIds.contains(currentUserId);

        return GestureDetector(
          onTap: () => onReactionTap(emoji),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: hasUserReacted
                  ? theme.colorScheme.primary.withOpacity(0.2)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: hasUserReacted
                  ? Border.all(color: theme.colorScheme.primary, width: 1)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                if (count > 1) ...[
                  const SizedBox(width: 2),
                  Text(
                    count.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      fontWeight: hasUserReacted ? FontWeight.bold : null,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
