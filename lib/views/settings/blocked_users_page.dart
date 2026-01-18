import 'package:flutter/material.dart';
import 'package:veil_chat_application/models/user_model.dart';
import 'package:veil_chat_application/services/chat_service.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  final ChatService _chatService = ChatService();
  
  List<Map<String, dynamic>> _blockedUsers = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    try {
      final user = await User.getFromPrefs();
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      _currentUserId = user.uid;
      
      final blockedUsers = await _chatService.getBlockedUsers(user.uid);
      
      if (mounted) {
        setState(() {
          _blockedUsers = blockedUsers;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading blocked users: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _unblockUser(Map<String, dynamic> blockedUser) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unblock ${blockedUser['name']}?'),
        content: Text('This user will be able to send you messages again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Unblock', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirmed == true && _currentUserId != null) {
      try {
        await _chatService.unblockUser(
          blockedUser['chatRoomId'] as String,
          _currentUserId!,
          blockedUser['userId'] as String,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${blockedUser['name']} has been unblocked'),
              backgroundColor: Colors.green,
            ),
          );
          // Reload the list
          await _loadBlockedUsers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to unblock user'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Blocked Users'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _blockedUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.block,
                        size: 64,
                        color: theme.colorScheme.outline,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No blocked users',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Users you block will appear here',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadBlockedUsers,
                  child: ListView.separated(
                    padding: EdgeInsets.all(16),
                    itemCount: _blockedUsers.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final blocked = _blockedUsers[index];
                      final name = blocked['name'] ?? 'Unknown User';
                      final profilePic = blocked['profilePicUrl'];
                      final blockedAt = blocked['blockedAt'];
                      
                      String blockedDateStr = '';
                      if (blockedAt != null) {
                        final date = blockedAt.toDate();
                        blockedDateStr = '${date.day}/${date.month}/${date.year}';
                      }
                      
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundImage: profilePic != null
                                ? NetworkImage(profilePic)
                                : AssetImage('assets/Profile_image.png') as ImageProvider,
                          ),
                          title: Text(
                            name,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: blockedDateStr.isNotEmpty
                              ? Text(
                                  'Blocked on $blockedDateStr',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                )
                              : null,
                          trailing: ElevatedButton(
                            onPressed: () => _unblockUser(blocked),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: Text(
                              'Unblock',
                              style: TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
