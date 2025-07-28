import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veil_chat_application/models/user_model.dart' as mymodel;
import 'package:veil_chat_application/core/app_theme.dart';
import 'profile.dart';
import 'package:veil_chat_application/widgets/docs_dialogs.dart' as dia;

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  mymodel.User? user;
  String? _name = '';
  String? _gender;
  String? _age;
  String? _profileImagePath;
  final TextEditingController _minAgeController = TextEditingController();
  final TextEditingController _maxAgeController = TextEditingController();

  bool _chatWithOppositeGender = false;
  bool _showProfilePhotoToStrangers = false;
  bool _showProfilePhotoToFriends = false;
  bool _chatOnlyWithVerifiedUsers = false;
  bool _isNotificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final loadedUser = await mymodel.User.getFromPrefs();
      final profileDetails = await mymodel.User.getProfileDetails();
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        user = loadedUser;
        _name = profileDetails['fullName'] ?? '';
        _gender = profileDetails['gender'] ?? '';
        _age = profileDetails['age'] ?? '';
        _profileImagePath = prefs.getString('profile_image_path');
      });
    } catch (e) {
      setState(() {
        user = null;
        _name = '';
        _gender = '';
        _age = '';
        _profileImagePath = null;
      });
    }
  }

  Widget _buildProfileCard(ThemeData theme) {
    return GestureDetector(
      onTap: () {
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => ProfileLvl1(),
        //   ),
        // );
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
              // Profile Image
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(width: 2, color: theme.primaryColor),
                  color: theme.colorScheme.secondary,
                ),
                child: (_profileImagePath != null &&
                        _profileImagePath!.isNotEmpty)
                    ? ClipOval(
                        child: Image.file(
                          File(_profileImagePath!),
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
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _name ?? 'User Name',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      (_gender ?? '').isNotEmpty ? _gender! : 'Gender not set',
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      (_age ?? '').isNotEmpty ? _age! : 'Age not set',
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
      body: SingleChildScrollView(
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
                onChanged: (bool value) {
                  setState(() {
                    _chatWithOppositeGender = value;
                  });
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
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Min',
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onChanged: (value) {
                            // handle min age change
                            _minAgeController.text = value;
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
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Max',
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onChanged: (value) {
                            // handle max age change
                            _maxAgeController.text = value;
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
                onChanged: (bool value) {
                  setState(() {
                    _showProfilePhotoToStrangers = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Show Profile photo to friends'),
                value: _showProfilePhotoToFriends,
                activeColor: Theme.of(context).primaryColor,
                inactiveTrackColor: Theme.of(context).colorScheme.secondary,
                onChanged: (bool value) {
                  setState(() {
                    _showProfilePhotoToFriends = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Chat only with Lvl 2 verified users'),
                value: _chatOnlyWithVerifiedUsers,
                activeColor: Theme.of(context).primaryColor,
                inactiveTrackColor: Theme.of(context).colorScheme.secondary,
                onChanged: (bool value) {
                  setState(() {
                    _chatOnlyWithVerifiedUsers = value;
                  });
                },
              ),
              const SizedBox(height: 8.0),
              // Text(
              //   'App Settings',
              //   style: Theme.of(context).textTheme.titleLarge?.copyWith(
              //         fontWeight: FontWeight.bold,
              //       ),
              // ),
              // const SizedBox(height: 16.0),
              // SwitchListTile(
              //   title: const Text('Enable Notifications'),
              //   value: _isNotificationsEnabled,
              //   activeColor: Theme.of(context).primaryColor,
              //   inactiveTrackColor: Theme.of(context).colorScheme.secondary,
              //   onChanged: (bool value) {
              //     setState(() {
              //       _isNotificationsEnabled = value;
              //     });
              //   },
              // ),
              TextButton(
                onPressed: () => dia.showTermsDialog(context),
                style: Theme.of(context).textButtonTheme.style?.copyWith(
                      foregroundColor: WidgetStateProperty.all<Color>(
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
    );
  }

  void pass() {
    // Placeholder for future functionality
    // This can be used to navigate to respective pages or show dialogs
  }
}
