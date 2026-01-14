import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veil_chat_application/widgets/Chat/chat_text.dart';
import 'package:veil_chat_application/widgets/Chat/chat_actions_bar.dart';
import 'package:veil_chat_application/models/message_model.dart';
import 'package:veil_chat_application/models/chat_room_model.dart';
import 'package:veil_chat_application/services/chat_service.dart';
import 'package:veil_chat_application/models/user_model.dart';

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
  
  // Streams
  StreamSubscription<List<Message>>? _messagesSubscription;
  StreamSubscription<ChatRoom?>? _chatRoomSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inputTextController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    _chatRoomSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _currentUserId != null) {
      // Mark messages as read when app comes to foreground
      _chatService.markMessagesAsRead(widget.chatId, _currentUserId!);
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
            // Mark messages as read
            if (_currentUserId != null) {
              _chatService.markMessagesAsRead(widget.chatId, _currentUserId!);
            }
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

      // Mark existing messages as read
      await _chatService.markMessagesAsRead(widget.chatId, _currentUserId!);

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

    try {
      await _chatService.sendMessage(
        chatRoomId: widget.chatId,
        senderId: _currentUserId!,
        receiverId: widget.otherUserId,
        text: text.trim(),
      );
      _inputTextController.clear();
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
      final becameFriends = await _chatService.toggleLike(widget.chatId, _currentUserId!);
      
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
    // TODO: Implement camera/image picker functionality
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Open camera
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Open gallery
              },
            ),
          ],
        ),
      ),
    );
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

  Widget _buildMessageItem(Message message) {
    final isSender = message.isSentByMe(_currentUserId ?? '');

    // System message
    if (message.type == MessageType.system) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.text ?? '',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.type == MessageType.image && message.imageUrl != null)
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    offset: const Offset(0, 4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  message.imageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 200,
                      height: 150,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 200,
                      height: 150,
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Icon(
                        Icons.broken_image,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    );
                  },
                ),
              ),
            )
          else
            ChatText(
              text: message.getDisplayText(),
              isSender: isSender,
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatMessageTime(message.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(128),
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
                        : Theme.of(context).textTheme.bodySmall?.color?.withAlpha(128),
                  ),
                ],
              ],
            ),
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
        title: Row(
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
                  if (_chatRoom != null && _chatRoom!.roomType == ChatRoomType.stranger)
                    Text(
                      _otherHasLiked ? '❤️ Liked you!' : 'Stranger',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: _otherHasLiked ? Colors.red : null,
                      ),
                    ),
                  if (_chatRoom != null && _chatRoom!.roomType == ChatRoomType.friend)
                    Text(
                      '✓ Friend',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: Colors.green,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Show expiry timer for stranger chats
          if (_chatRoom != null && 
              _chatRoom!.roomType == ChatRoomType.stranger && 
              _chatRoom!.expiresAt != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: StreamBuilder(
                stream: Stream.periodic(const Duration(minutes: 1)),
                builder: (context, snapshot) {
                  final timeLeft = _chatRoom!.expiresAt!.toDate().difference(DateTime.now());
                  if (timeLeft.isNegative) {
                    return Text('Expired', style: TextStyle(color: Colors.red, fontSize: 12));
                  }
                  final hours = timeLeft.inHours;
                  final minutes = timeLeft.inMinutes % 60;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_outlined, size: 16, color: hours < 6 ? Colors.orange : null),
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
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              // Handle menu actions
              switch (value) {
                case 'block':
                  _showBlockDialog();
                  break;
                case 'report':
                  _showReportDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, size: 20),
                    SizedBox(width: 8),
                    Text('Block User'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag, size: 20),
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
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Say hello! 👋',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
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
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            // Reverse index since ListView is reversed
                            final reversedIndex = _messages.length - 1 - index;
                            return _buildMessageItem(_messages[reversedIndex]);
                          },
                        ),
                ),
                // Input area
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: ChatActionsBar(
                    inputTextController: _inputTextController,
                    onSend: _handleSend,
                    onHeartPress: _handleHeartPress,
                    onCameraPress: _handleCameraPress,
                    hasLiked: _hasLiked,
                    isFriend: _chatRoom?.roomType == ChatRoomType.friend,
                  ),
                ),
              ],
            ),
    );
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: const Text('Are you sure you want to block this user? You will no longer be able to chat with them.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (_currentUserId != null) {
                await _chatService.blockUser(widget.chatId, _currentUserId!);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User blocked')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report User'),
        content: const Text('Report this user for inappropriate behavior?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report submitted. Thank you.')),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }
}
