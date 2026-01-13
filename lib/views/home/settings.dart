// import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:veil_chat_application/models/user_model.dart' as mymodel;
import 'package:veil_chat_application/core/app_theme.dart';
import 'package:veil_chat_application/services/firestore_service.dart';
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
  final TextEditingController _minAgeController = TextEditingController();
  final TextEditingController _maxAgeController = TextEditingController();

  bool _isLoading = true; // track initial data loading
  bool _pendingChange = false; // track whether settings differ from snapshot
  ImageProvider? _profileImageProvider; // cached image provider

  bool _chatWithOppositeGender = false;
  bool _showProfilePhotoToStrangers = false;
  bool _showProfilePhotoToFriends = false;
  bool _chatOnlyWithVerifiedUsers = false;

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
    _minAgeController.dispose();
    _maxAgeController.dispose();
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
        
        if (_user!.chatPreferences!.minAge != null) {
          _minAgeController.text = _user!.chatPreferences!.minAge.toString();
        }
        if (_user!.chatPreferences!.maxAge != null) {
          _maxAgeController.text = _user!.chatPreferences!.maxAge.toString();
        }
      }
      
      // Update privacy settings
      if (_user!.privacySettings != null) {
        _showProfilePhotoToFriends = _user!.privacySettings!.showProfilePicToFriends ?? false;
        _showProfilePhotoToStrangers = _user!.privacySettings!.showProfilePicToStrangers ?? false;
      }
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
    final minAge = _minAgeController.text.isEmpty
        ? null
        : int.tryParse(_minAgeController.text);
    final maxAge = _maxAgeController.text.isEmpty
        ? null
        : int.tryParse(_maxAgeController.text);

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
      ),
    );
  }

  Map<String, dynamic> _buildUpdatedFirestoreMap() {
    final minAge = _minAgeController.text.isEmpty
        ? null
        : int.tryParse(_minAgeController.text);
    final maxAge = _maxAgeController.text.isEmpty
        ? null
        : int.tryParse(_maxAgeController.text);

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
            (bpr?.showProfilePicToStrangers ?? false);

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
                SwitchListTile(
                  title: const Text('Chat only with opposite gender'),
                  value: _chatWithOppositeGender,
                  activeColor: Theme.of(context).primaryColor,
                  inactiveTrackColor: Theme.of(context).colorScheme.secondary,
                  onChanged: (bool value) async {
                    setState(() {
                      _chatWithOppositeGender = value;
                    });
                    await _saveLocalPreferences();
                  },
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    child: Row(
                      children: [
                        const Text(
                          'Chat only with people of age ',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(
                          width: 50,
                          child: TextField(
                            controller: _minAgeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Min',
                              contentPadding: EdgeInsets.symmetric(horizontal: 8),
                            ),
                            onChanged: (value) async {
                              await _saveLocalPreferences();
                            },
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('to'),
                        ),
                        SizedBox(
                          width: 50,
                          child: TextField(
                            controller: _maxAgeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Max',
                              contentPadding: EdgeInsets.symmetric(horizontal: 8),
                            ),
                            onChanged: (value) async {
                              await _saveLocalPreferences();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Show Profile photo to strangers'),
                  value: _showProfilePhotoToStrangers,
                  activeColor: Theme.of(context).primaryColor,
                  inactiveTrackColor: Theme.of(context).colorScheme.secondary,
                  onChanged: (bool value) async {
                    setState(() {
                      _showProfilePhotoToStrangers = value;
                    });
                    await _saveLocalPreferences();
                  },
                ),
                SwitchListTile(
                  title: const Text('Show Profile photo to friends'),
                  value: _showProfilePhotoToFriends,
                  activeColor: Theme.of(context).primaryColor,
                  inactiveTrackColor: Theme.of(context).colorScheme.secondary,
                  onChanged: (bool value) async {
                    setState(() {
                      _showProfilePhotoToFriends = value;
                    });
                    await _saveLocalPreferences();
                  },
                ),
                SwitchListTile(
                  title: const Text('Chat only with Lvl 2 verified users'),
                  value: _chatOnlyWithVerifiedUsers,
                  activeColor: Theme.of(context).primaryColor,
                  inactiveTrackColor: Theme.of(context).colorScheme.secondary,
                  onChanged: (bool value) async {
                    setState(() {
                      _chatOnlyWithVerifiedUsers = value;
                    });
                    await _saveLocalPreferences();
                  },
                ),
                const SizedBox(height: 8.0),
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