// import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:veil_chat_application/models/user_model.dart' as mymodel;
import 'package:veil_chat_application/core/app_theme.dart';
import 'package:veil_chat_application/services/firestore_service.dart';
import 'package:veil_chat_application/services/chat_service.dart';
import 'package:veil_chat_application/views/settings/blocked_users_page.dart';
import 'profile.dart';
import 'package:veil_chat_application/widgets/docs_dialogs.dart' as dia;
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatefulWidget {
  final mymodel.User? preloadedUser;
  final ImageProvider? preloadedImageProvider;

  const SettingsPage({
    Key? key,
    this.preloadedUser,
    this.preloadedImageProvider,
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  mymodel.User? _user;
  mymodel.User? _savedSnapshot; // last saved state (prefs/remote)
  final FirestoreService _firestoreService = FirestoreService();
  final ChatService _chatService = ChatService();
  int _blockedUsersCount = 0;
  
  // Age range values
  RangeValues _ageRange = const RangeValues(18, 60);
  static const double _minAgeLimit = 18;
  static const double _maxAgeLimit = 60;

  bool _isLoading = true; // track initial data loading
  bool _pendingChange = false; // track whether settings differ from snapshot
  ImageProvider? _profileImageProvider; // cached image provider

  bool _chatWithOppositeGender = false;
  bool _showProfilePhotoToStrangers = false;
  bool _showProfilePhotoToFriends = false;
  bool _chatOnlyWithVerifiedUsers = false;
  bool _hideReadReceipts = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    if (_pendingChange && _user != null) {
      _savePreferencesRemote(_user!);
    }
    super.dispose();
  }

  Future<void> _loadUserData() async {
    // Check if preloaded data was passed from HomePageFrame
    if (widget.preloadedUser != null) {
      debugPrint('[Settings] Using preloaded user data (no loading needed)');
      if (mounted) {
        setState(() {
          _user = widget.preloadedUser;
          _savedSnapshot = widget.preloadedUser;
          _pendingChange = false;
          _isLoading = false;
          _profileImageProvider = widget.preloadedImageProvider;
          _updateControllersFromUser();
        });
      }
      return;
    }

    // Fallback: Load from SharedPreferences if no preloaded data
    final user = await mymodel.User.getFromPrefs();
    if (user != null) {
      debugPrint('[Settings] Loaded user from SharedPreferences (fallback)');
      
      ImageProvider? imageProvider;
      if (user.profilePicUrl != null && user.profilePicUrl!.isNotEmpty) {
        try {
          final file = await DefaultCacheManager().getSingleFile(user.profilePicUrl!);
          imageProvider = FileImage(file);
        } catch (e) {
          debugPrint('[Settings] Cache error: $e');
          imageProvider = CachedNetworkImageProvider(user.profilePicUrl!);
        }
      }
      
      if (mounted) {
        setState(() {
          _user = user;
          _savedSnapshot = user;
          _pendingChange = false;
          _isLoading = false;
          _profileImageProvider = imageProvider;
          _updateControllersFromUser();
        });
      }
    } else {
      debugPrint('[Settings] No cached user available');
      if (mounted) {
        setState(() {
          _user = null;
          _isLoading = false;
        });
      }
    }
  }

  void _updateControllersFromUser() {
    if (_user != null) {
      // Update chat preferences
      if (_user!.chatPreferences != null) {
        _chatWithOppositeGender = _user!.chatPreferences!.matchWithGender != null;
        _chatOnlyWithVerifiedUsers = _user!.chatPreferences!.onlyVerified ?? false;
        
        final minAge = _user!.chatPreferences!.minAge?.toDouble() ?? _minAgeLimit;
        final maxAge = _user!.chatPreferences!.maxAge?.toDouble() ?? _maxAgeLimit;
        _ageRange = RangeValues(
          minAge.clamp(_minAgeLimit, _maxAgeLimit),
          maxAge.clamp(_minAgeLimit, _maxAgeLimit),
        );
      }
      
      // Update privacy settings
      if (_user!.privacySettings != null) {
        _showProfilePhotoToFriends = _user!.privacySettings!.showProfilePicToFriends ?? false;
        _showProfilePhotoToStrangers = _user!.privacySettings!.showProfilePicToStrangers ?? false;
        _hideReadReceipts = _user!.privacySettings!.hideReadReceipts ?? false;
      }
      
      // Load blocked users count
      _loadBlockedUsersCount();
    }
  }

  Future<void> _loadBlockedUsersCount() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;
    
    try {
      final blockedUsers = await _chatService.getBlockedUsers(firebaseUser.uid);
      if (mounted) {
        setState(() {
          _blockedUsersCount = blockedUsers.length;
        });
      }
    } catch (e) {
      debugPrint('[Settings] Error loading blocked users count: $e');
    }
  }

  Future<void> _saveLocalPreferences() async {
    if (_user == null) return;
    final updatedUser = _buildUpdatedUser(_user!);
    final baseline = _savedSnapshot ?? _user!;

    final changed = _settingsChanged(updatedUser, baseline);

    setState(() {
      _user = updatedUser;
      _pendingChange = changed;
    });

    if (changed) {
      await mymodel.User.saveToPrefs(updatedUser);
    }
  }

  Future<void> _savePreferencesRemote(mymodel.User user) async {
    try {
      debugPrint('[Settings] Saving preferences to Firestore for ${user.uid}');
      await _firestoreService.updateUser(user.uid, _buildUpdatedFirestoreMap());
    } catch (_) {
      // silently ignore on exit; can add logging if needed
    }
  }

  mymodel.User _buildUpdatedUser(mymodel.User base) {
    final minAge = _ageRange.start.round();
    final maxAge = _ageRange.end.round();

    return mymodel.User(
      uid: base.uid,
      email: base.email,
      fullName: base.fullName,
      createdAt: base.createdAt,
      profilePicUrl: base.profilePicUrl,
      gender: base.gender,
      age: base.age,
      interests: base.interests,
      verificationLevel: base.verificationLevel,
      chatPreferences: mymodel.ChatPreferences(
        matchWithGender:
            _chatWithOppositeGender ? (base.gender == 'Male' ? 'Female' : 'Male') : null,
        minAge: minAge,
        maxAge: maxAge,
        onlyVerified: _chatOnlyWithVerifiedUsers,
      ),
      privacySettings: mymodel.PrivacySettings(
        showProfilePicToFriends: _showProfilePhotoToFriends,
        showProfilePicToStrangers: _showProfilePhotoToStrangers,
        hideReadReceipts: _hideReadReceipts,
      ),
    );
  }

  Map<String, dynamic> _buildUpdatedFirestoreMap() {
    final minAge = _ageRange.start.round();
    final maxAge = _ageRange.end.round();

    return {
      'chatPreferences': {
        'matchWithGender': _chatWithOppositeGender
            ? (_user?.gender == 'Male' ? 'Female' : 'Male')
            : null,
        'minAge': minAge,
        'maxAge': maxAge,
        'onlyVerified': _chatOnlyWithVerifiedUsers,
      },
      'privacySettings': {
        'showProfilePicToFriends': _showProfilePhotoToFriends,
        'showProfilePicToStrangers': _showProfilePhotoToStrangers,
        'hideReadReceipts': _hideReadReceipts,
      },
    };
  }

  bool _settingsChanged(mymodel.User a, mymodel.User b) {
    final ap = a.chatPreferences;
    final bp = b.chatPreferences;
    final apr = a.privacySettings;
    final bpr = b.privacySettings;

    bool chatDiff = (ap?.matchWithGender ?? '') != (bp?.matchWithGender ?? '') ||
        (ap?.minAge ?? -1) != (bp?.minAge ?? -1) ||
        (ap?.maxAge ?? -1) != (bp?.maxAge ?? -1) ||
        (ap?.onlyVerified ?? false) != (bp?.onlyVerified ?? false);

    bool privacyDiff = (apr?.showProfilePicToFriends ?? false) !=
            (bpr?.showProfilePicToFriends ?? false) ||
        (apr?.showProfilePicToStrangers ?? false) !=
            (bpr?.showProfilePicToStrangers ?? false) ||
        (apr?.hideReadReceipts ?? false) !=
            (bpr?.hideReadReceipts ?? false);

    return chatDiff || privacyDiff;
  }

  Future<void> _refreshUserData() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      debugPrint('[Settings] Manual refresh from Firestore for ${firebaseUser.uid}');
      final userDoc = await _firestoreService.getUser(firebaseUser.uid);
      if (userDoc.exists) {
        final user = mymodel.User.fromJson(userDoc.data()!);
        await mymodel.User.saveToPrefs(user);
        
        // Refresh image from cache
        ImageProvider? newImageProvider;
        if (user.profilePicUrl != null && user.profilePicUrl!.isNotEmpty) {
          try {
            // Force re-download to get latest
            await DefaultCacheManager().removeFile(user.profilePicUrl!);
            final file = await DefaultCacheManager().downloadFile(user.profilePicUrl!);
            newImageProvider = FileImage(file.file);
          } catch (e) {
            debugPrint('[Settings] Refresh cache error: $e');
            newImageProvider = CachedNetworkImageProvider(user.profilePicUrl!);
          }
        }
        
        if (mounted) {
          setState(() {
            _user = user;
            _savedSnapshot = user;
            _pendingChange = false;
            _profileImageProvider = newImageProvider;
            _updateControllersFromUser();
          });
        }
      }
    }
  }

  bool get _isLevel2Verified => (_user?.verificationLevel ?? 0) >= 2;
  bool get _isLevel1Verified => (_user?.verificationLevel ?? 0) >= 1;

  Widget _buildLevel1Setting({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final isEnabled = _isLevel1Verified;
    
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: SwitchListTile(
        title: Row(
          children: [
            Expanded(child: Text(title)),
            if (!isEnabled)
              Icon(
                Icons.lock,
                size: 16,
                color: theme.colorScheme.outline,
              ),
          ],
        ),
        subtitle: Text(subtitle),
        value: isEnabled ? value : false,
        activeColor: theme.primaryColor,
        inactiveTrackColor: theme.colorScheme.secondary,
        onChanged: isEnabled
            ? onChanged
            : (bool _) {
                _showLevel1RequiredDialog(context);
              },
      ),
    );
  }

  Widget _buildLevel2Setting({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final isEnabled = _isLevel2Verified;
    
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: SwitchListTile(
        title: Row(
          children: [
            Expanded(child: Text(title)),
            if (!isEnabled)
              Icon(
                Icons.lock,
                size: 16,
                color: theme.colorScheme.outline,
              ),
          ],
        ),
        subtitle: Text(subtitle),
        value: isEnabled ? value : false,
        activeColor: theme.primaryColor,
        inactiveTrackColor: theme.colorScheme.secondary,
        onChanged: isEnabled
            ? onChanged
            : (bool _) {
                _showLevel2RequiredDialog(context);
              },
      ),
    );
  }

  void _showLevel1RequiredDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.verified, color: theme.colorScheme.primary),
            SizedBox(width: 8),
            Text('Verification Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This setting requires Level 1 verification.',
              style: theme.textTheme.bodyLarge,
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Complete basic verification to unlock this setting.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLevel2RequiredDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.verified_user, color: theme.colorScheme.primary),
            SizedBox(width: 8),
            Text('Verification Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This setting requires Level 2 verification.',
              style: theme.textTheme.bodyLarge,
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please verify to Level 2 to use these settings.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(ThemeData theme) {
    return GestureDetector(
      onTap: () {
        if (_user != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileLvl1(
                user: _user!,
                preloadedImageProvider: _profileImageProvider,
              ),
            ),
          ).then((_) => _refreshUserData()); // Refresh data on return
        }
      },
      child: Card(
        elevation: 4,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        color: theme.colorScheme.secondary,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(width: 2, color: theme.primaryColor),
                  color: theme.colorScheme.secondary,
                ),
                child: _profileImageProvider != null
                    ? ClipOval(
                        child: Image(
                          image: _profileImageProvider!,
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person,
                            size: 50,
                            color: theme.hintColor,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 50,
                        color: theme.hintColor,
                      ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _user?.fullName ?? 'User Name',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 18.h,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _user?.gender ?? 'Gender not set',
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _user?.age ?? 'Age not set',
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: Icon(
              appTheme.currentTheme == AppTheme.lightTheme
                  ? Icons.dark_mode
                  : Icons.light_mode,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: appTheme.toggleTheme,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(Theme.of(context)),
                const SizedBox(height: 30.0),
                Text(
                  'Chat Preferences',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.h,
                      ),
                ),
                const SizedBox(height: 16.0),
                
                // Age Range Setting
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Age range',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${_ageRange.start.round()} - ${_ageRange.end.round()}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Only match with users in this age range',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          rangeThumbShape: const RoundRangeSliderThumbShape(
                            enabledThumbRadius: 10,
                            elevation: 2,
                          ),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                          activeTrackColor: Theme.of(context).primaryColor,
                          inactiveTrackColor: Theme.of(context).primaryColor.withOpacity(0.2),
                          thumbColor: Theme.of(context).primaryColor,
                          overlayColor: Theme.of(context).primaryColor.withOpacity(0.2),
                        ),
                        child: RangeSlider(
                          values: _ageRange,
                          min: _minAgeLimit,
                          max: _maxAgeLimit,
                          divisions: (_maxAgeLimit - _minAgeLimit).round(),
                          labels: RangeLabels(
                            _ageRange.start.round().toString(),
                            _ageRange.end.round().toString(),
                          ),
                          onChanged: (RangeValues values) {
                            setState(() {
                              _ageRange = values;
                            });
                          },
                          onChangeEnd: (RangeValues values) async {
                            await _saveLocalPreferences();
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_minAgeLimit.round()}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                              ),
                            ),
                            Text(
                              '${_maxAgeLimit.round()}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Opposite Gender - Level 2 Required
                _buildLevel2Setting(
                  context: context,
                  title: 'Opposite gender only',
                  subtitle: 'Match only with the opposite gender',
                  value: _chatWithOppositeGender,
                  onChanged: (bool value) async {
                    setState(() {
                      _chatWithOppositeGender = value;
                    });
                    await _saveLocalPreferences();
                  },
                ),
                // Verified Users Only - Level 2 Required
                _buildLevel2Setting(
                  context: context,
                  title: 'Verified users only',
                  subtitle: 'Match only with Level 2 verified users',
                  value: _chatOnlyWithVerifiedUsers,
                  onChanged: (bool value) async {
                    setState(() {
                      _chatOnlyWithVerifiedUsers = value;
                    });
                    await _saveLocalPreferences();
                  },
                ),
                const SizedBox(height: 24.0),
                // Privacy Settings Section
                Text(
                  'Privacy Settings',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.h,
                      ),
                ),
                const SizedBox(height: 16.0),
                
                // Profile Photo to Strangers - Level 1 Required
                _buildLevel1Setting(
                  context: context,
                  title: 'Hide photo from strangers',
                  subtitle: 'Strangers won\'t see your profile picture',
                  value: !_showProfilePhotoToStrangers,
                  onChanged: (bool value) async {
                    setState(() {
                      _showProfilePhotoToStrangers = !value;
                    });
                    await _saveLocalPreferences();
                  },
                ),

                // Read Receipts - Level 2 Required
                _buildLevel2Setting(
                  context: context,
                  title: 'Hide read receipts',
                  subtitle: 'Others won\'t see when you read their messages',
                  value: _hideReadReceipts,
                  onChanged: (bool value) async {
                    setState(() {
                      _hideReadReceipts = value;
                    });
                    await _saveLocalPreferences();
                  },
                ),
                // Profile Photo to Friends - Level 2 Required
                _buildLevel2Setting(
                  context: context,
                  title: 'Hide photo from friends',
                  subtitle: 'Friends won\'t see your profile picture',
                  value: !_showProfilePhotoToFriends,
                  onChanged: (bool value) async {
                    setState(() {
                      _showProfilePhotoToFriends = !value;
                    });
                    await _saveLocalPreferences();
                  },
                ),
                const SizedBox(height: 16.0),
                // Blocked Users
                InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlockedUsersPage(),
                      ),
                    );
                    // Refresh count when returning
                    _loadBlockedUsersCount();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Blocked Users',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.red,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_blockedUsersCount > 0)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Text(
                                  '$_blockedUsersCount',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            SizedBox(width: 8.0),
                            Icon(Icons.chevron_right, color: Colors.red.withOpacity(0.7)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                const Divider(),
                TextButton(
                  onPressed: () => dia.showTermsDialog(context),
                  style: Theme.of(context).textButtonTheme.style?.copyWith(
                        foregroundColor: MaterialStateProperty.all<Color>(
                          Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                  child: Text('Terms of Service'),
                ),
                TextButton(
                  onPressed: () => dia.showPrivacyPolicyDialog(context),
                  child: Text('Privacy Policy'),
                ),
                TextButton(
                  onPressed: () => dia.showHelpSupportDialog(context),
                  child: Text('Help & Support'),
                ),
                TextButton(
                  onPressed: () => dia.showAboutUsDialog(context),
                  child: Text('About Us'),
                ),
                TextButton(
                  onPressed: () => mymodel.User.logout(context),
                  child: Text('Logout'),
                ),
                const SizedBox(height: 20.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}