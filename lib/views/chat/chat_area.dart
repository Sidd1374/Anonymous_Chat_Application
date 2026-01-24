import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:veil_chat_application/widgets/Chat/chat_text.dart';
import 'package:veil_chat_application/widgets/Chat/chat_actions_bar.dart';
import 'package:veil_chat_application/widgets/Chat/chat_image_message.dart';
import 'package:veil_chat_application/widgets/Chat/reaction_picker.dart';
import 'package:veil_chat_application/models/message_model.dart';
import 'package:veil_chat_application/models/chat_room_model.dart';
import 'package:veil_chat_application/services/chat_service.dart';
import 'package:veil_chat_application/services/presence_service.dart';
import 'package:veil_chat_application/services/cloudinary_service.dart';
import 'package:veil_chat_application/models/user_model.dart';
import 'package:veil_chat_application/views/profile/profile_page.dart';

class ChatArea extends StatefulWidget {
  final String userName;
  final String userImage;
  final String chatId;
  final String otherUserId;

  const ChatArea({
    super.key,
    required this.userName,
    required this.userImage,
    required this.chatId,
    required this.otherUserId,
  });

  @override
  State<ChatArea> createState() => _ChatAreaState();
}

class _ChatAreaState extends State<ChatArea> with WidgetsBindingObserver {
  final TextEditingController _inputTextController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final PresenceService _presenceService = PresenceService();
  final ImagePicker _imagePicker = ImagePicker();

  // Current user info
  String? _currentUserId;
  User? _currentUser;

  // Chat state
  List<Message> _messages = [];
  ChatRoom? _chatRoom;
  bool _isLoading = true;
  bool _hasLiked = false;
  bool _otherHasLiked = false;
  bool _isSending = false;

  // Presence state
  bool _isOtherUserOnline = false;
  bool _isOtherUserTyping = false;
  String _lastSeenText = '';

  // Reaction picker state
  String? _showReactionPickerForMessageId;

  // Reply state
  Message? _replyToMessage;

  // Streams
  StreamSubscription<List<Message>>? _messagesSubscription;
  StreamSubscription<ChatRoom?>? _chatRoomSubscription;
  StreamSubscription<UserPresence>? _presenceSubscription;
  StreamSubscription<Map<String, bool>>? _typingSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Clear typing status when leaving chat
    if (_currentUserId != null) {
      _presenceService.clearTyping(widget.chatId, _currentUserId!);
    }
    _inputTextController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    _chatRoomSubscription?.cancel();
    _presenceSubscription?.cancel();
    _typingSubscription?.cancel();
    _presenceService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _currentUserId != null) {
      // Mark messages as read when app comes to foreground (respecting privacy settings)
      final hideReadReceipts =
          _currentUser?.privacySettings?.hideReadReceipts ?? false;
      _chatService.markMessagesAsRead(
        widget.chatId,
        _currentUserId!,
        hideReadReceipts: hideReadReceipts,
      );
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Called when keyboard shows/hides. Scroll to bottom when keyboard opens.
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    if (bottomInset > 0) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _scrollToBottom();
      });
    }
  }

  Future<void> _initializeChat() async {
    try {
      // Get current user
      _currentUser = await User.getFromPrefs();
      if (_currentUser == null) {
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      }
      _currentUserId = _currentUser!.uid;

      // Set current user as online
      _presenceService.setOnlineStatus(_currentUserId!, true);

      // Subscribe to other user's presence (online/last seen)
      _presenceSubscription =
          _presenceService.streamUserPresence(widget.otherUserId).listen(
        (presence) {
          if (mounted) {
            setState(() {
              _isOtherUserOnline = presence.isOnline;
              _lastSeenText = presence.formatLastSeen();
            });
          }
        },
        onError: (error) {
          print('Error streaming presence: $error');
        },
      );

      // Subscribe to typing status in this chat
      _typingSubscription =
          _presenceService.streamTypingStatus(widget.chatId).listen(
        (typingMap) {
          if (mounted) {
            setState(() {
              _isOtherUserTyping = typingMap[widget.otherUserId] ?? false;
            });
          }
        },
        onError: (error) {
          print('Error streaming typing status: $error');
        },
      );

      // Subscribe to chat room updates
      _chatRoomSubscription = _chatService.streamChatRoom(widget.chatId).listen(
        (chatRoom) {
          if (mounted) {
            setState(() {
              _chatRoom = chatRoom;
              if (chatRoom != null && _currentUserId != null) {
                _hasLiked = chatRoom.hasCurrentUserLiked(_currentUserId!);
                _otherHasLiked = chatRoom.hasOtherUserLiked(_currentUserId!);
              }
            });
          }
        },
        onError: (error) {
          print('Error streaming chat room: $error');
        },
      );

      // Subscribe to messages
      _messagesSubscription = _chatService.streamMessages(widget.chatId).listen(
        (messages) {
          if (mounted) {
            setState(() {
              _messages = messages;
              _isLoading = false;
            });
            // Scroll to bottom when new message arrives
            _scrollToBottom();
          }
        },
        onError: (error) {
          print('Error streaming messages: $error');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
      );

      // Mark existing messages as read (respecting privacy settings)
      final hideReadReceipts =
          _currentUser?.privacySettings?.hideReadReceipts ?? false;
      await _chatService.markMessagesAsRead(
        widget.chatId,
        _currentUserId!,
        hideReadReceipts: hideReadReceipts,
      );
    } catch (e) {
      print('Error initializing chat: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    // With reverse: true, position 0 is the bottom (latest messages)
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSend(String text) async {
    if (text.trim().isEmpty || _currentUserId == null || _isSending) return;

    setState(() {
      _isSending = true;
    });

    // Clear typing status when sending
    _presenceService.clearTyping(widget.chatId, _currentUserId!);

    try {
      await _chatService.sendMessage(
        chatRoomId: widget.chatId,
        senderId: _currentUserId!,
        receiverId: widget.otherUserId,
        text: text.trim(),
        replyToMessage: _replyToMessage,
      );
      _inputTextController.clear();
      // Clear reply state after sending
      if (_replyToMessage != null) {
        setState(() {
          _replyToMessage = null;
        });
      }
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _handleHeartPress() async {
    if (_currentUserId == null) return;

    try {
      final becameFriends =
          await _chatService.toggleLike(widget.chatId, _currentUserId!);

      if (becameFriends && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.favorite, color: Colors.white),
                SizedBox(width: 8),
                Text('🎉 You are now friends!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  void _handleCameraPress() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMediaPickerSheet(),
    );
  }

  Widget _buildMediaPickerSheet() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Text(
              'Share Media',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            // Options Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMediaOption(
                    context: context,
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _buildMediaOption(
                    context: context,
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    isPrimary: false,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Cancel button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: theme.colorScheme.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = true,
  }) {
    final theme = Theme.of(context);
    final color =
        isPrimary ? theme.colorScheme.primary : theme.colorScheme.secondary;
    final iconColor = isPrimary
        ? theme.colorScheme.primary
        : theme.textTheme.bodyLarge?.color;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(isPrimary ? 0.15 : 1.0),
              shape: BoxShape.circle,
              border: isPrimary
                  ? null
                  : Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      width: 2,
                    ),
            ),
            child: Icon(
              icon,
              size: 30,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Show preview dialog
      if (mounted) {
        _showImagePreview(File(pickedFile.path));
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImagePreview(File imageFile) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Image.file(
                  imageFile,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cancel button
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text('Cancel',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Send button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _uploadAndSendImage(imageFile);
                  },
                  icon: const Icon(Icons.send, color: Colors.white),
                  label:
                      const Text('Send', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade400,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadAndSendImage(File imageFile) async {
    if (_currentUserId == null) return;

    final theme = Theme.of(context);

    // Show loading indicator with theme colors
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Sending image...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      print('=== UPLOADING IMAGE TO CLOUDINARY ===');
      print('Chat ID: ${widget.chatId}');
      print('Current User: $_currentUserId');
      print('File path: ${imageFile.path}');
      print('File exists: ${await imageFile.exists()}');
      print('File size: ${await imageFile.length()} bytes');

      // Upload image to Cloudinary
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final publicId = 'chat_${widget.chatId}_$timestamp';

      final uploadResult = await cloudinary.uploadFileUnsigned(
        filePath: imageFile.path,
        folder: 'ChatImages/${widget.chatId}',
        publicId: publicId,
      );

      print('Upload complete!');
      print('Image URL: ${uploadResult.secureUrl}');
      print('Public ID: ${uploadResult.publicId}');

      // Send image message with Cloudinary URL
      await _chatService.sendImageMessage(
        chatRoomId: widget.chatId,
        senderId: _currentUserId!,
        receiverId: widget.otherUserId,
        imageUrl: uploadResult.secureUrl,
        metadata: {
          'publicId': uploadResult.publicId,
          'bytes': uploadResult.bytes,
          'format': uploadResult.format,
        },
        replyToMessage: _replyToMessage,
      );
      print('Image message sent!');

      // Clear reply state after sending
      if (_replyToMessage != null) {
        setState(() {
          _replyToMessage = null;
        });
      }

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: theme.colorScheme.onPrimary),
                const SizedBox(width: 8),
                const Text('Image sent!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('Error uploading image: $e');
      print('Stack trace: $stackTrace');
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        String errorMessage = 'Failed to send image.';
        if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your connection.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: theme.colorScheme.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _uploadAndSendImage(imageFile),
            ),
          ),
        );
      }
    }
  }

  String _formatMessageTime(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Handle image pasted from keyboard (GIFs, copied images)
  Future<void> _handleImagePaste(Uint8List imageBytes) async {
    if (_currentUserId == null) return;

    // Create a temporary file from the bytes
    final tempDir = await Directory.systemTemp.createTemp('pasted_image');
    final tempFile = File(
        '${tempDir.path}/pasted_image_${DateTime.now().millisecondsSinceEpoch}.png');
    await tempFile.writeAsBytes(imageBytes);

    // Show preview dialog
    if (mounted) {
      _showImagePreview(tempFile);
    }
  }

  /// Handle typing detection - call this when text input changes
  void _handleTyping(String text) {
    if (_currentUserId == null) return;

    if (text.isNotEmpty) {
      _presenceService.setTypingStatus(widget.chatId, _currentUserId!, true);
    } else {
      _presenceService.setTypingStatus(widget.chatId, _currentUserId!, false);
    }
  }

  /// Handle reaction tap on a message
  Future<void> _handleReactionTap(Message message, String emoji) async {
    if (_currentUserId == null) return;

    // Close the reaction picker
    setState(() {
      _showReactionPickerForMessageId = null;
    });

    // Toggle the reaction
    await _chatService.toggleReaction(
      chatRoomId: widget.chatId,
      messageId: message.messageId,
      userId: _currentUserId!,
      emoji: emoji,
    );
  }

  /// Show reaction picker for a message
  void _showReactionPicker(Message message) {
    setState(() {
      // Toggle: if already showing for this message, hide it
      if (_showReactionPickerForMessageId == message.messageId) {
        _showReactionPickerForMessageId = null;
      } else {
        _showReactionPickerForMessageId = message.messageId;
      }
    });
  }

  Widget _buildMessageItem(Message message) {
    final isSender = message.isSentByMe(_currentUserId ?? '');
    final theme = Theme.of(context);

    // System message
    if (message.type == MessageType.system) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.text ?? '',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    // Get reply sender name
    String? replySenderName;
    bool isReplyToMe = false;
    if (message.replyToSenderId != null) {
      isReplyToMe = message.replyToSenderId == _currentUserId;
      replySenderName = isReplyToMe ? 'You' : widget.userName;
    }

    // Build reply preview widget if this message is a reply
    Widget? replyPreview;
    if (message.replyToMessageId != null && message.replyToText != null) {
      replyPreview = GestureDetector(
        onTap: () => _scrollToMessage(message.replyToMessageId!),
        child: Container(
          margin: EdgeInsets.only(bottom: 4),
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.5),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isReplyToMe ? 'You' : (replySenderName ?? 'User'),
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
                  if (message.replyToType == MessageType.image)
                    Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.image,
                        size: 14,
                        color:
                            theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  Flexible(
                    child: Text(
                      message.replyToText ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.textTheme.bodySmall?.color?.withOpacity(0.7),
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
      );
    }

    // Main message content
    Widget messageContent = Column(
      crossAxisAlignment:
          isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Show reply preview above image messages
        if (message.type == MessageType.image && replyPreview != null)
          replyPreview,
        if (message.type == MessageType.image &&
            message.imageUrl != null &&
            !message.isDeleted)
          ChatImageMessage(
            imageUrl: message.imageUrl!,
            isSender: isSender,
            messageId: message.messageId,
          )
        else
          ChatText(
            text: message.getDisplayText(),
            isSender: isSender,
            isDeleted: message.isDeleted,
            replyToText: message.replyToText,
            replyToSenderName: replySenderName,
            isReplyToMe: isReplyToMe,
            replyToType: message.replyToType,
            onReplyTap: message.replyToMessageId != null
                ? () => _scrollToMessage(message.replyToMessageId!)
                : null,
          ),
        // Display reactions if any
        if (message.reactions != null && message.reactions!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: MessageReactions(
              reactions: message.reactions,
              currentUserId: _currentUserId ?? '',
              onReactionTap: (emoji) => _handleReactionTap(message, emoji),
            ),
          ),
        // Show reaction picker if active for this message
        if (_showReactionPickerForMessageId == message.messageId)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: ReactionPicker(
              currentUserReaction:
                  message.getUserReaction(_currentUserId ?? ''),
              onReactionSelected: (emoji) => _handleReactionTap(message, emoji),
              onClose: () =>
                  setState(() => _showReactionPickerForMessageId = null),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatMessageTime(message.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: theme.textTheme.bodySmall?.color?.withAlpha(128),
                ),
              ),
              if (isSender) ...[
                const SizedBox(width: 4),
                Icon(
                  message.status == MessageStatus.read
                      ? Icons.done_all
                      : message.status == MessageStatus.sent
                          ? Icons.done
                          : Icons.access_time,
                  size: 14,
                  color: message.status == MessageStatus.read
                      ? Colors.blue
                      : theme.textTheme.bodySmall?.color?.withAlpha(128),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    // Wrap with swipe-to-reply (only if not deleted)
    if (!message.isDeleted) {
      messageContent = Dismissible(
        key: Key(message.messageId),
        direction: isSender
            ? DismissDirection.endToStart
            : DismissDirection.startToEnd,
        confirmDismiss: (direction) async {
          // Set reply state and return false to prevent actual dismissal
          setState(() {
            _replyToMessage = message;
          });
          return false;
        },
        background: Container(
          alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Icon(
            Icons.reply,
            color: theme.colorScheme.primary,
          ),
        ),
        child: GestureDetector(
          onLongPress: () => _showMessageOptions(message),
          onDoubleTap: () => _showReactionPicker(message),
          child: messageContent,
        ),
      );
    }

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: messageContent,
    );
  }

  void _scrollToMessage(String messageId) {
    final index = _messages.indexWhere((m) => m.messageId == messageId);
    if (index != -1) {
      // Calculate reversed index since ListView is reversed
      final reversedIndex = _messages.length - 1 - index;
      _scrollController.animateTo(
        reversedIndex * 80.0, // Approximate message height
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showMessageOptions(Message message) {
    final theme = Theme.of(context);
    final isSender = message.isSentByMe(_currentUserId ?? '');
    final canDeleteInfo =
        _chatService.canDeleteMessage(message, _currentUserId ?? '');
    final canDelete = canDeleteInfo['canDelete'] as bool;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              // Reply option
              ListTile(
                leading: Icon(Icons.reply, color: theme.colorScheme.primary),
                title: Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _replyToMessage = message;
                  });
                },
              ),
              // Delete option (only for sender's own messages)
              if (isSender)
                ListTile(
                  leading: Icon(
                    Icons.delete,
                    color: canDelete ? Colors.red : Colors.grey,
                  ),
                  title: Text('Delete'),
                  subtitle: canDelete
                      ? Text(
                          '${canDeleteInfo['minutesLeft']} min left to delete')
                      : Text(canDeleteInfo['reason'] ?? 'Cannot delete'),
                  enabled: canDelete,
                  onTap: canDelete
                      ? () {
                          Navigator.pop(context);
                          _confirmDeleteMessage(message);
                        }
                      : null,
                ),
              SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteMessage(Message message) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Message?'),
        content: Text('This message will be deleted for everyone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await _chatService.deleteMessage(
                chatRoomId: widget.chatId,
                messageId: message.messageId,
                currentUserId: _currentUserId!,
              );
              if (mounted) {
                if (result == 'success') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Message deleted'),
                      backgroundColor: theme.colorScheme.primary,
                    ),
                  );
                } else if (result == 'time_expired') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cannot delete: 15 minute limit exceeded'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserName = widget.userName;
    final String currentUserImage = widget.userImage;

    return WillPopScope(
      onWillPop: () async {
        // If keyboard is open, dismiss it instead of popping the route
        final currentFocus = FocusScope.of(context);
        if (MediaQuery.of(context).viewInsets.bottom > 0) {
          currentFocus.unfocus();
          return false;
        }
        if (currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
          currentFocus.unfocus();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: InkWell(
            onTap: () {
              // Only allow friends to view each other's profiles
              if (_chatRoom?.roomType == ChatRoomType.friend) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(
                      isViewingOther: true,
                      otherUserId: widget.otherUserId,
                    ),
                  ),
                );
              } else {
                // Strangers cannot view profiles - show a message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Become friends to view their profile'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: currentUserImage.startsWith('http')
                        ? NetworkImage(currentUserImage) as ImageProvider
                        : AssetImage(currentUserImage),
                    radius: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUserName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        // Dynamic status: Typing > Online > Last Seen > Room type info
                        Text(
                          _isOtherUserTyping
                              ? 'Typing...'
                              : (_isOtherUserOnline
                                  ? '● Online'
                                  : (_lastSeenText.isNotEmpty
                                      ? 'Last seen $_lastSeenText'
                                      : (_chatRoom != null &&
                                              _chatRoom!.roomType ==
                                                  ChatRoomType.stranger
                                          ? (_otherHasLiked
                                              ? '❤️ Liked you!'
                                              : '👤 Stranger')
                                          : '✓ Friend'))),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                fontSize: 11,
                                color: _isOtherUserTyping
                                    ? Theme.of(context).colorScheme.primary
                                    : (_isOtherUserOnline
                                        ? Colors.green
                                        : (_otherHasLiked
                                            ? Colors.red
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.6))),
                                fontWeight:
                                    _isOtherUserTyping ? FontWeight.w500 : null,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            // Show expiry timer for stranger chats OR infinity for friends
            if (_chatRoom != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _chatRoom!.roomType == ChatRoomType.friend
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.all_inclusive,
                              size: 18, color: Colors.green),
                          Text(
                            'Forever',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      )
                    : (_chatRoom!.expiresAt != null
                        ? StreamBuilder(
                            stream: Stream.periodic(const Duration(minutes: 1)),
                            builder: (context, snapshot) {
                              final timeLeft = _chatRoom!.expiresAt!
                                  .toDate()
                                  .difference(DateTime.now());
                              if (timeLeft.isNegative) {
                                return Text('Expired',
                                    style: TextStyle(
                                        color: Colors.red, fontSize: 12));
                              }
                              final hours = timeLeft.inHours;
                              final minutes = timeLeft.inMinutes % 60;
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.timer_outlined,
                                      size: 16,
                                      color: hours < 6 ? Colors.orange : null),
                                  Text(
                                    '${hours}h ${minutes}m',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: hours < 6 ? Colors.orange : null,
                                    ),
                                  ),
                                ],
                              );
                            },
                          )
                        : const SizedBox()),
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                // Handle menu actions
                switch (value) {
                  case 'unfriend':
                    _showUnfriendDialog();
                    break;
                  case 'block':
                    _showBlockDialog();
                    break;
                  case 'report':
                    _showReportDialog();
                    break;
                }
              },
              itemBuilder: (context) => [
                // Show unfriend option only for friends
                if (_chatRoom?.roomType == ChatRoomType.friend)
                  PopupMenuItem(
                    value: 'unfriend',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove,
                            size: 20, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Unfriend'),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(Icons.block, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Block User'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.flag, size: 20, color: Colors.amber),
                      SizedBox(width: 8),
                      Text('Report'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Chat messages
                  Expanded(
                    child: _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No messages yet',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Say hello! 👋',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline,
                                      ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: _scrollController,
                            reverse: true, // Start from bottom
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              // Reverse index since ListView is reversed
                              final reversedIndex =
                                  _messages.length - 1 - index;
                              return _buildMessageItem(
                                  _messages[reversedIndex]);
                            },
                          ),
                  ),
                  // Reply bar (shown when replying to a message)
                  if (_replyToMessage != null) _buildReplyBar(),
                  // Input area
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: ChatActionsBar(
                      inputTextController: _inputTextController,
                      onSend: _handleSend,
                      onHeartPress: _handleHeartPress,
                      onCameraPress: _handleCameraPress,
                      onImagePaste: _handleImagePaste,
                      onTextChanged: _handleTyping,
                      hasLiked: _hasLiked,
                      isFriend: _chatRoom?.roomType == ChatRoomType.friend,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildReplyBar() {
    final theme = Theme.of(context);
    final isReplyToMe = _replyToMessage?.senderId == _currentUserId;
    final senderName = isReplyToMe ? 'yourself' : widget.userName;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.primary,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to $senderName',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    if (_replyToMessage?.type == MessageType.image)
                      Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.image,
                          size: 14,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    Flexible(
                      child: Text(
                        _replyToMessage?.type == MessageType.image
                            ? 'Photo'
                            : (_replyToMessage?.text ?? ''),
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 20),
            onPressed: () {
              setState(() {
                _replyToMessage = null;
              });
            },
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _showUnfriendDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person_remove, color: Colors.orange),
            SizedBox(width: 8),
            Text('Unfriend ${widget.userName}?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to unfriend this user?',
              style: theme.textTheme.bodyLarge,
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⚠️ This will:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('• Remove them from your friends list'),
                  Text('• Move chat back to History'),
                  Text('• Start a new 48-hour timer'),
                  Text('• Reset both like statuses'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (_currentUserId != null) {
                await _chatService.unfriendUser(widget.chatId, _currentUserId!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${widget.userName} has been unfriended'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Unfriend', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.block, color: Colors.red),
            SizedBox(width: 8),
            Text('Block ${widget.userName}?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to block this user?',
              style: theme.textTheme.bodyLarge,
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🚫 This will:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('• Stop all messages from this user'),
                  Text('• Add them to your blocked list'),
                  Text('• You can unblock them later in Settings'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (_currentUserId != null) {
                await _chatService.blockUser(widget.chatId, _currentUserId!);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${widget.userName} has been blocked'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Block', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    final theme = Theme.of(context);
    String? selectedReason;
    final TextEditingController detailsController = TextEditingController();

    final reasons = [
      'Inappropriate content',
      'Harassment or bullying',
      'Spam or scam',
      'Fake profile',
      'Underage user',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.flag, color: Colors.amber),
              SizedBox(width: 8),
              Text('Report ${widget.userName}'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why are you reporting this user?',
                  style: theme.textTheme.bodyLarge,
                ),
                SizedBox(height: 12),
                ...reasons.map((reason) => RadioListTile<String>(
                      title: Text(reason, style: TextStyle(fontSize: 14)),
                      value: reason,
                      groupValue: selectedReason,
                      dense: true,
                      onChanged: (value) {
                        setDialogState(() {
                          selectedReason = value;
                        });
                      },
                    )),
                SizedBox(height: 12),
                TextField(
                  controller: detailsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Additional details (optional)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () async {
                      Navigator.pop(context);
                      if (_currentUserId != null) {
                        await _chatService.reportUser(
                          chatRoomId: widget.chatId,
                          reporterId: _currentUserId!,
                          reportedUserId: widget.otherUserId,
                          reason: selectedReason!,
                          details: detailsController.text.isNotEmpty
                              ? detailsController.text
                              : null,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Report submitted. Thank you.'),
                                ],
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              child:
                  Text('Submit Report', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}
