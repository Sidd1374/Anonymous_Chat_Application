// import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veil_chat_application/models/user_model.dart' as mymodel;
import 'package:veil_chat_application/core/app_theme.dart';
import 'package:veil_chat_application/services/firestore_service.dart';
import 'profile.dart';
import 'package:veil_chat_application/widgets/docs_dialogs.dart' as dia;
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  mymodel.User? _user;
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _minAgeController = TextEditingController();
  final TextEditingController _maxAgeController = TextEditingController();

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
    _minAgeController.dispose();
    _maxAgeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = await mymodel.User.getFromPrefs();
    if (mounted) {
      setState(() {
        _user = user;
        _updateControllersFromUser();
      });
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

  Future<void> _savePreferences() async {
    if (_user == null) return;

    try {
      // Parse age values
      int? minAge = _minAgeController.text.isEmpty ? null : int.tryParse(_minAgeController.text);
      int? maxAge = _maxAgeController.text.isEmpty ? null : int.tryParse(_maxAgeController.text);

      // Prepare updated data
      final updatedData = {
        'chatPreferences': {
          'matchWithGender': _chatWithOppositeGender ? (_user!.gender == 'Male' ? 'Female' : 'Male') : null,
          'minAge': minAge,
          'maxAge': maxAge,
          'onlyVerified': _chatOnlyWithVerifiedUsers,
        },
        'privacySettings': {
          'showProfilePicToFriends': _showProfilePhotoToFriends,
          'showProfilePicToStrangers': _showProfilePhotoToStrangers,
        },
      };

      // Update in Firebase
      await _firestoreService.updateUser(_user!.uid, updatedData);

      // Update local user object
      final updatedUser = mymodel.User(
        uid: _user!.uid,
        email: _user!.email,
        fullName: _user!.fullName,
        createdAt: _user!.createdAt,
        profilePicUrl: _user!.profilePicUrl,
        gender: _user!.gender,
        age: _user!.age,
        interests: _user!.interests,
        verificationLevel: _user!.verificationLevel,
        chatPreferences: mymodel.ChatPreferences(
          matchWithGender: _chatWithOppositeGender ? (_user!.gender == 'Male' ? 'Female' : 'Male') : null,
          minAge: minAge,
          maxAge: maxAge,
          onlyVerified: _chatOnlyWithVerifiedUsers,
        ),
        privacySettings: mymodel.PrivacySettings(
          showProfilePicToFriends: _showProfilePhotoToFriends,
          showProfilePicToStrangers: _showProfilePhotoToStrangers,
        ),
      );

      // Save to SharedPreferences
      await mymodel.User.saveToPrefs(updatedUser);

      // Update local state
      setState(() {
        _user = updatedUser;
      });

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      // Show error feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  Future<void> _refreshUserData() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      final userDoc = await _firestoreService.getUser(firebaseUser.uid);
      if (userDoc.exists) {
        final user = mymodel.User.fromJson(userDoc.data()!);
        await mymodel.User.saveToPrefs(user);
        if (mounted) {
          setState(() {
            _user = user;
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
              builder: (context) => ProfileLvl1(user: _user!),
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
                child: (_user?.profilePicUrl != null &&
                        _user!.profilePicUrl!.isNotEmpty)
                    ? ClipOval(
                        child: Image.network(
                          _user!.profilePicUrl!,
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
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
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
                    // Save to Firebase
                    await _savePreferences();
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
                              await _savePreferences();
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
                              await _savePreferences();
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
                    await _savePreferences();
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
                    await _savePreferences();
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
                    await _savePreferences();
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